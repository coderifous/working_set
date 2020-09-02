class View::Help < View::Base

  def self.render
    new.render
  end

  def render
    UserInputActor.set_user_input_mode :help
    clear_screen
    print_centered \
      [:cyan, "Help!"],
      "",
      [:blue, "Press 'q' to go back."]
  end

end

