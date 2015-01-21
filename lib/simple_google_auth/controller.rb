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
      return unless google_auth_data_from_session

      refresh_google_auth_data if google_auth_data_stale?
      google_auth_data_from_session
    end

    private

    def refresh_google_auth_data
      api = SimpleGoogleAuth::OAuth.new(SimpleGoogleAuth.config)

      auth_data = api.refresh_auth_token!(google_auth_data_from_session["refresh_token"])

      session[SimpleGoogleAuth.config.data_session_key_name] = auth_data
    end

    def google_auth_data_from_session
      session[SimpleGoogleAuth.config.data_session_key_name]
    end

    def google_auth_data_stale?
      expiry_time = google_auth_data_from_session["expires_at"]

      expiry_time.nil? || Time.parse(expiry_time).past?
    end
  end
end
