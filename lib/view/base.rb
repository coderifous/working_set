class View::Base

  def stdscr
    Ncurses.stdscr
  end

  def with_color(window, name)
    window.attron Ncurses.COLOR_PAIR(Colors[name][:number])
    yield if block_given?
    window.attroff Ncurses.COLOR_PAIR(Colors[name][:number])
  end

end
