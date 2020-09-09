class ViewRouterActor
  include BasicActor

  def initialize
    subscribe "welcome_user", :welcome_user
    subscribe "display_help", :display_help
    subscribe "display_working_set", :display_working_set
    subscribe "window_resized", :render_current_view
    subscribe "render_view", :render_view
    welcome_user
  end

  def welcome_user(_=nil)
    debug_message "displaying welcome_user!"
    render_view nil, View::WelcomeUser
  end

  def display_help(_)
    debug_message "displaying help!"
    render_view nil, View::Help
  end

  def display_working_set(_)
    debug_message "displaying working_set!"
    publish "render_working_set"
  end

  def render_view(_, view)
    @current_view = view
    render_current_view
  end

  def render_current_view(_=nil)
    debug_message "rendering view: #{@current_view.inspect}"
    @current_view&.render
  end

end

