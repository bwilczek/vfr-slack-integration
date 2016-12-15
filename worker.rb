require 'faraday'
require 'vfr-utils'
require_relative './lib/rabbit_helper'

RabbitHelper.init

begin
  RabbitHelper.process_message do |data|
    puts data.to_s
    case data['operation']
    when 'notam'
      puts 'Preparing data for Faraday to POST back to slack'
    when 'metar'
      # not implemented yet
    when 'taf'
      # not implemented yet
    else
      next
    end
    puts '... and posting it back'
  end
rescue SystemExit, Interrupt
  # puts 'Closing connection...'
  RabbitHelper.cleanup
end
