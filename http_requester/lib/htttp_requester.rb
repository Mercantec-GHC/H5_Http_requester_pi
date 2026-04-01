class HttpRequester
  
  attr_accessor :home_pages, :curl_responses, :logger, :stop, :state, :page_handler, :mqtt_broker, :immediate_ping_worker

  def initialize(logger)
    @logger = logger
    @stop = false
    @state = State.new(logger)
    @page_handler = PageHandler.new(logger)
  end
  
  def execute 
    start_immediate_ping_worker!
    start_mqtt_client!
    load_websites_from_api!

    until stop
      begin
        update_page_handler! if state.changes?
        run_curl_on_pages! if page_handler.pages_needing_ping?
      rescue => e
        logger.error("An error occurred in event loop: #{e.message} \n #{e.backtrace.join("\n")}")
      end
      sleep(5)
    end
  end
  
  private

  def report_ping_response_to_mqtt!
    pages_json_array = page_handler.uniq_pages_needing_ping.flat_map do |uniq_page|
      pages = []
      pages_json = uniq_page.pages.map do |page|
        {"id": page.id, "path": page.path, "user_id": page.user_id, "response": uniq_page.response}
      end
      pages << pages_json
      pages
    end.flatten
    mqtt_broker.enqueue_publish(topic: "uptime/measurements", payload: {pages: pages_json_array}.to_json)
  rescue => e
    logger.error("Failed to report ping response to MQTT: #{e.message}\n #{e.backtrace.join("\n")}")
  end

  def load_websites_from_api!
    puts "Loading websites from API..."
    response = FaradayService.get_bearer_token("http://#{ENV['HOST']}:#{ENV['PORT_ACCOUNT']}/accounts/login")
    token = JSON.parse(response.body).fetch("token")
    api_response = FaradayService.get_response("http://#{ENV['HOST']}:#{ENV['PORT_WEBSITES']}/api/Websites", token)
    JSON.parse(api_response.body).each do |page|
      page_handler.pages << Page.new(page.fetch("id"), page.fetch("url"), page.fetch("intervalTime"), page.fetch("userId"))
    end
      logger.info("Loaded pages: #{page_handler.pages.map(&:path).join(', ')}")
  rescue Faraday::ConnectionFailed => e
    logger.error("Failed to connect to API: #{e.message}")
    self.stop = true
  rescue JSON::ParserError => e
    logger.error("Failed to parse API response: #{e.message}, response was: #{response.body}")
    self.stop = true
  rescue KeyError => e
    logger.error("Missing expected key in API response: #{e.message}")
    self.stop = true
  rescue => e
    logger.error("Unexpected error: #{e.message}\n #{e.backtrace.join("\n")}")
    self.stop = true
  end

  def start_immediate_ping_worker!
    self.immediate_ping_worker = ImmediatePingWorker.new(logger, ->(topic, payload) {
    mqtt_broker.enqueue_publish(topic: topic, payload: payload)
  })
    immediate_ping_worker.start!
  end
  
  def start_mqtt_client!
    Thread.new do
      self.mqtt_broker = MqttBroker.new(logger, state, immediate_ping_worker)
      mqtt_broker.start!
    end
  end
  
  def update_page_handler!
    state.fetch_changes.each do |change|
      case change.type
      when "website_created"
        page_handler.add_page_from_change(change)
        logger.info("Added page: #{change.path}")
      when "website_deleted"
        page_handler.remove_page_from_change(change)
        logger.info("Removed page: #{change.path}")
      else
        logger.warn("Unknown change type: #{change.type}")
      end
    end
  end
  
    def run_curl_on_pages!
      page_handler.uniq_pages_needing_ping.each do |uniq_page|
        logger.info("Pinging #{uniq_page.path} for #{uniq_page.pages.size} page(s)")
        response = CurlService.get_hashed_response(uniq_page.path)
        uniq_page.response = response
        logger.info("Received response for #{uniq_page.path}: #{response}")
      end
      report_ping_response_to_mqtt!
      page_handler.uniq_pages_needing_ping = nil
    rescue => e
      logger.error("Failed to ping pages: #{e.message}\n #{e.backtrace.join("\n")}")
    end
end