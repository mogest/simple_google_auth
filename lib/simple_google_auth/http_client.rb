module SimpleGoogleAuth
  class HttpClient
    def initialize(url, ca_path)
      @uri = URI(url)
      @http = Net::HTTP.new(@uri.host, @uri.port)
      setup_https(ca_path)
    end

    def request(params)
      request = Net::HTTP::Post.new(@uri.request_uri)
      request.set_form_data(params)
      response = @http.request(request)
      response.body
    end

    private
    def setup_https(ca_path)
      if @uri.scheme == "https"
        @http.use_ssl = true
        if ca_path
          @http.verify_mode = OpenSSL::SSL::VERIFY_PEER
          @http.ca_path = ca_path
        else
          @http.verify_mode = OpenSSL::SSL::VERIFY_NONE
          Rails.logger.warn "SimpleGoogleAuth does not have a ca_path configured; SSL with Google is not protected"
        end
      end
    end
  end
end
