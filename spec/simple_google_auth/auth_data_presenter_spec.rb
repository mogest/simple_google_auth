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

  let(:id_token) { "12345." + Base64.encode64(id_data.to_json).gsub('=', '') }
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

  it "decodes JWT payloads of any length, re-adding base64 padding" do
    %w(a ab abc abcd abcde).each do |email|
      token = "12345." + Base64.strict_encode64({"email" => email}.to_json).delete("=")
      presenter = SimpleGoogleAuth::AuthDataPresenter.new("id_token" => token)
      expect(presenter.email).to eq email
    end
  end

  it "raises if id_token not provided" do
    expect {
      SimpleGoogleAuth::AuthDataPresenter.new({})
    }.to raise_error(SimpleGoogleAuth::AuthDataPresenter::InvalidAuthDataError)
  end
end
