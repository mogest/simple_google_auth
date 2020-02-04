module SimpleGoogleAuth
  module Controller
    protected

    def redirect_if_not_google_authenticated
      redirect_to google_authentication_uri if google_auth_data.nil?
    end

    def google_authentication_uri
      state = session[SimpleGoogleAuth.config.state_session_key_name] = SimpleGoogleAuth.config.authentication_uri_state_builder.call(request)
      SimpleGoogleAuth::AuthorizationUriBuilder.new(state).uri
    end

    def google_auth_data
      return unless cached_google_auth_data

      if should_refresh_google_auth_data?
        refresh_google_auth_data
      end
      cached_google_auth_data
    end

    private

    def refresh_google_auth_data
      api = SimpleGoogleAuth::OAuth.new(SimpleGoogleAuth.config)
      auth_data = api.refresh_auth_token!(cached_google_auth_data["refresh_token"])

      session[SimpleGoogleAuth.config.data_session_key_name] = auth_data
      @_google_auth_data_presenter = nil
    end

    def cached_google_auth_data
      @_google_auth_data_presenter ||= google_auth_data_from_session
    end

    def google_auth_data_from_session
      if auth_data = session[SimpleGoogleAuth.config.data_session_key_name]
        AuthDataPresenter.new(auth_data)
      end
    rescue AuthDataPresenter::InvalidAuthDataError
    end

    def should_refresh_google_auth_data?
      SimpleGoogleAuth.config.refresh_stale_tokens && google_auth_data_stale?
    end

    def google_auth_data_stale?
      expiry_time = cached_google_auth_data["expires_at"]

      expiry_time.nil? || Time.parse(expiry_time).past?
    end
  end
end
