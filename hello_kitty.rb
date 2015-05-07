require 'json'
require 'turbotlib'

class HelloKitty

  JESS = 'http://jess.openaddressesuk.org/infer'
#  SOURCE = 'https://alpha.openaddressesuk.org/'
  SOURCE = 'https://alpha.openaddressesuk.org/addresses.json?'

  def self.updates_since interval, &block
    total = nil
    count = 0
    page = 1
    while total.nil? || count < total
      url = SOURCE+"page=#{page}&updated_since=#{interval.xmlschema}"
      puts url
      response = request_with_retries url
      # Set total if first run through
      if total.nil?
        total = (response.header['X-Total-Count'] + response.header['Total']).first.to_i
      end

      j = JSON.parse(response.content)
      tokens = j['addresses'].map { |p| p['url'].split('/').last }
      tokens.each do |token|
        block.call token
        count += 1
      end
      page += 1
    end
  end

  def self.infer(token)
    response = HTTPClient.new.post JESS, "token=#{token}"
    if response.code == 400
      $stderr.puts "Address #{token} is already inferred"
    else
      results = JSON.parse response.content
      results["addresses"]["inferred"].map do |x|
        address = x.dup
        address['provenance'] = results['provenance']
        address
      end
    end
  rescue
    $stderr.puts "Jess exploded with token=#{token}"
    []
  end

  def self.request_with_retries(url, tries = 0)
    limit ||= 5
    response = HTTPClient.new.get url
    if response.http_header.status_code != 200
      if (tries += 1) <= limit
        seconds = 5 * tries
        $stderr.puts "Hit error, trying again in #{seconds} seconds"
        sleep seconds
        request_with_retries(url, tries)
      else
        $stderr.puts "Giving up"
      end
    else
      response
    end
  end

end
