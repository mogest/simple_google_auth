require 'spec_helper'

RSpec.describe SimpleGoogleAuth::Receiver do
  class ReceiverFakeSession < Hash
    attr_reader :options

    def initialize
      super
      @options = {}
    end
  end

  let(:state) { "abcd" * 8 + "/place" }
  let(:code) { "sekrit" }
  let(:params) { {"state" => state, "code" => code} }
  let(:session) do
    ReceiverFakeSession.new.tap { |s| s[SimpleGoogleAuth.config.state_session_key_name] = state }
  end
  let(:id_token) { "header." + Base64.strict_encode64({"email" => "user@example.com"}.to_json).delete("=") }
  let(:auth_data) { {"id_token" => id_token, "expires_in" => 1200} }
  let(:api) { instance_double(SimpleGoogleAuth::OAuth, exchange_code_for_auth_token!: auth_data) }
  let(:authenticated_emails) { [] }

  before do
    allow(SimpleGoogleAuth::OAuth).to receive(:new).with(SimpleGoogleAuth.config).and_return(api)
    SimpleGoogleAuth.config.failed_login_path = "/error"
    SimpleGoogleAuth.config.authenticate = lambda { |data| authenticated_emails << data.email; true }
  end

  def env_for(params)
    Rack::MockRequest.env_for("/auth?" + Rack::Utils.build_query(params)).tap do |env|
      env["rack.session"] = session
    end
  end

  subject(:response) { described_class.new.call(env_for(params)) }

  context "when a valid code and state are provided" do
    it "exchanges the code, authenticates and redirects to the path embedded in the state" do
      expect(response).to eq [302, {"Location" => "/place"}, [" "]]
      expect(api).to have_received(:exchange_code_for_auth_token!).with(code)
      expect(authenticated_emails).to eq ["user@example.com"]
    end

    it "stores the auth data in the session" do
      response
      expect(session[SimpleGoogleAuth.config.data_session_key_name]).to eq auth_data
    end

    it "marks the session for renewal to defend against session fixation" do
      response
      expect(session.options[:renew]).to be true
    end

    it "removes the state from the session so the callback cannot be replayed" do
      response
      expect(session).to_not have_key(SimpleGoogleAuth.config.state_session_key_name)
    end

    context "with a session store that does not support options" do
      let(:session) { {SimpleGoogleAuth.config.state_session_key_name => state} }

      it "still logs in successfully" do
        expect(response).to eq [302, {"Location" => "/place"}, [" "]]
      end
    end

    context "when the state embeds a protocol-relative path (open redirect)" do
      let(:state) { "a" * 32 + "//evil.com" }

      it "redirects to / instead" do
        expect(response).to eq [302, {"Location" => "/"}, [" "]]
      end
    end

    context "when the state embeds a backslash-prefixed path (open redirect)" do
      let(:state) { "a" * 32 + "/\\evil.com" }

      it "redirects to / instead" do
        expect(response).to eq [302, {"Location" => "/"}, [" "]]
      end
    end

    context "when the state embeds a path that does not start with a slash" do
      let(:state) { "a" * 32 + "place" }

      it "redirects to / instead" do
        expect(response).to eq [302, {"Location" => "/"}, [" "]]
      end
    end

    context "when the path extractor returns nil" do
      before do
        SimpleGoogleAuth.config.authentication_uri_state_path_extractor = lambda { |state| nil }
      end

      it "redirects to / instead" do
        expect(response).to eq [302, {"Location" => "/"}, [" "]]
      end
    end
  end

  context "when the authenticator rejects the login" do
    before do
      SimpleGoogleAuth.config.authenticate = lambda { |data| false }
    end

    it "redirects to the failed login path with a message" do
      expect(response).to eq [302, {"Location" => "/error?message=Authentication+failed"}, [" "]]
    end

    it "does not store the auth data in the session" do
      response
      expect(session[SimpleGoogleAuth.config.data_session_key_name]).to be_nil
    end
  end

  context "when the state doesn't match" do
    let(:params) { {"state" => "doesnotmatch", "code" => code} }

    it "redirects to the failed login path with a message" do
      expect(response).to eq [302, {"Location" => "/error?message=Invalid+state+returned+from+Google"}, [" "]]
    end

    it "removes the state from the session even though the login failed" do
      response
      expect(session).to_not have_key(SimpleGoogleAuth.config.state_session_key_name)
    end
  end

  context "when the session holds no state and the callback omits it (forged callback)" do
    let(:session) { ReceiverFakeSession.new }
    let(:params) { {"code" => code} }

    it "rejects the login rather than treating two blank states as a match" do
      expect(response).to eq [302, {"Location" => "/error?message=Invalid+state+returned+from+Google"}, [" "]]
    end
  end

  context "when the google authentication fails" do
    let(:params) { {"state" => state, "error" => "bad stuff"} }

    it "redirects to the failed login path with a message" do
      expect(response).to eq [302, {"Location" => "/error?message=Authentication+failed%3A+bad+stuff"}, [" "]]
    end
  end

  context "when no code is returned (unexpected)" do
    let(:params) { {"state" => state} }

    it "redirects to the failed login path with a message" do
      expect(response).to eq [302, {"Location" => "/error?message=No+authentication+code+returned"}, [" "]]
    end
  end

  context "when the failed login path already has a query string" do
    let(:params) { {"state" => "doesnotmatch", "code" => code} }

    before do
      SimpleGoogleAuth.config.failed_login_path = "/error?source=google"
    end

    it "appends the message to the existing query string" do
      expect(response).to eq [302, {"Location" => "/error?source=google&message=Invalid+state+returned+from+Google"}, [" "]]
    end
  end

  context "when the token exchange fails with a provider error" do
    before do
      allow(api).to receive(:exchange_code_for_auth_token!).and_raise(SimpleGoogleAuth::ProviderError, "The server responded with error 500")
    end

    it "redirects to the failed login path with the error message" do
      expect(response).to eq [302, {"Location" => "/error?message=The+server+responded+with+error+500"}, [" "]]
    end
  end

  context "when the token exchange returns data without an id_token" do
    let(:auth_data) { {"expires_in" => 1200} }

    it "redirects to the failed login path rather than crashing" do
      expect(response[0]).to eq 302
      expect(response[1]["Location"]).to start_with "/error?message="
    end
  end
end
