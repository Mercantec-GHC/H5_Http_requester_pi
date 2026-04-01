
class MqttBroker
  MqttCreateResponse = Struct.new(:type, :user_id, :page_id, :path, :interval_time)
  MqttDeleteResponse = Struct.new(:type, :user_id, :page_id)

  attr_reader :logger, :state, :create_page_topic, :delete_page_topic, :publish_queue, :immediate_ping_worker

  def initialize(logger, state, immiediate_ping_worker)
    @logger = logger
    @state = state
    @create_page_topic = "uptime/websites/created"
    @delete_page_topic = "uptime/websites/deleted"
    @publish_queue = Queue.new
    @immediate_ping_worker = immiediate_ping_worker
  end

  def start_subscriber!
    Thread.new do
      loop do
        begin
          logger.info("Connecting subscriber to MQTT broker at localhost:1883...")
          MQTT::Client.connect(
            host: "localhost",
            port: 1883,
            keep_alive: 5
          ) do |client|
            client.subscribe(create_page_topic, delete_page_topic)
            logger.info("Connected subscriber to MQTT broker")
            client.get do |topic, message|
              logger.info("Received message on '#{topic}': #{message}")
              handle_response(topic, message)
            end
          end
        rescue MQTT::ProtocolException, Errno::ECONNREFUSED, IOError, SystemCallError => e
          logger.error("Subscriber connection error: #{e.class} - #{e.message}")
          sleep 10
        rescue => e
          logger.error("Subscriber unexpected error: #{e.class} - #{e.message}\n#{e.backtrace.join("\n")}")
          sleep 10
        end
      end
    end
  end

  def start_publisher!
    Thread.new do
      loop do
        begin
          logger.info("Connecting publisher to MQTT broker at localhost:1883...")
          MQTT::Client.connect(
            host: "localhost",
            port: 1883,
            keep_alive: 5
          ) do |client|
            logger.info("Connected publisher to MQTT broker")
            loop do
              flush_publish_queue(client)
              sleep 1
            end
          end
        rescue MQTT::ProtocolException, Errno::ECONNREFUSED, IOError, SystemCallError => e
          logger.error("Publisher connection error: #{e.class} - #{e.message}")
          sleep 10
        rescue => e
          logger.error("Publisher unexpected error: #{e.class} - #{e.message}\n#{e.backtrace.join("\n")}")
          sleep 10
        end
      end
    end
  end

  def start!
    start_subscriber!
    start_publisher!
  end

  def enqueue_publish(topic:, payload:)
    logger.info("Queueing MQTT publish to '#{topic}'")
    publish_queue << {
      topic: topic,
      payload: payload
    }
  end

  def flush_publish_queue(client, retain=true, qos=1)
    loop do
      message = publish_queue.pop(true)

      logger.info("Publishing MQTT message to '#{message[:topic]}': #{message[:payload]}")
      client.publish(message[:topic], message[:payload], retain: retain, qos: qos)
    end
  rescue ThreadError
    nil
  rescue => e
    logger.error("Error while flushing MQTT publish queue: #{e.message}\n#{e.backtrace.join("\n")}")
  end

  def handle_response(topic, message)
    mqtt_response = JSON.parse(message)

    case topic
    when create_page_topic
      page = MqttCreateResponse.new(
        mqtt_response.fetch("type"),
        mqtt_response.fetch("userId"),
        mqtt_response.fetch("websiteId"),
        mqtt_response.fetch("path"),
        mqtt_response.fetch("interval_time")
      )
      update_state(page)
      immediate_ping_worker.enqueue_page(page)
    when delete_page_topic
      page = MqttDeleteResponse.new(
        mqtt_response.fetch("type"),
        mqtt_response.fetch("userId"),
        mqtt_response.fetch("websiteId")
      )
      update_state(page)
    else
      logger.warn("Unknown topic: #{topic}")
    end
  end

  def update_state(page)
    state.add_change(page)
  end
end