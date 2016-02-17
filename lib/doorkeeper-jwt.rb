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
          encryption_method
        )
      end

      private

      def token_payload(opts = {})
        Doorkeeper::JWT.configuration.token_payload.call opts
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
        return nil unless Doorkeeper::JWT.configuration.encryption_method
        Doorkeeper::JWT.configuration.encryption_method.to_s.upcase
      end

      def use_application_secret?
        return false unless Doorkeeper::JWT.configuration.use_application_secret
      end

      def application_secret(opts)
        opts = { application: {} }.merge(opts)
        return opts[:application][:secret] if opts[:application][:secret]
        fail "JWT `use_application_secret` config set, but no app secret set."
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
        OpenSSL::PKey::RSA.new(secret_key_file_open)
      end

      def ecdsa_key_file
        OpenSSL::PKey::EC.new(secret_key_file_open)
      end

      def secret_key_file_open
        File.open(Doorkeeper::JWT.configuration.secret_key_path)
      end
    end
  end
end
