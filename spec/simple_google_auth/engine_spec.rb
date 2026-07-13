require 'spec_helper'

RSpec.describe SimpleGoogleAuth::Engine do
  it "includes the controller module into ActionController::Base and exposes the helper" do
    initializer = described_class.initializers.find { |i| i.name == "simple_google_auth.load_helpers" }
    initializer.run(nil)

    expect(ActionController::Base.include?(SimpleGoogleAuth::Controller)).to be true
    expect(ActionController::Base._helper_methods).to include(:google_auth_data)
  end
end
