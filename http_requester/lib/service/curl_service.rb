class CurlService

  def self.get_hashed_response(target_path)
    new(target_path).formated_response
  end

  attr_accessor :target_path

  def initialize(target_path)
    @target_path = target_path
  end
  
  def curl_response_with_ms_lookup
    @curl_response_with_ms_lookup ||= begin
      stdout, stderr, status = Open3.capture3("curl -s -o /dev/null #{curl_write_ms_response} #{@target_path}")
      unless status.success?
        return "status:500\ndns_lookup:0\nconnect_to_page:0\ntls_hand_shake:0\ntime_to_first_byte:0\ntotal_time:0\n"
      else
        stdout
      end
    end
  end

  def formated_response
    curl_response =  {}
    curl_response_with_ms_lookup.split("\n").map do |line|
      key, value = line.split(":")
      key == "status" ? curl_response[key] = value : curl_response[key] = (value.to_f*1000).round(2)
    end
    curl_response
  end

  private

  def curl_write_ms_response
    '-L -w "status:%{http_code}\ndns_lookup:%{time_namelookup}\nconnect_to_page:%{time_connect}\ntls_hand_shake:%{time_appconnect}\ntime_to_first_byte:%{time_starttransfer}\ntotal_time:%{time_total}\n" --connect-timeout 2 --max-time 5'
  end

end