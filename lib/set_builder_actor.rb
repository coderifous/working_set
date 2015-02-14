class SetBuilderActor
  include BasicActor

  attr_accessor :adapter

  DEFAULT_ADAPTER_CLASS = SetBuilderAdapter::Ag

  def initialize(initial_adapter = DEFAULT_ADAPTER_CLASS.new)
    subscribe "search_changed", :build_working_set
    self.adapter = initial_adapter
  end

  def build_working_set(_, search)
    debug_message "search command: #{adapter.command(search)}"
    begin
      working_set = adapter.build_working_set(search)
      publish "set_build_finished", working_set
    rescue StandardError => e
      publish "set_build_failed", e
    end
  end

end
