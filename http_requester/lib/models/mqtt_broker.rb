class MqttBroker  
  MqttCreateResponse = Struct.new(:type, :user_id, :page_id, :path, :interval_time)
  MqttDeleteResponse = Struct.new(:type, :user_id, :page_id)
  
  attr_reader :logger, :state, :create_page_topic, :delete_page_topic, :mqtt_response
  
  def initialize(logger, state)
    @logger = logger
    @state = state
    @create_page_topic = "uptime/websites/created"
    @delete_page_topic = "uptime/websites/deleted"
  end

  def start!
    logger.info("Starting MQTT client...")
    MQTT::Client.connect(
      host: "localhost",
      port: 1883
    ) do |client|
      client.subscribe(create_page_topic, delete_page_topic)
      client.get do |topic, message|
        logger.info("Received message on topic '#{topic}': #{message}")
        handle_response(topic, message)
      end
    end
  end

  def handle_response(topic, message)
    mqtt_response = JSON.parse(message)
    case topic
    when create_page_topic
      page = MqttCreateResponse.new(mqtt_response.fetch("type"), mqtt_response.fetch("userId"), mqtt_response.fetch("websiteId"), mqtt_response.fetch("path"), mqtt_response.fetch("interval_time"))
      update_state(page)
    when delete_page_topic
      page = MqttDeleteResponse.new(mqtt_response.fetch("type"), mqtt_response.fetch("userId"), mqtt_response.fetch("websiteId"))
      update_state(page)
    else
      logger.warn("Unknown topic: #{topic}")
    end
  end

  def update_state(page)
    state.add_change(page)
  end
  
  
end