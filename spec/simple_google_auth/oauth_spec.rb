require 'spec_helper'

RSpec.describe SimpleGoogleAuth::OAuth do
  let(:config) do
    instance_double(
      SimpleGoogleAuth::Config,
      google_token_url: "/token/url",
      client_id: '12345',
      client_secret: 'abcde',
      redirect_uri: '/ok',
      open_timeout: 12,
      read_timeout: 13
    )
  end

  let(:client) { instance_double(SimpleGoogleAuth::HttpClient) }
  let(:response) { {"id_token" => "sometoken", "expires_in" => 1200, "other" => "data"} }
  let(:expires_at) { Time.now + 1200 - 5 }

  before do
    now = Time.now
    allow(Time).to receive(:now).and_return(now)

    expect(SimpleGoogleAuth::HttpClient).to receive(:new).with(config.google_token_url, open_timeout: 12, read_timeout: 13).and_return(client)
  end

  subject { SimpleGoogleAuth::OAuth.new(config) }

  describe "#exchange_code_for_auth_token!" do
    before do
      expect(client).to receive(:request).with(
        code: "magic",
        grant_type: "authorization_code",
        client_id: "12345",
        client_secret: "abcde",
        redirect_uri: "/ok"
      ).and_return(response)
    end

    it "returns a hash of auth token data" do
      expect(subject.exchange_code_for_auth_token!('magic')).to eq('expires_in' => 1200, 'other' => 'data', 'id_token' => 'sometoken', 'expires_at' => expires_at.to_s)
    end

    context "when the response is missing an id_token" do
      let(:response) { {"expires_in" => 1200} }

      it "raises an error" do
        expect { subject.exchange_code_for_auth_token!('magic') }.to raise_error(SimpleGoogleAuth::Error, /id_token/)
      end
    end

    context "when the response is missing an expires_in" do
      let(:response) { {"id_token" => "sometoken"} }

      it "raises an error" do
        expect { subject.exchange_code_for_auth_token!('magic') }.to raise_error(SimpleGoogleAuth::Error, /expires_in/)
      end
    end

    context "when expires_in is not a number" do
      let(:response) { {"id_token" => "sometoken", "expires_in" => "1200"} }

      it "raises an error" do
        expect { subject.exchange_code_for_auth_token!('magic') }.to raise_error(SimpleGoogleAuth::Error, /number greater than 0/)
      end
    end

    context "when expires_in is negative" do
      let(:response) { {"id_token" => "sometoken", "expires_in" => -60} }

      it "raises an error" do
        expect { subject.exchange_code_for_auth_token!('magic') }.to raise_error(SimpleGoogleAuth::Error, /number greater than 0/)
      end
    end
  end

  describe "#refresh_auth_token!" do
    context "when a refresh token is provided" do
      before do
        expect(client).to receive(:request).with(
          refresh_token: "magic",
          grant_type: "refresh_token",
          client_id: "12345",
          client_secret: "abcde",
        ).and_return(response)
      end

      it "returns a hash of auth token data, retaining the refresh token" do
        expect(subject.refresh_auth_token!('magic')).to eq('expires_in' => 1200, 'other' => 'data', 'id_token' => 'sometoken', 'expires_at' => expires_at.to_s, 'refresh_token' => 'magic')
      end

      context "and the response contains a new refresh token" do
        let(:response) { {"id_token" => "sometoken", "expires_in" => 1200, "refresh_token" => "newer"} }

        it "keeps the refresh token from the response" do
          expect(subject.refresh_auth_token!('magic')['refresh_token']).to eq 'newer'
        end
      end
    end

    context "when no refresh token is provided" do
      it "does nothing and returns nil" do
        expect(subject.refresh_auth_token!(nil)).to be nil
      end
    end

    context "when the refresh token is blank" do
      it "does nothing and returns nil" do
        expect(subject.refresh_auth_token!('')).to be nil
      end
    end
  end
end
