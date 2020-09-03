class SetViewerActor
  include BasicActor

  def initialize
    subscribe "tell_selected_item", :tell_selected_item
    subscribe "copy_selected_item", :copy_selected_item
    subscribe "tell_selected_item_content", :tell_selected_item_content
    subscribe "set_build_finished", :refresh_view
    subscribe "set_build_failed", :show_error
    subscribe "scroll_changed", :scroll
    subscribe "context_lines_changed", :update_context_lines
    subscribe "refresh", :refresh
    subscribe "show_match_lines_toggled", :toggle_match_lines
    subscribe "select_next_file", :select_next_file
    subscribe "select_prev_file", :select_prev_file
    subscribe "select_next_item", :select_next_item
    subscribe "select_prev_item", :select_prev_item
    subscribe "welcome_user", :welcome_user
    subscribe "display_help", :display_help
    subscribe "display_working_set", :display_working_set
    welcome_user
  end

  def welcome_user(_=nil)
    debug_message "displaying welcome_user!"
    View::WelcomeUser.render
  end

  def display_help(_)
    debug_message "displaying help!"
    View::Help.render
  end

  def display_working_set(_)
    debug_message "displaying working_set!"
    @working_set_view&.render
  end

  def refresh_view(_, working_set)
    prev_wsv = @working_set_view
    @working_set_view = View::WorkingSet.new(working_set)
    if prev_wsv&.working_set&.search == working_set.search
      @working_set_view.restore_selection_state(prev_wsv)
    end
    @working_set_view.render
  end

  def items_present?
    @working_set_view&.working_set&.items&.size > 0
  end

  def scroll(_, delta)
    return unless items_present?
    @working_set_view.scroll(delta)
  end

  def update_context_lines(_, delta)
    $CONTEXT_LINES += delta
    $CONTEXT_LINES = 0 if $CONTEXT_LINES < 0
    debug_message "context lines set to #{$CONTEXT_LINES}"
    refresh
  end

  def refresh(_=nil)
    return unless @working_set_view
    # triggers search again without changing search term
    publish "search_changed", @working_set_view.working_set.search
  end

  def toggle_match_lines(_)
    return unless items_present?
    @working_set_view.toggle_match_lines
  end

  def select_next_file(_)
    return unless items_present?
    @working_set_view.select_next_file
  end

  def select_prev_file(_)
    return unless items_present?
    @working_set_view.select_prev_file
    unless @working_set_view.selected_item_in_view?
      publish "scroll_changed", @working_set_view.selected_item_scroll_delta
    end
  end

  def select_next_item(_)
    return unless items_present?
    @working_set_view.select_next_item
    unless @working_set_view.selected_item_in_view?
      publish "scroll_changed", @working_set_view.selected_item_scroll_delta
    end
  end

  def select_prev_item(_)
    return unless items_present?
    @working_set_view.select_prev_item
    unless @working_set_view.selected_item_in_view?
      publish "scroll_changed", @working_set_view.selected_item_scroll_delta
    end
  end

  def tell_selected_item(_)
    if items_present?
      item = @working_set_view.selected_item
      publish "respond_client", [item.file_path, item.row, item.column]
    else
      publish "respond_client", []
    end
  end

  def tell_selected_item_content(_)
    if items_present?
      item = @working_set_view.selected_item
      publish "respond_client", [item.match_line]
    else
      publish "respond_client", []
    end
  end

  def copy_selected_item(_, include_context=false)
    if items_present?
      item = @working_set_view.selected_item
      if include_context
        Clipboard.copy item.full_body
      else
        Clipboard.copy item.match_line
      end
    end
  end

  def show_error(_, error)
    debug_message error
    # Ncurses.stdscr.mvaddstr 0, 0, "SetViewerActor#show_error: #{error.backtrace}"
    # Ncurses.stdscr.refresh
  end

end
