class PageHandler
  attr_accessor :pages

  def initialize
    @pages = []
  end

  def add_page_from_change(change)
    page = Page.new(change.page_id, change.path, change.interval_time, change.user_id)
    pages << page 
  end

  def remove_page_from_change(change)
    pages.reject! { |page| page.page_id == change.page_id }
  end

end