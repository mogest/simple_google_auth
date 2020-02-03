module SimpleGoogleAuth
  class Receiver
    def call(env)
      request = Rack::Request.new(env)
      config = SimpleGoogleAuth.config
      ensure_params_are_correct(request, config)

      api = SimpleGoogleAuth::OAuth.new(config)
      auth_data = api.exchange_code_for_auth_token!(request.params["code"])

      data = AuthDataPresenter.new(auth_data)
      raise Error, "Authentication failed" unless config.authenticate.call(data)

      request.session[config.data_session_key_name] = auth_data

      path = config.authentication_uri_state_path_extractor.call(request.session[config.state_session_key_name])
      path = "/" if path.blank?
      [302, {"Location" => path}, [" "]]

    rescue Error => e
      uri = URI(config.failed_login_path)
      uri.query = uri.query ? "#{uri.query}&" : ""
      uri.query += "message=#{CGI.escape e.message}"
      [302, {"Location" => uri.to_s}, [" "]]
    end

    protected
    def ensure_params_are_correct(request, config)
      if request.params["state"] != request.session[config.state_session_key_name]
        raise Error, "Invalid state returned from Google"
      elsif request.params["error"]
        raise Error, "Authentication failed: #{request.params["error"]}"
      elsif request.params["code"].nil?
        raise Error, "No authentication code returned"
      end
    end
  end
end
