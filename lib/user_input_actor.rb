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

    # Creating this otherwise unused window so that I can run getch() without
    # the implicit call to stdscr.refresh that it apparently precipitates.
    trash_win = Ncurses.newwin(1, 1, 0, 0)
    trash_win.keypad(true)

    catch(:shutdown) do
      while(ch = trash_win.getch)
        debug_message "getch: #{ch}"
        handle_modal_input(ch)
      end
    end
    debug_message "Caught :shutdown"
    $supervisor.do_shutdown
  end

  def handle_modal_input(ch)
    if ch == Ncurses::KEY_RESIZE # window resize
      publish "window_resized"
      return
    end
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
    when ??.ord
      publish "display_help"
    else
      debug_message "Unhandled user input: #{ch}"
    end
  end

  USER_INPUT_MAPPINGS = {
    "?" => {
      desc: "display help",
      action: -> { publish "display_help" }
    },
    "q" => {
      desc: "quit",
      action: -> { throw :shutdown }
    },
    "j" => {
      desc: "select next match",
      action: -> { publish "select_next_item" }
    },
    "k" => {
      desc: "select previous match",
      action: -> { publish "select_prev_item" }
    },
    14 => {
      key_desc: "ctrl-n",
      desc: "select first match in next file",
      action: -> { publish "select_next_file" }
    },
    16 => {
      key_desc: "ctrl-p",
      desc: "select first match in previous file",
      action: -> { publish "select_prev_file" }
    },
    13 => {
      key_desc: "enter",
      desc: "Tell editor to jump to match",
      action: -> { publish "tell_selected_item" }
    },
    Ncurses::KEY_DOWN => {
      key_desc: "down arrow",
      desc: "scroll down without changing selection",
      action: -> { publish "scroll_changed", DEFAULT_SCROLL_STEP }
    },
    Ncurses::KEY_UP => {
      key_desc: "up arrow",
      desc: "scroll up without changing selection",
      action: -> { publish "scroll_changed", DEFAULT_SCROLL_STEP * -1 }
    },
    "r" => {
      desc: "refresh search results",
      action: -> { publish "refresh" }
    },
    "[" => {
      desc: "decrease context lines",
      action: -> { publish "context_lines_changed", -1 }
    },
    "]" => {
      desc: "increase context lines",
      action: -> { publish "context_lines_changed", 1 }
    },
    "z" => {
      desc: "toggle showing match lines vs just matched files",
      action: -> { publish "show_match_lines_toggled" }
    },
    "y" => {
      desc: "copy selected match to system clipboard",
      action: -> { publish "copy_selected_item" }
    },
    "Y" => {
      desc: "copy selected match + context to system clipboard",
      action: -> { publish "copy_selected_item", true }
    },
  }

  def handle_working_set_input(ch)
    mapping = USER_INPUT_MAPPINGS[ch] || USER_INPUT_MAPPINGS[ch.chr]
    if mapping
      instance_exec(&mapping[:action])
    end
  rescue RangeError # ignore when .chr is out of range.  Just means it's not input we care about anyways.
  end

  def clean_up
    debug_message "done user input"
  end

end
