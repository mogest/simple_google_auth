require 'spec_helper'

describe SimpleGoogleAuth::HttpClient do
  describe "#request" do
    let(:http) { instance_double(Net::HTTP) }
    let(:request) { instance_double(Net::HTTP::Post) }

    before do
      expect(Net::HTTP).to receive(:new).with("some.host", 443).and_return(http)
      expect(http).to receive(:use_ssl=).with(true)
      expect(http).to receive(:verify_mode=).with(OpenSSL::SSL::VERIFY_PEER)
      expect(http).to receive(:request).with(request).and_return(response)

      expect(Net::HTTP::Post).to receive(:new).with("/somepath").and_return(request)
      expect(request).to receive(:set_form_data).with('some' => 'data')
    end

    subject { SimpleGoogleAuth::HttpClient.new("https://some.host/somepath") }

    context "when the call is successful" do
      let(:response) do
        instance_double(
          Net::HTTPSuccess,
          code: '200',
          body: {"data" => "very"}.to_json,
          content_type: 'application/json'
        )
      end

      it "returns the server's response" do
        expect(subject.request('some' => 'data')).to eq("data" => "very")
      end
    end

    context "when non-json data is returned" do
      let(:response) do
        instance_double(
          Net::HTTPSuccess,
          code: '200',
          body: "some html",
          content_type: 'text/html'
        )
      end

      it "raises an error" do
        expect { subject.request('some' => 'data') }.to raise_error(SimpleGoogleAuth::NonJsonResponseError, /non-JSON/)
      end
    end

    context "when non-json-parseable data is returned" do
      let(:response) do
        instance_double(
          Net::HTTPSuccess,
          code: '200',
          body: "some html",
          content_type: 'application/json'
        )
      end

      it "raises an error" do
        expect { subject.request('some' => 'data') }.to raise_error(SimpleGoogleAuth::NonJsonResponseError, /parseable/)
      end
    end

    context "when non-successful json data is returned" do
      let(:response) do
        instance_double(
          Net::HTTPSuccess,
          code: '400',
          body: {"data" => "very"}.to_json,
          content_type: 'application/json'
        )
      end

      it "raises an error" do
        expect { subject.request('some' => 'data') }.to raise_error(SimpleGoogleAuth::ProviderError, /400.+very/)
      end
    end
  end
end
