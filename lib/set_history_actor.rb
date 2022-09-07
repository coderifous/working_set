class SetHistoryActor
  include BasicActor

  attr_accessor :entries, :position

  def initialize
    subscribe "set_build_finished",   :add
    subscribe "go_back_history",      :go_back_history
    subscribe "go_forward_history",   :go_forward_history
    subscribe "remove_from_history",  :remove_from_history
    subscribe "refresh",              :request_refresh
    subscribe "set_refresh_finished", :refresh_finished

    self.entries = []
    self.position = -1
  end

  def request_refresh(_=nil)
    return unless working_set = entries[position]
    publish "refresh_search", working_set
  end

  def refresh_finished(_, working_set)
    return unless working_set
    entries[position] = working_set
    position_changed!
  end

  # If we're at the end of history, add to end,
  # otherwise, insert after current position in history.
  def add(_, working_set = nil)
    return unless working_set
    entries.insert(position + 1, working_set)
    go_forward_history(nil)
  end

  def remove_from_history(_)
    return if entries.size == 0
    entries.delete_at(position)
    if entries.size > 0 && position >= entries.size
      go_back_history(nil)
    elsif entries.size > 0
      position_changed!
    else
      publish :welcome_user
    end
  end

  def go_back_history(_)
    return if position <= 0
    self.position -= 1
    position_changed!
  end

  def go_forward_history(_)
    return if position >= entries.size - 1
    self.position += 1
    position_changed!
  end

  def peek_search_term_back
    working_set = entries[position - 1]
    working_set.search if working_set && position > 0
  end

  def peek_search_term_forward
    working_set = entries[position + 1]
    working_set.search if working_set
  end

  private

  def position_changed!
    working_set = entries[position]
    publish "render_working_set", working_set
  end

end

