module SimpleGoogleAuth
  class Engine < ::Rails::Engine
    initializer "simple_google_auth.load_helpers" do
      ActiveSupport.on_load(:action_controller) do
        ActionController::Base.include(SimpleGoogleAuth::Controller)
        ActionController::Base.helper_method(:google_auth_data)
      end
    end
  end
end
