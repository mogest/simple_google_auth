require 'spec_helper'

RSpec.describe SimpleGoogleAuth::Controller do
  class TestController
    include SimpleGoogleAuth::Controller

    attr_reader :request, :session

    def redirect_to(x)
    end
  end

  def build_id_token(payload)
    "header." + Base64.strict_encode64(payload.to_json).delete("=")
  end

  subject(:controller) { TestController.new }

  let(:id_token) { build_id_token("email" => "hi@hi") }
  let(:auth_data) { {"id_token" => id_token} }
  let(:request) { double(path: "/somepath") }
  let(:session) { {} }
  let(:data_key) { SimpleGoogleAuth.config.data_session_key_name }
  let(:state_key) { SimpleGoogleAuth.config.state_session_key_name }

  before do
    allow(controller).to receive(:request).and_return(request)
    allow(controller).to receive(:session).and_return(session)
  end

  describe "#redirect_if_not_google_authenticated" do
    it "redirects if not authenticated" do
      SimpleGoogleAuth.config.authentication_uri_state_builder = ->(request) { 'prefix-/somepath' }

      expect(controller).to receive(:redirect_to).with("https://accounts.google.com/o/oauth2/auth?scope=openid+email&response_type=code&client_id=123&redirect_uri=%2Fabc&state=prefix-%2Fsomepath")
      controller.send(:redirect_if_not_google_authenticated)
    end

    it "stores the generated state in the session" do
      SimpleGoogleAuth.config.authentication_uri_state_builder = ->(request) { 'prefix-/somepath' }

      controller.send(:redirect_if_not_google_authenticated)
      expect(session[state_key]).to eq 'prefix-/somepath'
    end

    it "generates a state whose path is recoverable by the default extractor" do
      controller.send(:redirect_if_not_google_authenticated)

      state = session[state_key]
      path = SimpleGoogleAuth.config.authentication_uri_state_path_extractor.call(state)
      expect(path).to eq "/somepath"
    end

    it "does nothing if authenticated" do
      session[data_key] = auth_data
      expect(controller).to_not receive(:redirect_to)
      controller.send(:redirect_if_not_google_authenticated)
    end

    it "redirects if the session holds invalid auth data" do
      session[data_key] = {"junk" => true}
      expect(controller).to receive(:redirect_to)
      controller.send(:redirect_if_not_google_authenticated)
    end
  end

  describe "#google_auth_data" do
    it "returns data from the session" do
      session[data_key] = auth_data
      data = controller.send(:google_auth_data)
      expect(data.email).to eq 'hi@hi'
    end

    it "returns nil when the session is empty" do
      expect(controller.send(:google_auth_data)).to be_nil
    end

    it "returns nil when the session holds invalid auth data" do
      session[data_key] = {"junk" => true}
      expect(controller.send(:google_auth_data)).to be_nil
    end

    it "returns nil when the session holds a malformed id_token" do
      session[data_key] = {"id_token" => "notajwt"}
      expect(controller.send(:google_auth_data)).to be_nil
    end

    it "memoizes the presenter" do
      session[data_key] = auth_data
      first = controller.send(:google_auth_data)
      expect(controller.send(:google_auth_data)).to be first
    end

    context "when refresh_stale_tokens is enabled" do
      let(:api) { instance_double(SimpleGoogleAuth::OAuth) }

      before do
        SimpleGoogleAuth.config.refresh_stale_tokens = true
      end

      context "and the token has expired" do
        let(:auth_data) do
          {"id_token" => id_token, "refresh_token" => "refresh-me", "expires_at" => (Time.now - 60).to_s}
        end
        let(:new_auth_data) do
          {"id_token" => build_id_token("email" => "new@hi"), "expires_at" => (Time.now + 3600).to_s}
        end

        before do
          session[data_key] = auth_data
          expect(SimpleGoogleAuth::OAuth).to receive(:new).with(SimpleGoogleAuth.config).and_return(api)
          expect(api).to receive(:refresh_auth_token!).with("refresh-me").and_return(new_auth_data)
        end

        it "refreshes the token and returns the new data" do
          data = controller.send(:google_auth_data)
          expect(data.email).to eq 'new@hi'
        end

        it "stores the refreshed auth data in the session" do
          controller.send(:google_auth_data)
          expect(session[data_key]).to eq new_auth_data
        end
      end

      context "and the auth data has no expiry time" do
        let(:auth_data) { {"id_token" => id_token, "refresh_token" => "refresh-me"} }
        let(:new_auth_data) do
          {"id_token" => build_id_token("email" => "new@hi"), "expires_at" => (Time.now + 3600).to_s}
        end

        it "treats the token as stale and refreshes it" do
          session[data_key] = auth_data
          expect(SimpleGoogleAuth::OAuth).to receive(:new).and_return(api)
          expect(api).to receive(:refresh_auth_token!).with("refresh-me").and_return(new_auth_data)

          expect(controller.send(:google_auth_data).email).to eq 'new@hi'
        end
      end

      context "and the token has expired but there is no refresh token" do
        let(:auth_data) { {"id_token" => id_token, "expires_at" => (Time.now - 60).to_s} }

        it "clears the session data and returns nil" do
          session[data_key] = auth_data
          expect(SimpleGoogleAuth::OAuth).to receive(:new).and_return(api)
          expect(api).to receive(:refresh_auth_token!).with(nil).and_return(nil)

          expect(controller.send(:google_auth_data)).to be_nil
          expect(session[data_key]).to be_nil
        end
      end

      context "and the token is still fresh" do
        let(:auth_data) do
          {"id_token" => id_token, "refresh_token" => "refresh-me", "expires_at" => (Time.now + 3600).to_s}
        end

        it "does not refresh the token" do
          session[data_key] = auth_data
          expect(SimpleGoogleAuth::OAuth).to_not receive(:new)

          expect(controller.send(:google_auth_data).email).to eq 'hi@hi'
        end
      end
    end

    context "when refresh_stale_tokens is disabled" do
      it "does not refresh an expired token" do
        session[data_key] = auth_data.merge("expires_at" => (Time.now - 60).to_s)
        expect(SimpleGoogleAuth::OAuth).to_not receive(:new)

        expect(controller.send(:google_auth_data).email).to eq 'hi@hi'
      end
    end
  end
end
