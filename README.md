[![Gem Version](https://badge.fury.io/rb/doorkeeper-jwt.svg)](https://rubygems.org/gems/doorkeeper-jwt)
[![Coverage Status](https://coveralls.io/repos/github/doorkeeper-gem/doorkeeper-jwt/badge.svg?branch=master)](https://coveralls.io/github/doorkeeper-gem/doorkeeper-jwt?branch=master)
[![CI](https://github.com/doorkeeper-gem/doorkeeper-jwt/actions/workflows/ci.yml/badge.svg?branch=master)](https://github.com/doorkeeper-gem/doorkeeper-jwt/actions/workflows/ci.yml)
[![Maintainability](https://qlty.sh/gh/doorkeeper-gem/projects/doorkeeper-jwt/maintainability.svg)](https://qlty.sh/gh/doorkeeper-gem/projects/doorkeeper-jwt)

# Doorkeeper::JWT

Doorkeeper JWT adds JWT token support to the Doorkeeper OAuth library.

## Compatibility

Requires Doorkeeper 5.4 or newer. Doorkeeper 5.0 and earlier cannot load this gem at all, because they ship no
`doorkeeper/config/option`. Doorkeeper 5.1 - 5.3 load it but misconfigure it: their options DSL defines the
methods on Doorkeeper's own config builder instead of this gem's.

The minimum supported version and the latest release run on every CI build - see the `doorkeeper` axis of the matrix
in [`.github/workflows/ci.yml`](.github/workflows/ci.yml). To check a version that is not covered there, point the
test suite at it:

```console
$ DOORKEEPER_VERSION=5.6.0 bundle install
$ DOORKEEPER_VERSION=5.6.0 bundle exec rake test
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

    payload = {
      iss: 'My App',
      iat: opts[:created_at].utc.to_i,
      aud: opts[:application][:uid],

      # @see JWT reserved claims - https://tools.ietf.org/html/draft-jones-json-web-token-07#page-7
      jti: SecureRandom.uuid,
      sub: user.id,

      user: {
        id: user.id,
        email: user.email
      }
    }

    payload[:exp] = (opts[:created_at] + opts[:expires_in]).utc.to_i if opts[:expires_in]
    payload
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

  # Set the signing secret. This would be shared with any other applications
  # that should be able to verify the authenticity of the token. Defaults to "secret".
  secret_key ENV['JWT_SECRET']

  # If you want to use RS* algorithms specify the path to the RSA key to use for
  # signing. If you specify a `secret_key_path` it will be used instead of
  # `secret_key`.
  secret_key_path File.join('path', 'to', 'file.pem')

  # Specify cryptographic signing algorithm type (https://github.com/progrium/ruby-jwt). Defaults to
  # `nil`.
  signing_method :hs512
end
```

### Authenticating more than one model

`opts[:resource_owner_id]` alone does not tell the payload block which model the token belongs to, so an application
with several resource owner models (say, `Driver` and `Client`) cannot look the owner up from the id.

Doorkeeper 5.4 and newer can hand the owner record itself to the generator. Run the generator, which enables
`use_polymorphic_resource_owner` in the `Doorkeeper.configure` block and creates the migration that adds the
`resource_owner_type` columns, then apply the migration:

    $ rails generate doorkeeper:enable_polymorphic_resource_owner
    $ rails db:migrate

The payload block then receives the record as `opts[:resource_owner]`, so the payload can branch on its class:

```ruby
Doorkeeper::JWT.configure do
  token_payload do |opts|
    owner = opts[:resource_owner]

    # client credentials tokens have no resource owner
    next { sub: opts[:application]&.uid } unless owner

    # ids are only unique per model, so include the model name in `sub`
    {
      sub: "#{owner.class.name.underscore}:#{owner.id}",
      owner_type: owner.class.name,
      email: owner.email
    }
  end
end
```

Tokens issued by the client credentials flow have no resource owner, so `opts[:resource_owner]` is `nil` there.

### Using more than one signing method

`signing_method`, `secret_key` and `secret_key_path` also accept a block. The block receives the same
options hash as `token_payload` (`resource_owner_id`, `application`, `scopes`, ...) and is evaluated
whenever the option is needed for the token being generated, so you can pick the algorithm and the key
per request — for example an RSA-signed token for clients with an `admin` scope and an HMAC-signed token
for everyone else:

```ruby
Doorkeeper::JWT.configure do
  signing_method do |opts|
    opts[:scopes].exists?('admin') ? :rs512 : :hs256
  end

  secret_key do |opts|
    opts[:scopes].exists?('admin') ? ENV['JWT_RSA_PRIVATE_KEY'] : ENV['JWT_HMAC_SECRET']
  end
end
```

Doorkeeper hands `opts[:scopes]` over as a `Doorkeeper::OAuth::Scopes`, so match a single scope with
`exists?` rather than with a substring check: `opts[:scopes].to_s.include?('admin')` would also be true for
an unrelated `superadmin` or `admin_readonly` scope, and picking a signing key that way is easy to get wrong.

The blocks are independent of each other, so make sure `secret_key` (or `secret_key_path`) returns a key that
matches the algorithm returned by `signing_method` for the same options.

Note that the key options are only resolved when they are actually used: `secret_key_path` is read for
`RS*` and `ES*` algorithms only, and both `secret_key` and `secret_key_path` are skipped entirely when
`use_application_secret` is enabled. When a path is configured for an asymmetric algorithm it takes
precedence, and the `secret_key` block is not evaluated at all.

Whoever verifies these tokens now has more than one key to choose from, so tell them which one was used:
`token_headers` receives the same options hash and is evaluated per token as well, which lets you emit a
matching `kid` header.

```ruby
Doorkeeper::JWT.configure do
  token_headers do |opts|
    { kid: opts[:scopes].exists?('admin') ? 'rsa-2026' : 'hmac-2026' }
  end
end
```

See the `token_headers` entry in the configuration above for deriving the `kid` of an `RS*` key with
`JWT::JWK` instead of labelling it by hand.

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
