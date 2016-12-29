require 'faraday'
require 'vfr_utils'
require 'logger'
require_relative './lib/rabbit_helper'
require_relative './lib/markdown_formatter'

logger = Logger.new('/var/log/vfr_utils.log')
logger.level = Logger::ERROR
if ENV['VFR_LOG_LEVEL']
  begin
    logger.level = Logger.const_get(ENV['VFR_LOG_LEVEL'].upcase)
  rescue
  end
end

logger.info 'Starting the worker'

RabbitHelper.init
logger.info 'RabbitMQ connection ready'

begin
  RabbitHelper.process_message do |data|
    logger.debug "Processing message #{data}"
    begin
      result = case data['operation']
        when 'notam' then MarkdownFormatter.notam(VfrUtils::NOTAM.get(data['operation_params']))
        when 'metar' then MarkdownFormatter.weather(VfrUtils::METAR.get(data['operation_params']))
        when 'taf' then MarkdownFormatter.weather(VfrUtils::TAF.get(data['operation_params']))
        else
          next
        end
    rescue Exception => e
      logger.error "Exception: #{e.message}. Request data: #{data}"
      next
    end

    logger.debug " > Posting #{result.length} bytes to Slack"

    response = Faraday.post do |req|
      req.url data['response_url']
      req.headers['Content-Type'] = 'application/json'
      req.body = JSON.generate(text: result, mrkdwn: true)
    end
    logger.debug " < Result code: #{response.status}, body: #{response.body}"
    unless response.status == 200
      logger.error "POST to Slack failed. Code: #{response.status}, body: #{response.body}"
    end

  end
rescue SystemExit, Interrupt
  logger.info 'Closing RabbitMQ connection...'
  RabbitHelper.cleanup
end
