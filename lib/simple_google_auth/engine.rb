module SimpleGoogleAuth
  class Engine < ::Rails::Engine
    initializer "simple_google_auth.load_helpers" do
      ActiveSupport.on_load(:action_controller) do
        include SimpleGoogleAuth::Controller
        helper_method :google_auth_data
      end
    end
  end
end
