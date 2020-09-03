class View::WelcomeUser < View::Base

  def self.render
    new.render
  end

  def render
    UserInputActor.set_user_input_mode :welcome_user
    clear_screen
    print_centered \
      [:cyan, "Working Set"],
      "",
      "v#{WorkingSet::VERSION}",
      "by Jim Garvin et al.",
      "",
      [:blue, "Press '?' for help."],
      [:blue, "Press 'q' to quit."]
    refresh_screen
  end

end

