require "doorkeeper-jwt/version"
require "doorkeeper-jwt/config"
require 'jwt'

module Doorkeeper
  module JWT
    def self.generate
      ::JWT.encode(token_payload, secret_key, encryption_method)
    end

  private

    def self.token_payload
      instance_eval(&Doorkeeper::JWT.configuration.token_payload)
    end

    def self.secret_key
      Doorkeeper::JWT.configuration.secret_key
    end

    def self.encryption_method
      return nil unless Doorkeeper::JWT.configuration.encryption_method
      Doorkeeper::JWT.configuration.encryption_method.to_s.upcase
    end
  end
end
