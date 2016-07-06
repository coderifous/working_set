require 'listen'

class LiveUpdaterActor
  include BasicActor

  finalizer :stop

  def initialize
    @listener = build
    start
  end

  def build
    Listen.to($LIVE_UPDATE_WATCH_PATH) do |modified, added, removed|
      debug_message "modified absolute path: #{modified}"
      debug_message "added absolute path: #{added}"
      debug_message "removed absolute path: #{removed}"
      publish "refresh"
    end
  end

  def start
    @listener.start
  end

  def stop
    @listener.stop
  end
end
