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
        # run_curl_on_home_pages!
        # print_curl_responses!
      rescue => e
        logger.error("An error occurred in event loop: #{e.message} \n #{e.backtrace.join("\n")}")
      end
      sleep(2)
    end
  end

  def print_curl_responses!
    curl_responses.each do |curl_response|
      curl_response.pretty_print_data
    end
  end
  
  private

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
    state.changes.each do |change|
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
    state.clean_changes!
  end
  
    def run_curl_on_home_pages!
    @curl_responses = home_pages.map do |home_page|
      UrlData.new(CurlService.new(home_page).formated_response, home_page)
    end
  end  

end