require 'spec_helper'

RSpec.describe SimpleGoogleAuth::AuthorizationUriBuilder do
  subject do
    SimpleGoogleAuth::AuthorizationUriBuilder.new("somestate")
  end

  describe "#uri" do
    it "constructs an authorization URI" do
      expect(subject.uri).to eq 'https://accounts.google.com/o/oauth2/auth?scope=openid+email&response_type=code&client_id=123&redirect_uri=%2Fabc&state=somestate'
    end

    it "includes custom request parameters" do
      SimpleGoogleAuth.config.request_parameters = {scope: "openid email", hd: "example.com"}

      expect(subject.uri).to include("hd=example.com")
    end

    it "does not allow request parameters to override protocol parameters" do
      SimpleGoogleAuth.config.request_parameters = {response_type: "token"}

      expect(subject.uri).to include("response_type=code")
      expect(subject.uri).to_not include("response_type=token")
    end

    it "escapes the state" do
      builder = SimpleGoogleAuth::AuthorizationUriBuilder.new("a state&value")

      expect(builder.uri).to end_with("state=a+state%26value")
    end
  end
end
