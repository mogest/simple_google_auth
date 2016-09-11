module SimpleGoogleAuth
  class HttpClient
    DEFAULT_OPEN_TIMEOUT = 15
    DEFAULT_READ_TIMEOUT = 15

    def initialize(url, open_timeout: DEFAULT_OPEN_TIMEOUT, read_timeout: DEFAULT_READ_TIMEOUT)
      @uri = URI(url)
      @http = Net::HTTP.new(@uri.host, @uri.port)
      @http.open_timeout = open_timeout
      @http.read_timeout = read_timeout

      if @uri.scheme == "https"
        @http.use_ssl = true
        @http.verify_mode = OpenSSL::SSL::VERIFY_PEER
      end
    end

    def request(params)
      request = Net::HTTP::Post.new(@uri.request_uri)
      request.set_form_data(params)

      response = begin
        @http.request(request)
      rescue Net::OpenTimeout, Net::ReadTimeout => e
        raise ProviderError, "A #{e.class.name} occurred while communicating with the server"
      end

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
