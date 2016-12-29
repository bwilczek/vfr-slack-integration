require 'json'
require 'vfr_utils'
require_relative './lib/rabbit_helper'

RabbitHelper.init

# The only way to perform cleanup after Sinatra shuts down
# is to register at_exit _before_ sinatra gem gets even required
at_exit {
  puts 'Closing RabbitMQ connection...'
  RabbitHelper.cleanup
}

### SINATRA PART STARTS HERE

require 'sinatra'

set :bind, '0.0.0.0'
ALLOWED_OPERATIONS = ['notam', 'taf', 'metar']

get '/' do
  # handle_request
  halt(405, 'Try with POST')
end

post '/' do
  handle_request
end

def handle_request
  halt(401, 'Eingang verboten') unless ENV['SLACK_TOKEN'] == params[:token]
  content_type 'application/json'

  task_data = validate_request
  return usage unless task_data

  RabbitHelper.publish(task_data)
  enqueued
end

def validate_request
  text = params[:text]
  return nil if text.nil?
  operation = text.split.first
  return nil unless ALLOWED_OPERATIONS.include? operation
  operation_params = text.split[1..-1]
  return nil if operation_params.empty?
  task_data = {
    operation: operation,
    operation_params: operation_params,
    response_url: params[:response_url]
  }
  task_data
end

def usage
  ret = {
    "text": "*Usage:*\n\`#{params[:command]} #{ALLOWED_OPERATIONS.join('|')} <list of ICAO codes>`\n_Example:_ `#{params[:command]} notam EPWR LKLB`",
    "mrkdwn": true
  }
  JSON.pretty_generate ret
end

def enqueued
  ret = {
    "text": "_Hold on, requested data will arrive soon..._",
    "mrkdwn": true
  }
  JSON.pretty_generate ret
end
