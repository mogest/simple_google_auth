require 'spec_helper'

describe SimpleGoogleAuth do
  describe "::configure" do
    it "yields the config object" do
      SimpleGoogleAuth.configure do |config|
        expect(config).to be_a(SimpleGoogleAuth::Config)
      end
    end

    it "sets access_type to offline if refresh_stale_tokens set"
  end

  describe "::uri" do
    subject { SimpleGoogleAuth.uri('somestate') }

    it "constructs an authorization URI" do
      expect(subject).to eq 'https://accounts.google.com/o/oauth2/auth?scope=openid+email&response_type=code&client_id=123&redirect_uri=%2Fabc&state=somestate'
    end
  end
end
