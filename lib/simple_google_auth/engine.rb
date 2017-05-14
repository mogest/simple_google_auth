module SimpleGoogleAuth
  class Engine < ::Rails::Engine
    initializer "simple_google_auth.load_helpers" do
      ActionController::Base.send :include, SimpleGoogleAuth::Controller
      ActionController::Base.send :helper_method, :google_auth_data

      ActionController::API.send :include, SimpleGoogleAuth::Controller
    end
  end
end
