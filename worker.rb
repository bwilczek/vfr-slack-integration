require 'faraday'
require 'vfr-utils'
require_relative './lib/rabbit_helper'
require_relative './lib/markdown_formatter'

RabbitHelper.init

begin
  RabbitHelper.process_message do |data|
    result = case data['operation']
      when 'notam' then MarkdownFormatter.notam(VfrUtils::NOTAM.get(data['operation_params']))
      when 'metar'
        # not implemented yet
        next
      when 'taf'
        # not implemented yet
        next
      else
        next
      end

    # puts JSON.generate(text: result, mrkdwn: true)
    # next
    # TODO: some error handling for the response
    response = Faraday.post do |req|
      req.url data['response_url']
      req.headers['Content-Type'] = 'application/json'
      req.body = JSON.generate(text: result, mrkdwn: true)
    end
  end
rescue SystemExit, Interrupt
  # puts 'Closing connection...'
  RabbitHelper.cleanup
end
