require "doorkeeper-jwt/version"
require "doorkeeper-jwt/config"
require 'jwt'

module Doorkeeper
  module JWT
    class << self
      def generate(opts = {})
        ::JWT.encode(
          token_payload(opts),
          secret_key(opts),
          encryption_method,
          token_headers(opts)
        )
      end

      private

      def token_payload(opts = {})
        Doorkeeper::JWT.configuration.token_payload.call opts
      end

      def token_headers(opts = {})
        Doorkeeper::JWT.configuration.token_headers.call opts
      end

      def secret_key(opts)
        opts = { application: {} }.merge(opts)

        return application_secret(opts) if use_application_secret?
        return secret_key_file unless secret_key_file.nil?
        return rsa_key if rsa_encryption?
        return ecdsa_key if ecdsa_encryption?
        Doorkeeper::JWT.configuration.secret_key
      end

      def secret_key_file
        return nil if Doorkeeper::JWT.configuration.secret_key_path.nil?
        return rsa_key_file if rsa_encryption?
        return ecdsa_key_file if ecdsa_encryption?
      end

      def encryption_method
        return "none" unless Doorkeeper::JWT.configuration.encryption_method
        Doorkeeper::JWT.configuration.encryption_method.to_s.upcase
      end

      def use_application_secret?
        Doorkeeper::JWT.configuration.use_application_secret
      end

      def application_secret(opts)
        if opts[:application].nil?
          fail "JWT `use_application_secret` is enabled but application is " \
            "nil. This can happen if `client_id` was absent in the request " \
            "params."
        end

        if opts[:application][:secret].nil?
          fail "JWT `use_application_secret` is enabled but the application " \
            "secret is nil."
        end

        opts[:application][:secret]
      end

      def rsa_encryption?
        /RS\d{3}/ =~ encryption_method
      end

      def ecdsa_encryption?
        /ES\d{3}/ =~ encryption_method
      end

      def rsa_key
        OpenSSL::PKey::RSA.new(Doorkeeper::JWT.configuration.secret_key)
      end

      def ecdsa_key
        OpenSSL::PKey::EC.new(Doorkeeper::JWT.configuration.secret_key)
      end

      def rsa_key_file
        secret_key_file_open { |f| OpenSSL::PKey::RSA.new(f) }
      end

      def ecdsa_key_file
        secret_key_file_open { |f| OpenSSL::PKey::EC.new(f) }
      end

      def secret_key_file_open(&block)
        File.open(Doorkeeper::JWT.configuration.secret_key_path, &block)
      end
    end
  end
end
