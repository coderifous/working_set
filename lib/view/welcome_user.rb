class View::WelcomeUser < View::Base

  def self.render
    new.render
  end

  def render
    print_centered \
      [:cyan, "Working Set"],
      "v#{WorkingSet::VERSION}",
      "",
      [:yellow, "Press 'h' for help."],
      [:blue, "Press 'q' to quit."]
  end

end

