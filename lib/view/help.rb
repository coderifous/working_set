class View::Help < View::Base

  def self.render
    new.render
  end

  def render
    UserInputActor.set_user_input_mode :help
    stdscr.clear
    stdscr.move 0, 0
    stdscr.printw "Key Bindings\n"
    stdscr.printw "------------\n\n"

    UserInputActor::USER_INPUT_MAPPINGS.each_pair do |k,v|
      with_color(stdscr, :cyan) do
        stdscr.printw " #{v[:key_desc] || k}"
      end
      stdscr.printw " - #{v[:desc]}\n\n"
    end
    with_color(stdscr, :blue) do
      stdscr.printw "Press 'q' to go back."
    end

    stdscr.refresh
  end

end

