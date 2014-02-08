module SimpleGoogleAuth
  Config = Struct.new(
    :client_id,
    :client_secret,
    :redirect_uri,
    :redirect_path,
    :failed_login_path,
    :authenticate,
    :ca_path,
    :google_auth_url,
    :google_token_url,
    :state_session_key_name,
    :data_session_key_name
  )

  mattr_accessor :config
  self.config = Config.new

  def self.configure
    yield config
  end

  def self.uri(state)
    query = {
      response_type: "code",
      client_id: config.client_id,
      redirect_uri: config.redirect_uri,
      scope: "openid email",
      state: state
    }

    "#{config.google_auth_url}?" + query.map {|k, v| "#{k}=#{CGI.escape v}"}.join("&")
  end
end

SimpleGoogleAuth.configure do |config|
  config.ca_path = %w(/etc/ssl/certs).detect {|dir| Dir.exists?(dir)}
  config.google_auth_url = "https://accounts.google.com/o/oauth2/auth"
  config.google_token_url = "https://accounts.google.com/o/oauth2/token"
  config.state_session_key_name = "simple-google-auth.state"
  config.data_session_key_name = "simple-google-auth.data"
  config.failed_login_path = "/"
  config.authenticate = lambda { raise "You must define an authenticate lambda that sets the session" }
end

require 'simple_google_auth/engine'
require 'simple_google_auth/controller'
require 'simple_google_auth/receiver'
