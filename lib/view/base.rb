class View::Base

  def refresh_screen
    Ncurses.stdscr.refresh
  end

  def clear_screen
    Ncurses.stdscr.clear
  end

  def color(name, window=Ncurses.stdscr)
    window.attron Ncurses.COLOR_PAIR(Colors[name][:number])
    yield if block_given?
    window.attroff Ncurses.COLOR_PAIR(Colors[name][:number])
  end

  def move(y, x, window = Ncurses.stdscr)
    window.move y, x
  end

  def printf(fmt, string)
    Ncurses.stdscr.printw fmt, string
  end

  def printw(string)
    Ncurses.stdscr.printw(string)
  end

  def puts(string="")
    print string + "\n"
  end

  def print(string)
    printw(sprintf "%s", string)
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
