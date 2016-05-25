class SetViewerActor
  include BasicActor

  finalizer :clean_up

  def initialize
    subscribe "tell_selected_item", :tell_selected_item
    subscribe "set_build_finished", :refresh_view
    subscribe "set_build_failed", :show_error
    subscribe "scroll_changed", :scroll
    subscribe "refresh", :refresh
    subscribe "show_match_lines_toggled", :toggle_match_lines
    subscribe "select_next_file", :select_next_file
    subscribe "select_prev_file", :select_prev_file
    subscribe "select_next_item", :select_next_item
    subscribe "select_prev_item", :select_prev_item
    initialize_ncurses
  end

  def refresh_view(_, working_set)
    @working_set_view = WorkingSetView.new(working_set)
    @working_set_view.render
  end

  def scroll(_, delta)
    @working_set_view.scroll(delta)
  end

  def refresh(_)
    # triggers search again without changing search term
    publish "search_changed", @working_set_view.working_set.search
  end

  def toggle_match_lines(_)
    @working_set_view.toggle_match_lines
  end

  def select_next_file(_)
    @working_set_view.select_next_file
  end

  def select_prev_file(_)
    @working_set_view.select_prev_file
    unless @working_set_view.selected_item_in_view?
      publish "scroll_changed", @working_set_view.selected_item_scroll_delta
    end
  end

  def select_next_item(_)
    @working_set_view.select_next_item
    unless @working_set_view.selected_item_in_view?
      publish "scroll_changed", @working_set_view.selected_item_scroll_delta
    end
  end

  def select_prev_item(_)
    @working_set_view.select_prev_item
    unless @working_set_view.selected_item_in_view?
      publish "scroll_changed", @working_set_view.selected_item_scroll_delta
    end
  end

  def tell_selected_item(_)
    item = @working_set_view.selected_item
    publish "respond_client", [item.file_path, item.row, item.column]
  end

  def show_error(_, error)
    Ncurses.stdscr.mvaddstr 0, 0, "SetViewerActor#show_error: #{error.backtrace}"
    Ncurses.stdscr.refresh
  end

  def initialize_ncurses
    Ncurses.initscr
    Ncurses.cbreak # unbuffered input
    Ncurses.noecho # turn off input echoing
    Ncurses.nonl   # turn off newline translation
    Ncurses.stdscr.intrflush(false) # turn off flush-on-interrupt
    Ncurses.stdscr.keypad(true)     # turn on keypad mode

    Ncurses.start_color
    Ncurses.use_default_colors

    COLORS.each_pair do |k,v|
      Ncurses.init_pair v[:number], v[:pair][0], v[:pair][1]
    end
  end

  def clean_up
    Ncurses.echo
    Ncurses.nocbreak
    Ncurses.nl
    Ncurses.endwin
  end
end
