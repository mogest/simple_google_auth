require 'spec_helper'

describe SimpleGoogleAuth::Config do
  subject { SimpleGoogleAuth::Config.new }

  describe "#get_or_call" do
    it "gets the value if it doesn't respond to call" do
      subject.client_id = '12345'
      expect(subject.get_or_call(:client_id)).to eq '12345'
    end

    it "calls to get the value if it responds to call" do
      subject.client_id = lambda { '12345' }
      expect(subject.get_or_call(:client_id)).to eq '12345'
    end
  end

  describe "#ca_path=" do
    it "logs a warning" do
      Rails.logger ||= double
      expect(Rails.logger).to receive(:warn)
      subject.ca_path = "/etc/certs"
    end
  end
end
