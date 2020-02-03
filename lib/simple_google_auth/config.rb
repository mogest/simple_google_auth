module SimpleGoogleAuth
  config_fields = [
    :client_id,
    :client_secret,
    :redirect_uri,
    :redirect_path,
    :failed_login_path,
    :authenticate,
    :google_auth_url,
    :google_token_url,
    :state_session_key_name,
    :data_session_key_name,
    :request_parameters,
    :refresh_stale_tokens,
    :open_timeout,
    :read_timeout,
    :authentication_uri_state_builder,
    :authentication_uri_state_path_extractor,
  ]

  class Config < Struct.new(*config_fields)
    def ca_path=(value)
      Rails.logger.warn "ca_path is no longer used by SimpleGoogleAuth as OpenSSL is clever enough to find its ca_path now"
    end

    def client_id
      get_or_call super
    end

    def client_secret
      get_or_call super
    end

    def authenticate=(value)
      raise Error, "Your SimpleGoogleAuth authenticator must be an object that responds to :call, normally a lambda.  See documentation for configuration details." unless value.respond_to?(:call)

      super
    end

    def authentication_uri_state_builder=(value)
      raise Error, "Your SimpleGoogleAuth authentication_uri_state_builder must be an object that responds to :call, normally a lambda.  See documentation for configuration details." unless value.respond_to?(:call)

      super
    end

    def authentication_uri_state_path_extractor=(value)
      raise Error, "Your SimpleGoogleAuth authentication_uri_state_path_extractor must be an object that responds to :call, normally a lambda.  See documentation for configuration details." unless value.respond_to?(:call)

      super
    end

    private

    def get_or_call(value)
      value.respond_to?(:call) ? value.call : value
    end
  end
end
