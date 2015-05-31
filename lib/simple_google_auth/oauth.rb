module SimpleGoogleAuth
  class OAuth
    def initialize(config)
      @config = config
      @client = HttpClient.new(@config.google_token_url)
    end

    def exchange_code_for_auth_token!(code)
      response = @client.request(
        code: code,
        grant_type: "authorization_code",
        client_id: @config.client_id,
        client_secret: @config.client_secret,
        redirect_uri: @config.redirect_uri)

      parse_auth_response(response)
    end

    def refresh_auth_token!(refresh_token)
      return if refresh_token.blank?

      response = @client.request(
        refresh_token: refresh_token,
        client_id: @config.client_id,
        client_secret: @config.client_secret,
        grant_type: "refresh_token")

      response["refresh_token"] ||= refresh_token

      parse_auth_response(response)
    end

    private
    def parse_auth_response(auth_data)
      validate_data_present!(auth_data)

      auth_data["expires_at"] = calculate_expiry(auth_data).to_s

      auth_data
    end

    def validate_data_present!(auth_data)
      %w(id_token expires_in).each do |field|
        if auth_data[field].blank?
          raise Error, "Expecting field '#{field}' to be set but it is blank"
        end
      end

      if !auth_data['expires_in'].is_a?(Numeric) || auth_data['expires_in'] <= 0
        raise Error, "Field 'expires_in' must be a number greater than 0"
      end
    end

    def calculate_expiry(auth_data)
      Time.now + auth_data["expires_in"] - 5.seconds
    end
  end
end
