module SimpleGoogleAuth
  class Receiver
    def call(env)
      request = Rack::Request.new(env)
      config = SimpleGoogleAuth.config

      # The state is single-use: remove it from the session up front so the
      # callback URL can't be replayed, whether this attempt succeeds or fails.
      state = request.session.delete(config.state_session_key_name)
      ensure_params_are_correct(request, state)

      api = SimpleGoogleAuth::OAuth.new(config)
      auth_data = api.exchange_code_for_auth_token!(request.params["code"])

      data = AuthDataPresenter.new(auth_data)
      raise Error, "Authentication failed" unless config.authenticate.call(data)

      renew_session(request)
      request.session[config.data_session_key_name] = auth_data

      path = config.authentication_uri_state_path_extractor.call(state)
      path = "/" unless safe_redirect_path?(path)
      [302, {"Location" => path}, [" "]]

    rescue Error => e
      uri = URI(config.failed_login_path)
      uri.query = uri.query ? "#{uri.query}&" : ""
      uri.query += "message=#{CGI.escape e.message}"
      [302, {"Location" => uri.to_s}, [" "]]
    end

    protected
    def ensure_params_are_correct(request, expected_state)
      if expected_state.blank? || !states_match?(request.params["state"], expected_state)
        raise Error, "Invalid state returned from Google"
      elsif request.params["error"]
        raise Error, "Authentication failed: #{request.params["error"]}"
      elsif request.params["code"].nil?
        raise Error, "No authentication code returned"
      end
    end

    private

    # Constant-time comparison so the CSRF state token isn't leaked via timing.
    # A blank expected state is rejected by the caller before we get here.
    def states_match?(actual, expected)
      return false if actual.nil?
      ActiveSupport::SecurityUtils.secure_compare(actual.to_s, expected.to_s)
    end

    # Only redirect back to a path on our own host. A safe path starts with a
    # single "/" that isn't followed by another "/" or "\" -- both of which a
    # browser can resolve to a different origin ("//evil.com", "/\evil.com").
    # Written as an allowlist so we don't have to chase every dangerous form.
    def safe_redirect_path?(path)
      path = path.to_s
      path.start_with?("/") && !path.start_with?("//", "/\\")
    end

    # Rotate the session on successful login to defend against session fixation.
    # No-op on session stores that don't expose options (e.g. in unit tests).
    def renew_session(request)
      session = request.session
      session.options[:renew] = true if session.respond_to?(:options) && session.options
    end
  end
end
