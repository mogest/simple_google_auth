require 'spec_helper'

RSpec.describe SimpleGoogleAuth do
  describe "::configure" do
    it "yields the config object" do
      SimpleGoogleAuth.configure do |config|
        expect(config).to be_a(SimpleGoogleAuth::Config)
      end
    end

    it "sets access_type to offline if refresh_stale_tokens is set" do
      SimpleGoogleAuth.configure do |config|
        config.refresh_stale_tokens = true
      end

      expect(SimpleGoogleAuth.config.request_parameters[:access_type]).to eq "offline"
    end

    it "does not set access_type if refresh_stale_tokens is not set" do
      SimpleGoogleAuth.configure {|config| }

      expect(SimpleGoogleAuth.config.request_parameters).to_not have_key(:access_type)
    end
  end

  describe "error hierarchy" do
    it "makes all errors rescuable as SimpleGoogleAuth::Error" do
      expect(SimpleGoogleAuth::ProviderError.ancestors).to include(SimpleGoogleAuth::Error)
      expect(SimpleGoogleAuth::NonJsonResponseError.ancestors).to include(SimpleGoogleAuth::ProviderError)
      expect(SimpleGoogleAuth::AuthDataPresenter::InvalidAuthDataError.ancestors).to include(SimpleGoogleAuth::Error)
    end
  end
end
