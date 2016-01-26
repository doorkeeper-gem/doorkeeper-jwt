[![Coverage Status](https://coveralls.io/repos/chriswarren/doorkeeper-jwt/badge.svg?branch=master)](https://coveralls.io/r/chriswarren/doorkeeper-jwt?branch=master)
[![Build Status](https://travis-ci.org/chriswarren/doorkeeper-jwt.svg?branch=master)](https://travis-ci.org/chriswarren/doorkeeper-jwt)
[![Code Climate](https://codeclimate.com/github/chriswarren/doorkeeper-jwt/badges/gpa.svg)](https://codeclimate.com/github/chriswarren/doorkeeper-jwt)

# Doorkeeper::JWT

Doorkeeper JWT adds JWT token support to the Doorkeeper OAuth library. Requires Doorkeeper 2.2.0 or newer. Until it is released (expected mid-April, 2015), you can load the necessary commit that addis custom token support in your gemfile.

```ruby
gem 'doorkeeper', git: "git://github.com/doorkeeper/doorkeeper-gem", ref: '910112'
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
access_token_generator "Doorkeeper::JWT"
```

Then add a `Doorkeeper::JWT.configure` block below the `Doorkeeper.configure` block to set your JWT preferences.

```ruby
Doorkeeper::JWT.configure do
  # Set the payload for the JWT token. This should contain unique information
  # about the user.
  # Defaults to a randomly generated token in a hash
  # { token: "RANDOM-TOKEN" }
  token_payload do |opts|
    user = User.find(opts[:resource_owner_id])

    {
      user: {
        id: user.id,
        email: user.email
      }
    }
  end

  # Use the application secret specified in the Access Grant token
  # Defaults to false
  # If you specify `use_application_secret true`, both secret_key and secret_key_path will be ignored
  use_application_secret false

  # Set the encryption secret. This would be shared with any other applications
  # that should be able to read the payload of the token.
  # Defaults to "secret"
  secret_key "MY-SECRET"

  # If you want to use RS* encoding specify the path to the RSA key
  # to use for signing.
  # If you specify a secret_key_path it will be used instead of secret_key
  secret_key_path "path/to/file.pem"

  # Specify encryption type. Supports any algorithim in
  # https://github.com/progrium/ruby-jwt
  # defaults to nil
  encryption_method :hs512
end
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release` to create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

1. Fork it ( https://github.com/[my-github-username]/doorkeeper-jwt/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
