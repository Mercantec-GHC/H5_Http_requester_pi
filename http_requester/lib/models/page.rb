class Page
  attr_accessor  :path, :interval_time, :id, :last_ping_time, :user_id

  def initialize(id, path, interval_time, user_id)
    @id = id
    @path = path
    @interval_time = interval_time
    @last_ping_time = Time.now
    @user_id = user_id
  end

  def ready_for_ping?
    puts "testing if #{path} is ready for ping... (last ping: #{last_ping_time}, interval: #{interval_time}s)"
    Time.now - last_ping_time >= interval_time
  end

  def update_last_ping_time!
    @last_ping_time = Time.now
  end
  
end