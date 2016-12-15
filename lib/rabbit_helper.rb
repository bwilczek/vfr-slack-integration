require 'json'
require 'bunny'

module RabbitHelper
	class << self

		def init
			# TODO: use configuration
			@rabbit = Bunny.new
			@rabbit.start

			@channel = @rabbit.create_channel
			@queue  = @channel.queue('vfr-utils', :auto_delete => true)
			@exchange  = @channel.default_exchange
		end

		def cleanup
			@rabbit.close
		end

		def publish(task_data)
			@exchange.publish(JSON.generate(task_data), :routing_key => @queue.name)
		end

		def process_message
			@queue.subscribe(block: true) do |delivery_info, metadata, payload|
				Thread.new do
					data = JSON.parse(payload)
					yield data
				end
		  end
		end

	end
end
