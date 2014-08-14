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

Follow these five steps to integrate with your site.

Step 1: Make yourself a project at https://cloud.google.com/console, if you haven't already.

Step 2: In that project, go to the "APIs & auth" tab, then the "Credentials" tab.  Create a new client ID of application type "Web application".  Set the Authorized Redirect URI to
`http://yoursite.com/google-callback`.  You might want to put in `http://localhost:3000/google-callback` so you can test locally too.

Step 3: Add simple_google_auth to your Gemfile

    gem 'simple_google_auth'

Step 4: In your application.rb, put down some code inside the Application class:

    SimpleGoogleAuth.configure do |config|
      config.client_id = "the client ID as supplied by Google in step 2"
      config.client_secret = "the client secret as supplied by Google in step 2"
      config.redirect_uri = "http://localhost:3000/google-callback"
      config.authenticate = lambda do |data|
        data["email"] == "your.email@example.com"
      end
    end

Step 5: In your application_controller.rb, add a before filter:

    before_filter :redirect_if_not_google_authenticated

Done!  Any request to your site will now redirect off to Google for authentication.
A route that captures requests coming in to /google-callback is automatically created and handled for you.

If you log in with `your.email@example.com`, it'll let you in to the site and take you to the page you were initially trying to go to.
Otherwise it'll redirect to `/` (by default) with `params[:message]` set to the authentication error.

## Setting up multiple environments

You might want to put a different configure block in your development.rb and production.rb, each specifying
a different redirect URI.  Just pop them on the end of the file.

    # development.rb
    SimpleGoogleAuth.configure do |config|
      config.redirect_uri = "http://localhost:3000/google-callback"
    end

    # production.rb
    SimpleGoogleAuth.configure do |config|
      config.redirect_uri = "https://mysite.com/google-callback"
    end


## How do I tell who is logged in?

Call `#google_auth_data` from your controller or view and you'll get the identification hash that Google sends back.

    Welcome, <%= google_auth_data["email"] %>!

Take a look at https://developers.google.com/accounts/docs/OAuth2Login#obtainuserinfo to find out more about the fields in the hash.

## Configuring

There are a few configuration options that can be set using `SimpleGoogleAuth.configure` as in the example above.

Option | Default | Description
--- | --- | ---
client_id | (required) | Client ID as provided by Google.
client_secret | (required) | Client secret as provided by Google.
redirect_uri | (required) | Where Google should redirect to after authentication.
redirect_path | `nil` | A route is created at this path.  If no path is specified, the path is taken from redirect_uri.
authenticate | (required) | A lambda that's run to determine whether the user should be accepted as valid or not.  Takes one argument, a hash of identification data as provided by Google.  Should return true on success, or false if the login should not proceed.
failed_login_path | `"/"` | Where to redirect to upon a failed login.  `params[:message]` will be set with the error that occurred.
ca_path | `"/etc/ssl/certs"` | A path or file of SSL certificates, used to check that we're really talking to the Google servers.
google_auth_url | `"https://accounts.google.com/o/oauth2/auth"` | Google's authentication URL.
google_token_url | `"https://accounts.google.com/o/oauth2/token"` | Google's token URL.
state_session_key_name | `"simple-google-auth.state"` | The name of the session variable used to store a random string used to prevent CSRF attacks during authentication.
data_session_key_name | `"simple-google-auth.data"` | The name of the session variable used to store identification data from Google.
request_parameters | {scope: "openid email"} | Parameters to use when requesting a login from Google

## Licence

MIT.
