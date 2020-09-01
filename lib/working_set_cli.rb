# DEV ONLY
# Among other things, this adds bundle-installed gems to the load path so the
# dependencies are require-able.
require 'bundler/setup' if ENV["WORKING_SET_DEV"] == "true"

# External gem dependencies are loaded here.
require 'celluloid/current'
require 'celluloid/io'
require 'ncurses'

# And zeitwerk takes care of auto-loading the ruby files in this gem.
require 'zeitwerk'
loader = Zeitwerk::Loader.for_gem
loader.setup

if ARGV.to_s =~ /--debug=(\d+)/
  require 'socket'
  $DEBUG_CONSOLE ||= TCPSocket.new 'localhost', $1.to_i
end

$SOCKET_PATH = ".working_set_socket"
if ARGV.to_s =~ /(?:--socket|-S)=([\/a-zA-Z0-9_.-]+)/
  $SOCKET_PATH = $1
end

$LIVE_UPDATE_WATCH_PATH = false
if ARGV.to_s =~ /(?:--watch)=([\/a-zA-Z0-9_.-]+)/
  $LIVE_UPDATE_WATCH_PATH = $1
end

class Object
  def debug_message(msg)
    $DEBUG_CONSOLE.puts msg if $DEBUG_CONSOLE
  end
end

class AppGroup < Celluloid::Supervision::Container
  supervise type: SetViewerActor,  as: :set_viewer
  supervise type: SetBuilderActor, as: :set_builder
  supervise type: ApiInputActor,   as: :api_input
  supervise type: UserInputActor,  as: :user_input
  if $LIVE_UPDATE_WATCH_PATH
    require 'live_updater_actor'
    supervise type: LiveUpdaterActor, as: :live_updater
  end

  # It seems exiting cleanly requires:
  #   - shutdown: to kill the supervised actors
  #   - terminate: to kill the supervisor itself
  def do_shutdown
    shutdown
    terminate
  end

end

def check_for_existing_socket_file
  if File.exists?($SOCKET_PATH)
    puts "File #{$SOCKET_PATH.inspect} exists. Overwrite it? (y/N)"
    if STDIN.getch =~ /y/i
      File.delete($SOCKET_PATH)
    else
      puts "Ok, exiting program."
      exit
    end
  end
end

check_for_existing_socket_file

$supervisor = AppGroup.run!

# It seems we need to occupy the main thread otherwise the program exits here.
sleep 0.5 while $supervisor.alive?
