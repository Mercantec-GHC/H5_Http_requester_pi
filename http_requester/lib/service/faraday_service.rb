class FaradayService
  attr_accessor :destanation_path

  def self.get_response(destanation_path)
    new(destanation_path).get_response
  end

  def initialize(destanation_path)
    @destanation_path = destanation_path
  end
  
  def get_response
    faraday_client.get(destanation_path)
  end

  private

  def faraday_client
    @faraday_client ||= begin
      Faraday.new do |faraday|
        faraday.adapter Faraday.default_adapter
      end
    end
  end

end