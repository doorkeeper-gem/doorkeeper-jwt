require "doorkeeper-jwt/version"
require "doorkeeper-jwt/config"
require 'jwt'

module Doorkeeper
  module JWT
    def self.generate(resource_owner_id)
      ::JWT.encode(
        token_payload(resource_owner_id),
        secret_key,
        encryption_method
      )
    end

  private

    def self.token_payload(resource_owner_id)
      Doorkeeper::JWT.configuration.token_payload.call resource_owner_id
    end

    def self.secret_key
      secret_key_file || Doorkeeper::JWT.configuration.secret_key
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
  end
end
