if defined?(Ncurses)
  Colors = {
    blue:  { pair: [Ncurses::COLOR_BLUE, -1] },
    cyan:  { pair: [Ncurses::COLOR_CYAN, -1] },
    red:   { pair: [Ncurses::COLOR_RED, -1] },
    white: { pair: [Ncurses::COLOR_WHITE, -1] },
    green: { pair: [Ncurses::COLOR_GREEN, -1] },
    yellow: { pair: [Ncurses::COLOR_YELLOW, -1] }
  }

  Colors.each_with_index do |(k,v),i|
    v[:number] = i + 1
  end
end

API_PORT_NUMBER = 3930
