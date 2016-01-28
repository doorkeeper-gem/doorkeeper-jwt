require "doorkeeper-jwt/version"
require "doorkeeper-jwt/config"
require 'jwt'

module Doorkeeper
  module JWT
    def self.generate(opts = {})
      ::JWT.encode(
        token_payload(opts),
        secret_key(opts),
        encryption_method
      )
    end

  private

    def self.token_payload(opts = {})
      Doorkeeper::JWT.configuration.token_payload.call opts
    end

    def self.secret_key(opts)
      opts = { application: {} }.merge(opts)

      if Doorkeeper::JWT.configuration.use_application_secret
        return opts[:application][:secret] if opts[:application][:secret]

        fail "`use_application_secret` config set, but no app had no secret."
      end

      return secret_key_file if !secret_key_file.nil?
      return rsa_key if rsa_encryption?
      Doorkeeper::JWT.configuration.secret_key
    end

    def self.secret_key_file
      return nil if Doorkeeper::JWT.configuration.secret_key_path.nil?
      OpenSSL::PKey::RSA.new(
        File.open(Doorkeeper::JWT.configuration.secret_key_path)
      )
    end

    def self.encryption_method
      return nil unless Doorkeeper::JWT.configuration.encryption_method
      Doorkeeper::JWT.configuration.encryption_method.to_s.upcase
    end

    def self.rsa_encryption?
      /RS\d{3}/ =~ encryption_method
    end

    def self.rsa_key
      OpenSSL::PKey::RSA.new(Doorkeeper::JWT.configuration.secret_key)
    end
  end
end
