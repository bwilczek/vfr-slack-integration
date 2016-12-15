require "bunny"

STDOUT.sync = true

conn = Bunny.new
conn.start

ch = conn.create_channel
q  = ch.queue("bunny.examples.hello_world", :auto_delete => true)

begin
  q.subscribe(block: true) do |delivery_info, metadata, payload|
    puts "Received #{payload}"
  end
rescue SystemExit, Interrupt
  puts "Closing connection..."
  conn.close
end
