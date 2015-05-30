require 'spec_helper'

describe SimpleGoogleAuth::HttpClient do
  describe "#request" do
    let(:http) { instance_double(Net::HTTP) }
    let(:request) { instance_double(Net::HTTP::Post) }
    let(:response) { instance_double(Net::HTTPSuccess, :body => 'someresponse') }

    before do
      expect(Net::HTTP).to receive(:new).with("some.host", 443).and_return(http)
      expect(http).to receive(:use_ssl=).with(true)
      expect(http).to receive(:verify_mode=).with(OpenSSL::SSL::VERIFY_PEER)
      expect(http).to receive(:request).with(request).and_return(response)

      expect(Net::HTTP::Post).to receive(:new).with("/somepath").and_return(request)
      expect(request).to receive(:set_form_data).with('some' => 'data')
    end

    subject { SimpleGoogleAuth::HttpClient.new("https://some.host/somepath") }

    it "makes a post request to the URL with the specified params and returns the body" do
      expect(subject.request('some' => 'data')).to eq 'someresponse'
    end
  end
end
