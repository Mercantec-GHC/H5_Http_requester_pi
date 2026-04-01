class FaradayService
  attr_accessor :destanation_path

  def self.get_bearer_token(destanation_path)
    new(destanation_path).get_bearer_token
  end

  def self.get_response(destanation_path, token)
    new(destanation_path).get_response(token)
  end
  
  def initialize(destanation_path)
    @destanation_path = destanation_path
  end
  
  def get_response(token)
    faraday_client.get(destanation_path) do |req|
      req.headers['Authorization'] = "Bearer #{token}"
    end
  end

  def get_bearer_token
    faraday_client.post(destanation_path) do |req|
      req.headers['Content-Type'] = 'application/json'
      req.body = {email: ENV.fetch("ADMIN_EMAIL"), password: ENV.fetch("ADMIN_PASSWORD")}.to_json
    end
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