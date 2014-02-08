Rails.application.routes.draw do
  get SimpleGoogleAuth.config.redirect_path || URI(SimpleGoogleAuth.config.redirect_uri).path, to: SimpleGoogleAuth::Receiver.new
end
