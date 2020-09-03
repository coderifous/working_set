class View::Help < View::Base

  def self.render
    new.render
  end

  def render
    UserInputActor.set_user_input_mode :help
    clear_screen
    move 0, 0
    puts "Key Bindings"
    puts "------------"
    puts
    UserInputActor::USER_INPUT_MAPPINGS.each_pair do |k,v|
      color(:cyan) do
        print " #{v[:key_desc] || k}"
      end
      puts " - #{v[:desc]}"
      puts
    end
    color(:blue) do
      print "Press 'q' to go back."
    end
  end

end

