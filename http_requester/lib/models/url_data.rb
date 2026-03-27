class UrlData
  attr_reader :status_code, :dns_lookup, :connect_to_page, :tls_hand_shake, :time_to_first_byte, :total_time, :url

  def initialize(curl_response, url)
    @url = url
    @status_code = curl_response.fetch("status")
    @dns_lookup = curl_response.fetch("dns_lookup")
    @connect_to_page = curl_response.fetch("connect_to_page")
    @tls_hand_shake = curl_response.fetch("tls_hand_shake")
    @time_to_first_byte = curl_response.fetch("time_to_first_byte")
    @total_time = curl_response.fetch("total_time")
  end

  def pretty_print_data
    puts "URL: #{url}"
    puts "Status code: #{status_code}"
    puts "DNS lookup: #{dns_lookup} ms"
    puts "Connect to page: #{connect_to_page} ms"
    puts "TLS hand shake: #{tls_hand_shake} ms"
    puts "Time to first byte: #{time_to_first_byte} ms"
    puts "Total time: #{total_time} ms"
    puts "-----------------------------"
  end

  def to_json
    {
      url: url,
      status_code: status_code,
      dns_lookup: dns_lookup,
      connect_to_page: connect_to_page,
      tls_hand_shake: tls_hand_shake,
      time_to_first_byte: time_to_first_byte,
      total_time: total_time
    }.to_json
    
  end
  
  

end