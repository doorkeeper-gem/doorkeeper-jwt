# frozen_string_literal: true

require "doorkeeper/jwt/version"
require "doorkeeper/jwt/errors"
require "doorkeeper/jwt/config"
require "jwt"

module Doorkeeper
  module JWT
    class << self
      def generate(opts = {})
        algorithm = signing_method(opts)

        ::JWT.encode(
          token_payload(opts),
          secret_key(opts, algorithm),
          algorithm,
          token_headers(opts)
        )
      end

      def signing_key_configured?
        use_application_secret? ||
          !Doorkeeper::JWT.configuration.secret_key.nil? ||
          !Doorkeeper::JWT.configuration.secret_key_path.nil?
      end

      private

      def token_payload(opts = {})
        Doorkeeper::JWT.configuration.token_payload.call(opts)
      end

      def token_headers(opts = {})
        Doorkeeper::JWT.configuration.token_headers.call(opts)
      end

      def secret_key(opts, algorithm)
        return application_secret(opts) if use_application_secret?

        case algorithm
        when /RS\d{3}/ then OpenSSL::PKey::RSA.new(asymmetric_key(opts))
        when /ES\d{3}/ then OpenSSL::PKey::EC.new(asymmetric_key(opts))
        else configured_secret_key(opts)
        end
      end

      # A configured key file wins over `secret_key`, which is only resolved
      # when no path is configured for this token.
      def asymmetric_key(opts)
        secret_key_file(opts) || configured_secret_key(opts)
      end

      def configured_secret_key(opts)
        resolve_option(Doorkeeper::JWT.configuration.secret_key, opts)
      end

      def secret_key_file(opts)
        path = resolve_option(Doorkeeper::JWT.configuration.secret_key_path, opts)
        File.read(path) if path
      end

      def signing_method(opts)
        method = resolve_option(Doorkeeper::JWT.configuration.signing_method, opts)
        return method.to_s.upcase unless method.nil?

        raise_missing_signing_method if signing_key_configured?

        warn_unsigned_token
        "none"
      end

      def raise_missing_signing_method
        raise(
          SigningMethodMissing,
          "JWT `signing_method` is not configured, but a signing key is." \
          " Refusing to issue an unsigned (alg: none) token. Set" \
          " `signing_method` explicitly, e.g. `signing_method :hs512`."
        )
      end

      def warn_unsigned_token
        Kernel.warn(
          "[DOORKEEPER-JWT]: No `signing_method` configured; issuing UNSIGNED" \
          " tokens (alg: none). This will become an error in a future release."
        )
      end

      # Options can be configured either with a static value or with a block
      # that receives the token generation options and returns the value.
      def resolve_option(value, opts)
        value.respond_to?(:call) ? value.call(opts) : value
      end

      def use_application_secret?
        Doorkeeper::JWT.configuration.use_application_secret
      end

      def application_secret(opts)
        opts = { application: {} }.merge(opts)

        if opts[:application].nil?
          raise(
            "JWT `use_application_secret` is enabled, but application is nil." \
            " This can happen if `client_id` was absent in the request params."
          )
        end

        secret = if opts[:application].respond_to?(:plaintext_secret)
                   unless opts[:application].secret_strategy.allows_restoring_secrets?
                     raise(
                       "JWT `use_application_secret` is enabled, but secret strategy " \
                       "doesn't allow plaintext secret restoring"
                     )
                   end
                   opts[:application].plaintext_secret
                 else
                   opts[:application][:secret]
                 end

        if secret.nil?
          raise(
            "JWT `use_application_secret` is enabled, but the application" \
            " secret is nil."
          )
        end

        secret
      end
    end
  end
end
