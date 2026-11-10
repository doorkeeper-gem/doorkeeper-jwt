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

**Important:** a payload that is anything but trivial makes the generated JWT longer than 255 characters. Doorkeeper's
migration creates the `token` column of `oauth_access_tokens` as a `string`, which some databases (MySQL among them)
store as `VARCHAR(255)`, so a token that does not fit is rejected or truncated and `doorkeeper_authorize!` answers every
request with `401 Unauthorized`. See [Using with `doorkeeper_authorize!`](#using-with-doorkeeper_authorize) below for
how to size the column before issuing tokens.

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

### Using with `doorkeeper_authorize!`

`doorkeeper_authorize!` never looks inside the JWT. Doorkeeper stores every token it issues as a
`Doorkeeper::AccessToken` record, whichever generator produced it, and the `before_action` finds that record by the
bearer token sent with the request and then checks its expiry, revocation and scopes. A JWT generated by this gem
therefore works with `doorkeeper_authorize!` out of the box; nothing has to be configured beyond
`access_token_generator`.

```ruby
class Api::V1::ProfilesController < ApplicationController
  before_action :doorkeeper_authorize!

  def show
    render json: User.find(doorkeeper_token.resource_owner_id)
  end
end
```

The one thing to watch is the size of the `token` column: the lookup compares the stored value with the one the client
presents, so the token has to be stored in full. Doorkeeper's migration creates the column as `t.string`, which MySQL
maps to `VARCHAR(255)` (PostgreSQL applies no limit). A JWT with a non-trivial payload is easily longer than that, and
depending on the database and its strict mode the insert then either fails or silently truncates the token. A truncated
token never matches the one presented by the client, `Doorkeeper::AccessToken.by_token` returns `nil` and every request
is answered with `401 Unauthorized`. There are two ways around this:

* Change the column to `text`, as the comment in Doorkeeper's migration template suggests. MySQL cannot index a `text`
  column without a prefix length, so the unique index on `token` has to be dropped before the column is changed and
  recreated with a `length` afterwards. Recreate it without `unique: true`: a unique index over a prefix rejects two
  different JWTs that merely start with the same characters, which they do whenever they share the header and the
  leading claims. Doorkeeper's own uniqueness validation on `token` stays in place. If you would rather keep the
  database-level constraint, prefer the second option.

  ```ruby
  class ChangeOauthAccessTokensTokenToText < ActiveRecord::Migration[7.1]
    def up
      remove_index :oauth_access_tokens, :token
      change_column :oauth_access_tokens, :token, :text, null: false
      add_index :oauth_access_tokens, :token, length: 255
    end

    def down
      remove_index :oauth_access_tokens, :token
      change_column :oauth_access_tokens, :token, :string, null: false
      add_index :oauth_access_tokens, :token, unique: true
    end
  end
  ```

* Enable `hash_token_secrets` in the `Doorkeeper.configure` block. Doorkeeper then stores a SHA-256 digest of the token
  (64 characters) instead of the token itself, which fits any column size. This disables `reuse_access_token` and,
  unless you pass `fallback: :plain`, invalidates tokens that are already in the database.

Also leave `doorkeeper_token` alone: it has to keep returning the `Doorkeeper::AccessToken` record. Overriding it in a
controller to return the raw or decoded JWT instead breaks `doorkeeper_authorize!`, which calls `acceptable?` on
whatever `doorkeeper_token` returns and fails with a `NoMethodError` for a `String` or a `Hash`. If you need the claims
in a controller, decode the JWT separately once `doorkeeper_authorize!` has accepted the request. Take it from the
request rather than from `doorkeeper_token.token`, which holds the digest instead of the JWT when `hash_token_secrets`
is enabled:

```ruby
jwt = Doorkeeper::OAuth::Token.from_request(request, *Doorkeeper.config.access_token_methods)
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
