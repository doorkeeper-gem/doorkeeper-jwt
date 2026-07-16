# frozen_string_literal: true

require "doorkeeper/config/option"

module Doorkeeper
  module JWT
    class MissingConfiguration < StandardError
      def initialize
        super("Configuration for doorkeeper-jwt missing.")
      end
    end

    def self.configure(&block)
      @config = Config::Builder.new(&block).build
    end

    def self.configuration
      @config || raise(MissingConfiguration)
    end

    class Config
      class Builder
        def initialize(&block)
          @config = Config.new
          instance_eval(&block)
        end

        def build
          @config
        end

        def use_application_secret(value)
          @config.instance_variable_set("@use_application_secret", value)
        end

        def secret_key(value)
          @config.instance_variable_set("@secret_key", value)
        end

        def secret_key_path(value)
          @config.instance_variable_set("@secret_key_path", value)
        end

        # For backward compatibility. This library does not support encryption.
        def encryption_method(value)
          @config.instance_variable_set("@signing_method", value)
          Kernel.warn("[DOORKEEPER-JWT]: Please use signing_method instead, this option is deprecated and will be removed soon")
        end

        def signing_method(value)
          @config.instance_variable_set("@signing_method", value)
        end
      end

      mattr_reader(:builder_class) { Config::Builder }
      extend ::Doorkeeper::Config::Option

      option(
        :token_payload,
        default: proc { { token: SecureRandom.hex } },
      )

      option :token_headers, default: proc { {} }
      option :use_application_secret, default: false
      option :secret_key, default: nil
      option :secret_key_path, default: nil
      option :signing_method, default: nil

      def use_application_secret
        @use_application_secret ||= false
      end

      def secret_key
        @secret_key ||= nil
      end

      def secret_key_path
        @secret_key_path ||= nil
      end

      def signing_method
        @signing_method ||= nil
      end
    end
  end
end
