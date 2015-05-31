module SimpleGoogleAuth
  class AuthDataPresenter
    InvalidAuthDataError = Class.new(Error)

    FIELDS = %w(
      access_token
      expires_in
      token_type
      refresh_token
      id_token
      iss
      at_hash
      email_verified
      sub
      azp
      email
      aud
      iat
      exp
      hd
      expires_at
    )

    def initialize(auth_data)
      raise InvalidAuthDataError if auth_data["id_token"].nil?

      token_data = unpack_json_web_token(auth_data["id_token"])
      @data = auth_data.merge(token_data)
    end

    def [](field)
      @data[field.to_s]
    end

    FIELDS.each do |field|
      define_method(field) { @data[field.to_s] }
    end

    private

    def unpack_json_web_token(id_token)
      # We don't worry about validating the signature because we got this JWT directly
      # from Google over HTTPS (see
      # https://developers.google.com/identity/protocols/OpenIDConnect#obtainuserinfo)
      signature, id_data_64 = id_token.split(".")
      id_data_64 << "=" until id_data_64.length % 4 == 0
      JSON.parse(Base64.decode64(id_data_64))
    end
  end
end
