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
      session[SimpleGoogleAuth.config.data_session_key_name]
    end
  end
end
