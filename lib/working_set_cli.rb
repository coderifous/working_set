# DEV ONLY
# Among other things, this adds bundle-installed gems to the load path so the
# dependencies are require-able.
require 'bundler/setup' if ENV["WORKING_SET_DEV"] == "true"

# External gem dependencies are loaded here.
require 'celluloid/current'
require 'celluloid/io'
require 'ncurses'
require 'tty-option'

# And zeitwerk takes care of auto-loading the ruby files in this gem.
require 'zeitwerk'
loader = Zeitwerk::Loader.for_gem
loader.setup

class WorkingSetCli

  include TTY::Option

  usage do

    no_command # Doesn't seem to work as expected...
    command nil # So I have to do this.

    header "Working Set: A powerful companion for your brain while it's using your favorite text editor."

    desc "Very fast searching powered by `ag`, convenient ncurses-based interface, robust editor integration via bi-directional socket API."
    desc "Pairs great with tmux and vim."

  end

  flag :help do
    short "-h"
    long "--help"
    desc "Print usage"
  end

  option :debug do
    hidden
    short "-d"
    long "--debug=number"
    convert :int
    validate /\d{4,5}/
  end

  option :socket do
    desc "Set path for IPC socket file (for comms with text editor)"
    short "-s"
    long "--socket=path"
    default ".working_set_socket"
  end

  option :watch do
    desc "Auto-refresh working set when file changes detected"
    short "-w"
    long "--watch=path"
  end

  def run
    parse
    if params[:help]
      print help
      exit
    else
      init
      $supervisor = AppSupervisor.run!
      sleep 0.5 while $supervisor.alive? # I've need to occupy the main thread otherwise the program exits here.
    end
  end

  class AppSupervisor < Celluloid::Supervision::Container
    supervise type: SetViewerActor,  as: :set_viewer
    supervise type: SetBuilderActor, as: :set_builder
    supervise type: ApiInputActor,   as: :api_input
    supervise type: UserInputActor,  as: :user_input

    def self.enable_live_watch!
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

  private

  def init
    init_debug
    init_socket_file
    init_live_watch
  end

  def init_live_watch
    AppSupervisor.enable_live_watch! if params.key?(:watch)
    $LIVE_UPDATE_WATCH_PATH = params.key?(:watch) ? (params[:watch] || ".") : false
  end

  def init_socket_file
    $SOCKET_PATH = params[:socket]
    check_for_existing_socket_file
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

  def init_debug
    if params.key?(:debug)
      require 'socket'
      $DEBUG_CONSOLE ||= TCPSocket.new 'localhost', params[:debug] || 4444
    end
  end

end

class Object
  def debug_message(msg)
    $DEBUG_CONSOLE.puts msg if $DEBUG_CONSOLE
  end
end

WorkingSetCli.new.run
