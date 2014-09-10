module SimpleGoogleAuth
  module Controller
    protected
    def redirect_if_not_google_authenticated
      redirect_to google_authentication_uri if google_auth_data.nil?
    end

    def google_authentication_uri
      state = session[SimpleGoogleAuth.config.state_session_key_name] = SecureRandom.hex + request.path
      SimpleGoogleAuth.uri(state)
    end

    def google_auth_data
      refresh_google_auth_data if google_auth_data_stale?
      session[SimpleGoogleAuth.config.data_session_key_name]
    end

    private

    def refresh_google_auth_data
      api = SimpleGoogleAuth::Oauth.new(SimpleGoogleAuth.config)
      auth_data = api.refresh_auth_token!(google_auth_data["refresh_token"])
      session[SimpleGoogleAuth.config.data_session_key_name] = auth_data
    end


    def google_auth_data_stale?
      Time.parse(google_auth_data["expires_at"]).past?
    end
  end
end
