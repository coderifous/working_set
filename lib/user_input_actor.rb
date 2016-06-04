class UserInputActor
  include BasicActor

  finalizer :clean_up

  DEFAULT_SCROLL_STEP = 5

  def initialize
    async.watch_input
  end

  def watch_input
    while(ch = Ncurses.stdscr.getch)
      debug_message "getch: #{ch}"
      case ch
      when Ncurses::KEY_DOWN
        publish "scroll_changed", DEFAULT_SCROLL_STEP
      when Ncurses::KEY_UP
        publish "scroll_changed", DEFAULT_SCROLL_STEP * -1
      when ?r.ord
        publish "refresh"
      when ?z.ord
        publish "show_match_lines_toggled"
      when ?q.ord
        Celluloid.shutdown
      when ?j.ord
        publish "select_next_item"
      when ?k.ord
        publish "select_prev_item"
      when 14 # ctrl-n
        publish "select_next_file"
      when 16 # ctrl-p
        publish "select_prev_file"
      when 13
        publish "tell_selected_item"
      end
    end
  end

  def clean_up
    debug_message "done user input"
  end

end
