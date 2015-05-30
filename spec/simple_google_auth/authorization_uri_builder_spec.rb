require 'spec_helper'

describe SimpleGoogleAuth::AuthorizationUriBuilder do
  subject do
    SimpleGoogleAuth::AuthorizationUriBuilder.new("somestate")
  end

  describe "#uri" do
    it "constructs an authorization URI" do
      expect(subject.uri).to eq 'https://accounts.google.com/o/oauth2/auth?scope=openid+email&response_type=code&client_id=123&redirect_uri=%2Fabc&state=somestate'
    end
  end
end
