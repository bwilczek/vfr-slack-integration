require 'sinatra'
require 'json'
require 'vfr-utils'

set :bind, '0.0.0.0'

get '/' do
	handle_request
	# 'Try with POST'
end

post '/' do
	handle_request
end

def handle_request
	# TODO: validate ENV['SLACK_TOKEN'] == params[:token]
	# TODO: validate params[:text]

	content_type 'application/json'

	operation = params[:text].split.first
	operation_params = params[:text].split[1..-1]

	# return "|#{operation}| #{operation_params.to_s}"
	view = erb :notam_multiple_airports, locals: { data: VfrUtils::NOTAM.get(operation_params) }

	ret = {
		"text": view,
		"username": "VFR bot",
		"mrkdwn": true
	}
	JSON.generate ret
end
