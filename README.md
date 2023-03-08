[![Gem Version](https://badge.fury.io/rb/doorkeeper-jwt.svg)](https://rubygems.org/gems/doorkeeper-jwt)
[![Coverage Status](https://coveralls.io/repos/github/doorkeeper-gem/doorkeeper-jwt/badge.svg?branch=master)](https://coveralls.io/github/doorkeeper-gem/doorkeeper-jwt?branch=master)
[![Build Status](https://travis-ci.org/doorkeeper-gem/doorkeeper-jwt.svg?branch=master)](https://travis-ci.org/doorkeeper-gem/doorkeeper-jwt)
[![Maintainability](https://api.codeclimate.com/v1/badges/ca4d81b49acabda27e0c/maintainability)](https://codeclimate.com/github/doorkeeper-gem/doorkeeper-jwt/maintainability)

# Doorkeeper::JWT

Doorkeeper JWT adds JWT token support to the Doorkeeper OAuth library. Confirmed to work with Doorkeeper 2.2.x - 4.x.
Untested with later versions of Doorkeeper.

```ruby
gem 'doorkeeper'
```

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'doorkeeper-jwt'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install doorkeeper-jwt

## Usage

In your `doorkeeper.rb` initializer add the follow to the `Doorkeeper.configure` block:

```ruby
access_token_generator '::Doorkeeper::JWT'
```

Then add a `Doorkeeper::JWT.configure` block below the `Doorkeeper.configure` block to set your JWT preferences.

```ruby
Doorkeeper::JWT.configure do
  # Set the payload for the JWT token. This should contain unique information
  # about the user. Defaults to a randomly generated token in a hash:
  #     { token: "RANDOM-TOKEN" }
  token_payload do |opts|
    user = User.find(opts[:resource_owner_id])

    {
      iss: 'My App',
      iat: Time.current.utc.to_i,
      aud: opts[:application][:uid],

      # @see JWT reserved claims - https://tools.ietf.org/html/draft-jones-json-web-token-07#page-7
      jti: SecureRandom.uuid,
      sub: user.id,

      user: {
        id: user.id,
        email: user.email
      }
    }
  end

  # Optionally set additional headers for the JWT. See
  # https://tools.ietf.org/html/rfc7515#section-4.1
  # JWK can be used to automatically verify RS* tokens client-side if token's kid matches a public kid in /oauth/discovery/keys
  # token_headers do |_opts|
  #   key = OpenSSL::PKey::RSA.new(File.read(File.join('path', 'to', 'file.pem')))
  #   { kid: JWT::JWK.new(key)[:kid] }
  # end

  # Use the application secret specified in the access grant token. Defaults to
  # `false`. If you specify `use_application_secret true`, both `secret_key` and
  # `secret_key_path` will be ignored.
  use_application_secret false

  # Set the encryption secret. This would be shared with any other applications
  # that should be able to read the payload of the token. Defaults to "secret".
  secret_key ENV['JWT_SECRET']

  # If you want to use RS* encoding specify the path to the RSA key to use for
  # signing. If you specify a `secret_key_path` it will be used instead of
  # `secret_key`.
  secret_key_path File.join('path', 'to', 'file.pem')

  # Specify encryption type (https://github.com/progrium/ruby-jwt). Defaults to
  # `nil`.
  encryption_method :hs512
end
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `bin/console` for an interactive prompt
that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the
version number in `version.rb`, and then run `bundle exec rake release` to create a git tag for the version, push git
commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

1. Fork it (https://github.com/[my-github-username]/doorkeeper-jwt/fork)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
