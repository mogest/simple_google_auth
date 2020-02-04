require 'spec_helper'

describe SimpleGoogleAuth::Controller do
  class TestController
    include SimpleGoogleAuth::Controller

    attr_reader :request, :session

    def redirect_to(x)
    end
  end

  subject { TestController.new }

  let(:id_data) { Base64.encode64({email:"hi@hi"}.to_json).gsub('=', '') }
  let(:auth_data) { {"id_token" => "123." + id_data} }
  let(:request) { double(path: "/somepath") }
  let(:session) { {} }

  before do
    allow(subject).to receive(:request).and_return(request)
    allow(subject).to receive(:session).and_return(session)
  end

  describe "#redirect_if_not_google_authenticated" do
    it "redirects if not authenticated" do
      SimpleGoogleAuth.config.authentication_uri_state_builder = ->(request) { 'prefix-/somepath' }

      expect(subject).to receive(:redirect_to).with("https://accounts.google.com/o/oauth2/auth?scope=openid+email&response_type=code&client_id=123&redirect_uri=%2Fabc&state=prefix-%2Fsomepath")
      subject.send(:redirect_if_not_google_authenticated)
    end

    it "does nothing if authenticated" do
      session[SimpleGoogleAuth.config.data_session_key_name] = auth_data
      expect(subject).to_not receive(:redirect_to)
      subject.send(:redirect_if_not_google_authenticated)
    end
  end

  describe "#google_auth_data" do
    it "returns data from the session" do
      session[SimpleGoogleAuth.config.data_session_key_name] = auth_data
      data = subject.send(:google_auth_data)
      expect(data.email).to eq 'hi@hi'
    end

    it "refreshes the token data if it's expired and refresh_stale_tokens is true"
  end
end
