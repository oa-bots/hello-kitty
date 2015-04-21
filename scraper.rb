require 'json'
require 'turbotlib'

$:.unshift File.dirname(__FILE__)
require 'hello_kitty'

Turbotlib.log("Starting run...")

if ENV['FIRST_RUN']
  last_run = (Time.now - 259200)
else
  last_run = DateTime.parse(ENV['LAST_RUN_AT'])
end

puts last_run

HelloKitty.updates_since(last_run) do |token|
  HelloKitty.infer(token).each do |data|
    puts JSON.dump(data)
  end
end
