require 'faraday'
require 'vfr_utils'
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

    response = Faraday.post do |req|
      req.url data['response_url']
      req.headers['Content-Type'] = 'application/json'
      req.body = JSON.generate(text: result, mrkdwn: true)
    end
    unless response.status == 200
      $stderr.puts "POST to Slack failed. Code: #{response.status}, body: #{response.body}"
    end
  end
rescue SystemExit, Interrupt
  # puts 'Closing connection...'
  RabbitHelper.cleanup
end
