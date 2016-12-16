require 'json'
require 'erb'
require 'bunny'

module RabbitHelper
  class << self

    def config
      return @config unless @config.nil?
      config_path = File.expand_path("#{File.dirname(__FILE__)}/../config/rabbit.json")
      @config = JSON.parse(ERB.new(File.read(config_path)).result, symbolize_names: true)
    end

    def init
      @rabbit = Bunny.new config[:connection]
      @rabbit.start

      @channel = @rabbit.create_channel
      @queue  = @channel.queue(config[:queue_name], :auto_delete => true)
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
