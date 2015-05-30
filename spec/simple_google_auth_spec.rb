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
end
