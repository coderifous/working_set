class View::Base

  def refresh_screen
    Ncurses.stdscr.refresh
  end

  def clear_screen
    Ncurses.stdscr.clear
  end

  def color(name)
    Ncurses.attron Ncurses.COLOR_PAIR(Colors[name][:number])
    yield if block_given?
    Ncurses.attroff Ncurses.COLOR_PAIR(Colors[name][:number])
  end

  def move(y, x)
    Ncurses.stdscr.move y, x
  end

  def printf(fmt, string)
    Ncurses.stdscr.printw fmt, string
  end

  def print(string)
    printf "%s", string
  end

  def puts(string="")
    print string + "\n"
  end

  def print_centered(*lines)
    start_y = Ncurses.LINES / 2 - lines.size / 2
    lines.each_with_index do |line, i|
      with_color, msg = if Array === line
                     line
                   else
                     [:white, line]
                   end
      x = Ncurses.COLS / 2 - msg.size / 2
      move start_y + i, x
      color(with_color) do
        print msg
      end
    end
  end

end
