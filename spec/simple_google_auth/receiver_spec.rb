require 'spec_helper'

describe SimpleGoogleAuth::Receiver do
  let(:authenticator) { double(call: true) }
  let(:authentication_result) { true }
  let(:session) { double }
  let(:state) { "abcd" * 8 + "/place" }
  let(:code) { "sekrit" }
  let(:params) { {"state" => state, "code" => code} }
  let(:request) { instance_double(Rack::Request, session: session, params: params) }
  let(:api) { instance_double(SimpleGoogleAuth::OAuth) }
  let(:auth_data) { double }
  let(:env) { double }
  let(:auth_data_presenter) { instance_double(SimpleGoogleAuth::AuthDataPresenter) }

  before do
    expect(Rack::Request).to receive(:new).with(env).and_return(request)
    expect(session).to receive(:[]).at_least(:once).with('simple-google-auth.state').and_return(state)

    SimpleGoogleAuth.config.authenticate = authenticator
    SimpleGoogleAuth.config.failed_login_path = '/error'
  end

  subject { SimpleGoogleAuth::Receiver.new.call(env) }

  context "when a valid code is provided to the receiver" do
    before do
      expect(SimpleGoogleAuth::OAuth).to receive(:new).with(SimpleGoogleAuth.config).and_return(api)
      expect(api).to receive(:exchange_code_for_auth_token!).with(code).and_return(auth_data)

      expect(SimpleGoogleAuth::AuthDataPresenter).to receive(:new).with(auth_data).and_return(auth_data_presenter)
      expect(authenticator).to receive(:call).with(auth_data_presenter).and_return(authentication_result)
    end

    context "and the authenticator accepts the login" do
      before do
        expect(session).to receive(:[]=).with('simple-google-auth.data', auth_data)
      end

      it "redirects to the URL specified in the session" do
        expect(subject).to eq [302, {"Location" => "/place"}, [" "]] 
      end
    end

    context "and the authenticator rejects the login" do
      let(:authentication_result) { false }

      it "redirects to the failed login path with a message" do
        expect(subject).to eq [302, {"Location" => "/error?message=Authentication+failed"}, [" "]] 
      end
    end
  end

  context "when the state doesn't match" do
    let(:params) { {"state" => "doesnotmatch", "code" => code} }

    it "redirects to the failed login path with a message" do
      expect(subject).to eq [302, {"Location" => "/error?message=Invalid+state+returned+from+Google"}, [" "]] 
    end
  end

  context "when the google authentication fails" do
    let(:params) { {"state" => state, "error" => "bad stuff"} }

    it "redirects to the failed login path with a message" do
      expect(subject).to eq [302, {"Location" => "/error?message=Authentication+failed%3A+bad+stuff"}, [" "]] 
    end
  end

  context "when no code is returned (unexpected)" do
    let(:params) { {"state" => state} }

    it "redirects to the failed login path with a message" do
      expect(subject).to eq [302, {"Location" => "/error?message=No+authentication+code+returned"}, [" "]] 
    end
  end
end
