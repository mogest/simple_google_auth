require 'spec_helper'

RSpec.describe SimpleGoogleAuth::AuthDataPresenter do
  let(:id_data) do
    {
      "iss" => "accounts.google.com",
      "sub" => "10769150350006150715113082367",
      "email" => "test@test.example",
      "aud" => "1234987819200.apps.googleusercontent.com",
      "iat" => 1353601026,
      "exp" => 1353604926
    }
  end

  let(:id_token) { "12345." + Base64.urlsafe_encode64(id_data.to_json, padding: false) }
  let(:auth_data) do
    {
      "id_token" => id_token,
      "expires_in" => 1200,
      "access_token" => "abcdef",
      "token_type" => "Bearer"
    }
  end

  subject { SimpleGoogleAuth::AuthDataPresenter.new(auth_data) }

  it "provides indifferent hash access to data in the JWT" do
    expect(subject['email']).to eq 'test@test.example'
    expect(subject[:email]).to eq 'test@test.example'
  end

  it "provides method access to data in the JWT" do
    expect(subject.email).to eq 'test@test.example'
    expect(subject.sub).to eq '10769150350006150715113082367'
    expect(subject.iat).to eq 1353601026
  end

  it "provides method access to data outside the JWT" do
    expect(subject.access_token).to eq 'abcdef'
    expect(subject.token_type).to eq 'Bearer'
    expect(subject.expires_in).to eq 1200
  end

  it "prefers JWT claims over top-level auth data" do
    presenter = SimpleGoogleAuth::AuthDataPresenter.new(auth_data.merge("email" => "outer@test.example"))
    expect(presenter.email).to eq 'test@test.example'
  end

  it "decodes unpadded JWT payloads of any length" do
    %w(a ab abc abcd abcde).each do |email|
      token = "12345." + Base64.urlsafe_encode64({"email" => email}.to_json, padding: false)
      presenter = SimpleGoogleAuth::AuthDataPresenter.new("id_token" => token)
      expect(presenter.email).to eq email
    end
  end

  it "decodes payloads containing base64url-specific characters" do
    payload = {"name" => "a>b?c~", "email" => "test@test.example"}
    token = "12345." + Base64.urlsafe_encode64(payload.to_json, padding: false)
    expect(token).to match(/[-_]/)

    presenter = SimpleGoogleAuth::AuthDataPresenter.new("id_token" => token)
    expect(presenter.email).to eq "test@test.example"
  end

  it "raises if id_token not provided" do
    expect {
      SimpleGoogleAuth::AuthDataPresenter.new({})
    }.to raise_error(SimpleGoogleAuth::AuthDataPresenter::InvalidAuthDataError)
  end

  it "raises if the id_token has no payload segment" do
    expect {
      SimpleGoogleAuth::AuthDataPresenter.new("id_token" => "notajwt")
    }.to raise_error(SimpleGoogleAuth::AuthDataPresenter::InvalidAuthDataError)
  end

  it "raises if the id_token payload is not valid JSON" do
    expect {
      SimpleGoogleAuth::AuthDataPresenter.new("id_token" => "12345." + Base64.urlsafe_encode64("not json", padding: false))
    }.to raise_error(SimpleGoogleAuth::AuthDataPresenter::InvalidAuthDataError)
  end

  it "raises if the id_token payload is not valid base64url" do
    expect {
      SimpleGoogleAuth::AuthDataPresenter.new("id_token" => "12345.not!valid*base64")
    }.to raise_error(SimpleGoogleAuth::AuthDataPresenter::InvalidAuthDataError)
  end
end
