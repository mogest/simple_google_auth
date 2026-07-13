require 'spec_helper'

RSpec.describe SimpleGoogleAuth::Config do
  subject { SimpleGoogleAuth::Config.new }

  describe "#client_id" do
    it "gets the value if it doesn't respond to call" do
      subject.client_id = '12345'
      expect(subject.client_id).to eq '12345'
    end

    it "calls to get the value if it responds to call" do
      subject.client_id = lambda { '12345' }
      expect(subject.client_id).to eq '12345'
    end
  end

  describe "#client_secret" do
    it "gets the value if it doesn't respond to call" do
      subject.client_secret = 'abcde'
      expect(subject.client_secret).to eq 'abcde'
    end

    it "calls to get the value if it responds to call" do
      subject.client_secret = lambda { 'abcde' }
      expect(subject.client_secret).to eq 'abcde'
    end
  end

  describe "#authenticate=" do
    it "saves the value if it is callable" do
      fn = lambda {|data| true}
      subject.authenticate = fn
      expect(subject.authenticate).to eql fn
    end

    it "raises if the value isn't callable" do
      expect {
        subject.authenticate = "not a lambda"
      }.to raise_error(SimpleGoogleAuth::Error, /responds to :call/)
    end
  end

  describe "#ca_path=" do
    it "logs a warning" do
      Rails.logger ||= double
      expect(Rails.logger).to receive(:warn)
      subject.ca_path = "/etc/certs"
    end
  end

  describe "#authentication_uri_state_builder=" do
    it "saves the value if it is callable" do
      fn = lambda {|request| 'state'}
      subject.authentication_uri_state_builder = fn
      expect(subject.authentication_uri_state_builder).to eql fn
    end

    it "raises if the value isn't callable" do
      expect {
        subject.authentication_uri_state_builder = "not a lambda"
      }.to raise_error(SimpleGoogleAuth::Error, /responds to :call/)
    end
  end

  describe "#authentication_uri_state_path_extractor=" do
    it "saves the value if it is callable" do
      fn = lambda {|state| '/path'}
      subject.authentication_uri_state_path_extractor = fn
      expect(subject.authentication_uri_state_path_extractor).to eql fn
    end

    it "raises if the value isn't callable" do
      expect {
        subject.authentication_uri_state_path_extractor = "not a lambda"
      }.to raise_error(SimpleGoogleAuth::Error, /responds to :call/)
    end
  end
end
