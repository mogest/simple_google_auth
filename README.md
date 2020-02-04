# SimpleGoogleAuth

Want an extremely easy integration of Google's authentication system in your Rails site?

This is a dead simple gem that allows you to require a Google login for parts of your site.
You can allow any user with a Google account, or limit access to certain users based on their
Google e-mail address.

Being simple, it's limited in what it can do.  But if your goal is to put your site
behind a Google login instead of a crusty basic auth box, it'll do the trick.
If you're after more power, there are quite a few gems that'll do what you're looking for,
such as OmniAuth's Google strategy.

## Installation

Follow these four steps to integrate with your site.

Step 1: Make yourself a project at https://cloud.google.com/console, if you haven't already.  In that project, go to the "APIs & auth" tab, then the "Credentials" tab.  Create a new client ID of application type "Web application".  Set the Authorized Redirect URI to
`https://yoursite.com/google-callback`.  You might want to put in `http://localhost:3000/google-callback` so you can test locally too.

Step 2: Add simple_google_auth to your `Gemfile` and run `bundle`

    gem 'simple_google_auth'

Step 3: Add the following code to the bottom of your `config/application.rb` and tweak it with your site's values:

    SimpleGoogleAuth.configure do |config|
      config.client_id = "the client ID as supplied by Google in step 2"
      config.client_secret = "the client secret as supplied by Google in step 2"
      config.redirect_uri = "http://localhost:3000/google-callback"
      config.authenticate = lambda do |data|
        data.email == "your.email@example.com" || data.email.ends_with?("@example.net")
      end
    end

Step 4: In your `application_controller.rb`, add a before action:

    before_action :redirect_if_not_google_authenticated

Done!  Any request to your site will now redirect to Google for authentication.
A route that captures requests to `/google-callback` on your site is automatically created and handled for you.

If you log in with `your.email@example.com`, or any address in the `example.net` domain, it'll let you in to the site and take you to the page you were initially trying to go to.
Otherwise it'll redirect to `/` (by default) with `params[:message]` set to the authentication error.

## Setting up a production environment

You might want to put a different configure block in your development.rb and production.rb, each specifying
a different redirect URI.  Just pop them on the end of the file.  You can also have different client IDs and
secrets, or authentication criteria.

    # development.rb
    SimpleGoogleAuth.configure do |config|
      config.redirect_uri = "http://localhost:3000/google-callback"
    end

    # production.rb
    SimpleGoogleAuth.configure do |config|
      config.redirect_uri = "https://mysite.com/google-callback"
    end

## How do I tell who is logged in?

Call `#google_auth_data` from your controller or view and you'll get the authentication data that Google sends back.

    Welcome, <%= google_auth_data.email %>!

SimpleGoogleAuth exposes the following data via methods: access_token, expires_in, token_type, refresh_token, id_token, iss, at_hash, email_verified, sub, azp, email, aud, iat, exp, hd.  You can also use `google_auth_data` as a hash and get any additional fields not listed here.

Take a look at [the Google OAuth documentation](https://developers.google.com/accounts/docs/OAuth2Login#obtainuserinfo)
to see more information about what these fields mean.

## Refreshing tokens and offline mode

By default SimpleGoogleAuth doesn't check the expiry time
on the credentials after they've been loaded from Google the first time.
This is less hassle if all you want is simple authentication for your site,
but prevents you from using the credentials for other uses (eg. GCal integration)
because the oauth tokens will expire and Google won't accept them anymore.

If you want the tokens to be refreshed when they expire then you need to
add an extra line to your config. Doing so will ensure that your
Google auth tokens never get stale and allow you to use offline mode.

    SimpleGoogleAuth.configure do |config|
      config.refresh_stale_tokens = true
    end

Whenever the google_auth_data is requested in a controller it will first
be checked to make sure it's not stale. If it is stale the tokens will be
refreshed before being returned.

If your users have already allowed your site access to a certain set of scopes
Google won't re-issue you a refresh_token automatically. You'll need to set an
extra param in the request_parameters configuration hash to force Google to
send you the refresh token every time your users authenticate.

    SimpleGoogleAuth.configure do |config|
      config.refresh_stale_tokens = true
      config.request_parameters.merge!(approval_prompt: "force")
    end

For more details on offline mode and approval_prompt refer to the
[Google OAuth documentation](https://developers.google.com/accounts/docs/OAuth2WebServer).

## Configuring

There are a few configuration options that can be set using `SimpleGoogleAuth.configure` as in the example above.

Option | Default | Description
--- | --- | ---
client_id* | (required) | Client ID as provided by Google.
client_secret* | (required) | Client secret as provided by Google.
redirect_uri | (required) | Where Google should redirect to after authentication.
redirect_path | `nil` | A route is created at this path.  If no path is specified, the path is taken from redirect_uri.
authenticate | (required) | A lambda that's run to determine whether the user should be accepted as valid or not.  Takes one argument, a hash of identification data as provided by Google.  Should return true on success, or false if the login should not proceed.
failed_login_path | `"/"` | Where to redirect to upon a failed login.  `params[:message]` will be set with the error that occurred.
google_auth_url | `"https://accounts.google.com/o/oauth2/auth"` | Google's authentication URL.
google_token_url | `"https://accounts.google.com/o/oauth2/token"` | Google's token URL.
state_session_key_name | `"simple-google-auth.state"` | The name of the session variable used to store a random string used to prevent CSRF attacks during authentication.
data_session_key_name | `"simple-google-auth.data"` | The name of the session variable used to store identification data from Google.
request_parameters | `{scope: "openid email"}` | Parameters to use when requesting a login from Google
open_timeout | `15` | The maximum time, in seconds, to wait connecting to Google before giving up
read_timeout | `15` | The maximum time, in seconds, to wait for a response from Google before giving up
authentication_uri_state_builder | ->(request) { SecureRandom.hex + request.path } | The lambda used to create the state param for the oauth uri.
authentication_uri_state_path_extractor | ->(state) { state[32..-1] } | The lambda used to extract the request path from the state param.

Items marked with * may be a lambda, which will be called when that config item is required.

Note that when customising the oauth uri state param, you will need to configure both authentication_uri_state_builder and authentication_uri_state_path_extractor. The builder must include the request path when creating the state param, otherwise simple_google_auth will always redirect back to '/'. This feature can be used to encode other information into the state parameter.

## Licence

MIT.  Copyright 2014-2016 Roger Nesbitt, Powershop New Zealand Limited.
MIT.  Copyright 2020 Flux Federation Ltd

## Authors and contributors

 - Roger Nesbitt
 - Andy Newport
 - Flux Federation
