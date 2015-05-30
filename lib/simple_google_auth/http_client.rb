module SimpleGoogleAuth
  class HttpClient
    def initialize(url)
      @uri = URI(url)
      @http = Net::HTTP.new(@uri.host, @uri.port)

      if @uri.scheme == "https"
        @http.use_ssl = true
        @http.verify_mode = OpenSSL::SSL::VERIFY_PEER
      end
    end

    def request(params)
      request = Net::HTTP::Post.new(@uri.request_uri)
      request.set_form_data(params)
      response = @http.request(request)

      if response.content_type != 'application/json'
        raise NonJsonResponseError, "The server responded with non-JSON content"
      end

      data = begin
        JSON.parse(response.body)
      rescue JSON::ParserError
        raise NonJsonResponseError, "The server responded with JSON content that was not parseable"
      end

      if response.code !~ /\A2\d\d\z/
        raise ProviderError, "The server responded with error #{response.code}: #{data.inspect}"
      end

      data
    end
  end
end
