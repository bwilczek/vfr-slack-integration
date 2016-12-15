require "bunny"

STDOUT.sync = true

conn = Bunny.new
conn.start

ch = conn.create_channel
q  = ch.queue("bunny.examples.hello_world", :auto_delete => true)
x  = ch.default_exchange

x.publish("Hello!", :routing_key => q.name)

conn.close
