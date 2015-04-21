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
      response = HTTPClient.new.get url
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
    results = JSON.parse response.content
    results["addresses"]["inferred"].map do |x|
      address = x.dup
      address['provenance'] = results['provenance']
      address
    end
  rescue
    $stderr.puts "Jess exploded with token=#{token}"
    []
  end
  
end
