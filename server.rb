require 'sinatra'
require 'json'

set :bind, '0.0.0.0'

get '/' do
	'Try with POST'
end

post '/' do
	content_type 'text/json'
	# TODO: validate ENV['SLACK_TOKEN'] == params[:token]
	# TODO: validate params[:text]
	ret = {
		"text": "So, does it work?\nText: _#{params[:text]}_",
		"username": "VFR bot",
		"mrkdwn": true
	}
	JSON.generate ret
end
