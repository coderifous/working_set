class SetBuilderActor
  include BasicActor

  attr_accessor :adapter

  DEFAULT_ADAPTER_CLASS = SetBuilderAdapter::Ag

  def initialize(initial_adapter = DEFAULT_ADAPTER_CLASS.new)
    subscribe "search_changed", :build_working_set
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

end
