module BasicActor

  def self.included(includer)
    includer.include Celluloid
    includer.include Celluloid::Notifications
  end

end
