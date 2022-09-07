class SetBuilderActor
  include BasicActor

  attr_accessor :adapter, :working_set_history

  DEFAULT_ADAPTER_CLASS = SetBuilderAdapter::Ag

  def initialize(initial_adapter = DEFAULT_ADAPTER_CLASS.new)
    subscribe "search_changed", :build_working_set
    subscribe "refresh_search", :refresh_working_set
    self.adapter = initial_adapter
  end

  def build_working_set(_, search, options={})
    debug_message "search: #{search.inspect} options: #{options.inspect}"
    begin
      working_set = adapter.build_working_set(search, options)
      publish "set_build_finished", working_set
    rescue StandardError => e
      publish "set_build_failed", e
    end
  end

  def refresh_working_set(_, working_set)
    begin
      ws = adapter.build_working_set(working_set.search, working_set.options)
      publish "set_refresh_finished", ws
    rescue StandardError => e
      publish "set_build_failed", e
    end
  end

end
