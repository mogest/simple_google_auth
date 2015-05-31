require 'spec_helper'

describe SimpleGoogleAuth::AuthDataPresenter do
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
  end

  it "raises if id_token not provided" do
    expect {
      SimpleGoogleAuth::AuthDataPresenter.new({})
    }.to raise_error(SimpleGoogleAuth::AuthDataPresenter::InvalidAuthDataError)
  end
end
