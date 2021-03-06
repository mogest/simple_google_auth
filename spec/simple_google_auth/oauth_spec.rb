require 'spec_helper'

describe SimpleGoogleAuth::OAuth do
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

      it "returns a hash of auth token data" do
        expect(subject.refresh_auth_token!('magic')).to eq('expires_in' => 1200, 'other' => 'data', 'id_token' => 'sometoken', 'expires_at' => expires_at.to_s, 'refresh_token' => 'magic')
      end
    end

    context "when no refresh token is provided" do
      it "does nothing and returns nil" do
        expect(subject.refresh_auth_token!(nil)).to be nil
      end
    end
  end
end
