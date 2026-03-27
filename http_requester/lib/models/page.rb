class Page
  attr_accessor  :path, :interval_time, :id, :last_ping_time, :user_id

  def initialize(id, path, interval_time, user_id)
    @id = id
    @path = path
    @interval_time = interval_time
    @last_ping_time = 0
    @user_id = user_id
  end
end