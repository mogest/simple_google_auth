require 'spec_helper'

RSpec.describe SimpleGoogleAuth::HttpClient do
  let(:http) do
    instance_double(Net::HTTP, :open_timeout= => nil, :read_timeout= => nil, :use_ssl= => nil, :verify_mode= => nil)
  end

  describe "initialisation" do
    context "with an https URL" do
      it "enables SSL with peer verification" do
        expect(Net::HTTP).to receive(:new).with("some.host", 443).and_return(http)

        described_class.new("https://some.host/somepath")

        expect(http).to have_received(:use_ssl=).with(true)
        expect(http).to have_received(:verify_mode=).with(OpenSSL::SSL::VERIFY_PEER)
      end

      it "sets the supplied timeouts" do
        allow(Net::HTTP).to receive(:new).and_return(http)

        described_class.new("https://some.host/somepath", open_timeout: 12, read_timeout: 13)

        expect(http).to have_received(:open_timeout=).with(12)
        expect(http).to have_received(:read_timeout=).with(13)
      end

      it "defaults the timeouts to 15 seconds" do
        allow(Net::HTTP).to receive(:new).and_return(http)

        described_class.new("https://some.host/somepath")

        expect(http).to have_received(:open_timeout=).with(15)
        expect(http).to have_received(:read_timeout=).with(15)
      end
    end

    context "with an http URL" do
      it "does not enable SSL" do
        expect(Net::HTTP).to receive(:new).with("some.host", 80).and_return(http)

        described_class.new("http://some.host/somepath")

        expect(http).to_not have_received(:use_ssl=)
        expect(http).to_not have_received(:verify_mode=)
      end
    end
  end

  describe "#request" do
    subject(:client) { described_class.new("https://some.host/somepath") }

    let(:post) { instance_double(Net::HTTP::Post, set_form_data: nil) }

    before do
      allow(Net::HTTP).to receive(:new).and_return(http)
      allow(Net::HTTP::Post).to receive(:new).with("/somepath").and_return(post)
    end

    def stub_response(code:, body:, content_type:)
      response = instance_double(Net::HTTPResponse, code: code, body: body, content_type: content_type)
      allow(http).to receive(:request).with(post).and_return(response)
    end

    it "posts the form data and returns the parsed JSON response" do
      stub_response(code: '200', body: {"data" => "very"}.to_json, content_type: 'application/json')

      expect(client.request('some' => 'data')).to eq("data" => "very")
      expect(post).to have_received(:set_form_data).with('some' => 'data')
    end

    it "raises an error when non-JSON content is returned" do
      stub_response(code: '200', body: "some html", content_type: 'text/html')

      expect { client.request('some' => 'data') }.to raise_error(SimpleGoogleAuth::NonJsonResponseError, /non-JSON/)
    end

    it "raises an error when unparseable JSON is returned" do
      stub_response(code: '200', body: "some html", content_type: 'application/json')

      expect { client.request('some' => 'data') }.to raise_error(SimpleGoogleAuth::NonJsonResponseError, /parseable/)
    end

    it "raises an error when a non-2xx response is returned" do
      stub_response(code: '400', body: {"data" => "very"}.to_json, content_type: 'application/json')

      expect { client.request('some' => 'data') }.to raise_error(SimpleGoogleAuth::ProviderError, /400.+very/)
    end

    it "raises a ProviderError when the connection times out opening" do
      allow(http).to receive(:request).and_raise(Net::OpenTimeout)

      expect { client.request('some' => 'data') }.to raise_error(SimpleGoogleAuth::ProviderError, /Net::OpenTimeout/)
    end

    it "raises a ProviderError when the connection times out reading" do
      allow(http).to receive(:request).and_raise(Net::ReadTimeout)

      expect { client.request('some' => 'data') }.to raise_error(SimpleGoogleAuth::ProviderError, /Net::ReadTimeout/)
    end
  end
end
