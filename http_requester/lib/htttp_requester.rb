class HttpRequester
  
  attr_accessor :home_pages, :curl_responses, :logger, :stop, :state, :page_handler

  def initialize(logger)
    @logger = logger
    @stop = false
    @state = State.new(logger)
    @page_handler = PageHandler.new
  end
  
  def execute 
    start_mqtt_client!
    load_websites_from_api!

    until @stop
      begin
        update_page_handler! if state.changes?
        run_curl_on_home_pages! if page_handler.pages_needing_ping?
      rescue => e
        logger.error("An error occurred in event loop: #{e.message} \n #{e.backtrace.join("\n")}")
      end
      sleep(2)
    end
  end
  
  private

  def report_ping_response_to_mqtt()
    
  end

  def load_websites_from_api!
    api_response = FaradayService.get_response("http://localhost:8080/api/Websites")
      JSON.parse(api_response.body).each do |page|
        page_handler.pages << Page.new(page.fetch("id"), page.fetch("url"), page.fetch("intervalTime"), page.fetch("userId"))
      end
      logger.info("Loaded pages: #{@page_handler.pages.map(&:path).join(', ')}")
  rescue => e
    logger.error("Failed to load websites from DB: #{e.message}\n #{e.backtrace.join("\n")}")
  end
  
    def start_mqtt_client!
      Thread.new do
        MqttBroker.new(logger, state).start!
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
  
    def run_curl_on_home_pages!
      page_handler.uniq_pages_needing_ping.each do |uniq_page|
        logger.info("Pinging #{uniq_page.path} for #{uniq_page.pages.size} page(s)")
        response = CurlService.get_response(uniq_page.path)
        uniq_page.response = response
        logger.info("Received response for #{uniq_page.path}: #{response}")
      end
      report_ping_response_to_mqtt
      page_handler.uniq_pages_needing_ping = nil
    rescue => e
      logger.error("Failed to ping pages: #{e.message}\n #{e.backtrace.join("\n")}")
      raise "test"
    end

end