module SimpleGoogleAuth
  class AuthorizationUriBuilder
    def initialize(state)
      @state = state
    end

    def uri
      params = config.request_parameters.merge(
        response_type: "code",
        client_id:     config.client_id,
        redirect_uri:  config.redirect_uri,
        state:         @state
      )

      "#{config.google_auth_url}?#{params_to_query(params)}"
    end

    private

    def config
      SimpleGoogleAuth.config
    end

    def params_to_query(params)
      params.map {|k, v| "#{CGI.escape k.to_s}=#{CGI.escape v.to_s}"}.join("&")
    end
  end
end
