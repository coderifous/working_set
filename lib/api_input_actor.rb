require 'socket'
require 'json'

class ApiInputActor
  include BasicActor
  include Celluloid::IO

  finalizer :close_server

  # Since the inputs are translated into internal actor messages, we can have a
  # little extra security by only permitting certain messages, because some
  # messages are really for internal use only.
  PERMITTED_MESSAGES_LIST = %w(
    search_changed
    select_next_item
    select_prev_item
    select_next_file
    select_prev_file
    tell_selected_item
    tell_selected_item_content
    show_match_lines_toggled
    refresh
  )

  def initialize
    subscribe "respond_client", :respond_client
    @server = UNIXServer.new $SOCKET_PATH
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
    debug_message "input: #{input.inspect}"

    parsed = JSON.parse(input)
    message = parsed["message"]
    args    = parsed["args"]
    options = parsed["options"]

    debug_message "message: #{message.inspect}\nargs: #{args.inspect}\noptions: #{options.inspect}"

    unless PERMITTED_MESSAGES_LIST.include?(message)
      debug_message "Message not permitted, ignoring."
      return
    end

    publish *[message, args, options].compact
  end

  def close_server
    debug_message "closing server" if @server
    @server.close if @server
    File.delete($SOCKET_PATH)
  end

  def respond_client(_, message, extras={})
    payload = { message: message }.merge(extras)
    debug_message "Responding #{payload.inspect}"
    @client.puts payload.to_json if @client
  end

  def send_message(msg, arg)
    debug_message "Sending #{msg}, #{arg}"
    @client.puts [msg, arg].join("|") if @client
  end
end
