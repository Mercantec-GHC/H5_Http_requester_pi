class State

  attr_accessor :changes
  attr_reader :logger, :mutex
  
  def initialize(logger)
    @logger = logger
    @changes = []
    @mutex = Mutex.new
  end

  def changes?
    !changes.empty?
  end

  def clean_changes!
    mutex.synchronize do
      logger.info("Clearing changes: #{changes.map(&:to_s).join(', ')}")
      changes.clear
    end
  end

  def add_change(change)
    mutex.synchronize do
      logger.info("Adding change: #{change}")
      changes << change
    end
  end

end