module SimpleGoogleAuth
  class Receiver
    Error = Class.new(StandardError)

    def call(env)
      request = Rack::Request.new(env)
      config = SimpleGoogleAuth.config

      ensure_params_are_correct(request, config)
      auth_data = obtain_authentication_data(request.params["code"], config)
      id_data = decode_id_data(auth_data.delete("id_token"))

      raise Error, "Authentication failed" unless config.authenticate.call(id_data)

      request.session[config.data_session_key_name] = id_data.merge(auth_data)

      path = request.session[config.state_session_key_name][32..-1]
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

    def obtain_authentication_data(code, config)
      uri = URI(config.google_token_url)

      http = Net::HTTP.new(uri.host, uri.port)
      if uri.scheme == "https"
        http.use_ssl = true
        if config.ca_path
          http.verify_mode = OpenSSL::SSL::VERIFY_PEER
          http.ca_path = config.ca_path
        else
          http.verify_mode = OpenSSL::SSL::VERIFY_NONE
          Rails.logger.warn "SimpleGoogleAuth does not have a ca_path configured; SSL with Google is not protected"
        end
      end

      request = Net::HTTP::Post.new(uri.request_uri)
      request.set_form_data(
        code: code,
        client_id: config.client_id,
        client_secret: config.client_secret,
        redirect_uri: config.redirect_uri,
        grant_type: "authorization_code"
      )

      response = http.request(request)
      raise Error, "Failed to get an access token" unless response.is_a?(Net::HTTPSuccess)

      JSON.parse(response.body)
    end

    def decode_id_data(id_data)
      id_data_64 = id_data.split(".")[1]
      id_data_64 << "=" until id_data_64.length % 4 == 0
      JSON.parse(Base64.decode64(id_data_64))
    end
  end
end
