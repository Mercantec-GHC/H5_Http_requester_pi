class ImmediatePingWorker

  attr_reader :logger, :queue, :publish_result

  def initialize(logger, publish_result)
    @logger = logger
    @queue = Queue.new
    @publish_result = publish_result
  end
  
  def start!
    Thread.new do
      loop do
        begin
          page = queue.pop
          logger.info("Processing immediate ping for page: #{page.path}")
          response = CurlService.get_hashed_response(page.path)
          publish_result.call("uptime/measurements", {pages: {id: page.page_id, path: page.path, user_id: page.user_id, response: response}}.to_json)
        rescue => e
          logger.error("Error processing immediate ping: #{e.class} - #{e.message}\n#{e.backtrace.join("\n")}")
        end
      end
    end
  end

  def enqueue_page(page)
    logger.info("Enqueuing page for immediate ping: #{page.path}")
    queue << page
  end
end