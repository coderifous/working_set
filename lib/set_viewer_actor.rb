class SetViewerActor
  include BasicActor

  def initialize
    subscribe "tell_selected_item", :tell_selected_item
    subscribe "copy_selected_item", :copy_selected_item
    subscribe "tell_selected_item_content", :tell_selected_item_content
    subscribe "render_working_set", :render_working_set
    subscribe "set_build_failed", :show_error
    subscribe "scroll_changed", :scroll
    subscribe "context_lines_changed", :update_context_lines
    subscribe "show_match_lines_toggled", :toggle_match_lines
    subscribe "select_next_file", :select_next_file
    subscribe "select_prev_file", :select_prev_file
    subscribe "select_next_item", :select_next_item
    subscribe "select_prev_item", :select_prev_item
    subscribe "delete_selected_item", :delete_selected_item
  end

  def render_working_set(_, working_set = nil)
    if working_set
      prev_wsv = @working_set_view
      @working_set_view = View::WorkingSet.new(working_set)
      if prev_wsv&.working_set&.search == working_set.search
        @working_set_view.restore_selection_state(prev_wsv)
      end
    end
    publish "render_view", @working_set_view
  end

  def items_present?
    (@working_set_view&.working_set&.items&.size || 0) > 0
  end

  def scroll(_, delta)
    return unless items_present?
    @working_set_view.scroll(delta)
  end

  def update_context_lines(_, delta)
    $CONTEXT_LINES += delta
    $CONTEXT_LINES = 0 if $CONTEXT_LINES < 0
    debug_message "context lines set to #{$CONTEXT_LINES}"
    publish :refresh
  end

  def toggle_match_lines(_)
    return unless items_present?
    @working_set_view.toggle_match_lines
  end

  def select_next_file(_)
    return unless items_present?
    @working_set_view.select_next_file
    unless @working_set_view.selected_item_in_view?
      publish "scroll_changed", @working_set_view.selected_item_scroll_delta
    end
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
      publish "respond_client", "selected_item", {
        file_path: item.file_path,
        row: item.row,
        column: item.column
      }
    end
  end

  def tell_selected_item_content(_)
    if items_present?
      item = @working_set_view.selected_item
      publish "respond_client", "selected_item_content", {
        data: item.match_line
      }
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

  def delete_selected_item(_)
    return unless items_present?
    @working_set_view.delete_selected_item
  end

  def show_error(_, error)
    debug_message error
    # Ncurses.stdscr.mvaddstr 0, 0, "SetViewerActor#show_error: #{error.backtrace}"
    # Ncurses.stdscr.refresh
  end

end
