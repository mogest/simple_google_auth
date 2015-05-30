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
      response.body
    end
  end
end
