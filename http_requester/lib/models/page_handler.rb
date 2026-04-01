class PageHandler
  UniqPageNeedingPing = Struct.new(:path, :pages, :response) do
    def initialize(path, pages, response = nil)
      super
    end
  end

  attr_accessor :pages, :uniq_pages_needing_ping
  attr_reader :logger

  def initialize(logger)
    @pages = []
    @uniq_pages_needing_ping = nil
    @logger = logger
  end

  def add_page_from_change(change)
    page = Page.new(change.page_id, change.path, change.interval_time, change.user_id)
    pages << page 
  end

  def remove_page_from_change(change)
    pages.reject! { |page| page.page_id == change.page_id }
  end

  def uniq_pages_needing_ping
    logger.info("Calculating unique pages needing ping...")
    @uniq_pages_needing_ping ||= begin 
      unique_pages = pages.find_all(&:ready_for_ping?).group_by(&:normalize_path).map { |path, pages| UniqPageNeedingPing.new(path, pages) }
      unique_pages.empty? ? nil : unique_pages
    end
  rescue => e
    logger.error("Error while determining pages needing ping: #{e.message} \n #{e.backtrace.join("\n")}")
    [] 
  end

  def pages_needing_ping?
    !uniq_pages_needing_ping.nil?
  end
  

end