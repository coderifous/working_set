class View::WelcomeUser < View::Base

  def self.render
    new.render
  end

  def render
    UserInputActor.set_user_input_mode :welcome_user
    stdscr.clear
    print_centered \
      [:cyan, "Working Set"],
      "",
      "v#{WorkingSet::VERSION}",
      "by Jim Garvin et al.",
      "",
      [:blue, "Press '?' for help."],
      [:blue, "Press 'q' to quit."]
    stdscr.refresh
  end

  private

  def print_centered(*lines)
    start_y = Ncurses.LINES / 2 - lines.size / 2
    lines.each_with_index do |line, i|
      color, msg = if Array === line
                     line
                   else
                     [:white, line]
                   end
      x = Ncurses.COLS / 2 - msg.size / 2
      stdscr.move start_y + i, x
      with_color(stdscr, color) do
        stdscr.printw msg
      end
    end
  end

end

