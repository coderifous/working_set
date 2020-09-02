class UserInputActor
  include BasicActor

  finalizer :clean_up

  DEFAULT_SCROLL_STEP = 5

  def self.user_input_mode
    @user_input_mode
  end

  def self.prev_user_input_modes
    @prev_user_input_modes ||= []
  end

  def self.set_user_input_mode(mode)
    debug_message "set input mode: #{mode.inspect}"
    push_mode(mode)
  end

  def self.push_mode(mode)
    prev_user_input_modes << @user_input_mode if @user_input_mode
    @user_input_mode = mode
  end

  def self.pop_mode
    @user_input_mode = prev_user_input_modes.pop
  end

  def user_input_mode
    self.class.user_input_mode
  end

  def pop_mode
    self.class.pop_mode
  end

  def initialize
    async.watch_input
  end

  def watch_input
    catch(:shutdown) do
      while(ch = Ncurses.stdscr.getch)
        debug_message "getch: #{ch}"
        handle_modal_input(ch)
      end
    end
    debug_message "Caught :shutdown"
    $supervisor.do_shutdown
  end

  def handle_modal_input(ch)
    case user_input_mode
    when :welcome_user then handle_welcome_user_input(ch)
    when :help         then handle_help_input(ch)
    when :working_set  then handle_working_set_input(ch)
    else
      debug_message "Uncrecognized mode: #{user_input_mode.inspect}"
      throw :shutdown
    end
  end

  def handle_help_input(ch)
    case ch
    when ?q.ord
      mode = pop_mode
      case mode
      when :welcome_user then publish "welcome_user"
      when :working_set  then publish "display_working_set"
      else
        debug_message "Unrecognized mode from pop: #{mode.inspect}"
        throw :shutdown
      end
    else
      debug_message "Unhandled user input: #{ch}"
    end
  end

  def handle_welcome_user_input(ch)
    case ch
    when ?q.ord
      throw :shutdown
    when ?h.ord
      publish "display_help"
    else
      debug_message "Unhandled user input: #{ch}"
    end
  end

  def handle_working_set_input(ch)
    case ch
    when Ncurses::KEY_DOWN
      publish "scroll_changed", DEFAULT_SCROLL_STEP
    when Ncurses::KEY_UP
      publish "scroll_changed", DEFAULT_SCROLL_STEP * -1
    when ?[.ord
      publish "context_lines_changed", -1
    when ?].ord
      publish "context_lines_changed", 1
    when ?r.ord
      publish "refresh"
    when ?z.ord
      publish "show_match_lines_toggled"
    when ?y.ord
      publish "copy_selected_item"
    when ?h.ord
      publish "display_help"
    when ?q.ord
      throw :shutdown
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

  def clean_up
    debug_message "done user input"
  end

end
