require 'socket'

class ApiInputActor
  include BasicActor
  include Celluloid::IO

  finalizer :close_server

  def initialize
    subscribe "respond_client", :respond_client
    @server = TCPServer.new API_PORT_NUMBER
    async.watch_input
  end

  def watch_input
    loop do
      @client = @server.accept
      while input = @client.gets
        process_input(input.chomp)
      end
      @client.close
    end
  end

  def process_input(input)
    message, arg = input.split(/(?<!\\)\|/, 2)
    debug_message "message recieved: #{message.inspect} with arg: #{arg.inspect}"
    if arg
      publish message, arg
    else
      publish message
    end
  end

  def close_server
    debug_message "closing server" if @server
    @server.close if @server
  end

  def respond_client(_, arg_array)
    debug_message "Responding #{arg_array.inspect}"
    @client.puts arg_array.join("|") if @client
  end

  def send_message(msg, arg)
    debug_message "Sending #{msg}, #{arg}"
    @client.puts [msg, arg].join("|") if @client
  end
end

