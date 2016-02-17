module Doorkeeper
  module JWT
    class MissingConfiguration < StandardError
      def initialize
        super('Configuration for doorkeeper-jwt missing.')
      end
    end

    def self.configure(&block)
      @config = Config::Builder.new(&block).build
    end

    def self.configuration
      @config || (fail MissingConfiguration.new)
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

        def use_application_secret(use_application_secret)
          @config.instance_variable_set(
            "@use_application_secret",
            use_application_secret
          )
        end

        def secret_key(secret_key)
          @config.instance_variable_set('@secret_key', secret_key)
        end

        def secret_key_path(secret_key_path)
          @config.instance_variable_set('@secret_key_path', secret_key_path)
        end

        def encryption_method(encryption_method)
          @config.instance_variable_set(
            '@encryption_method', encryption_method)
        end
      end

      module Option
        # Defines configuration option
        #
        # When you call option, it defines two methods. One method will take place
        # in the +Config+ class and the other method will take place in the
        # +Builder+ class.
        #
        # The +name+ parameter will set both builder method and config attribute.
        # If the +:as+ option is defined, the builder method will be the specified
        # option while the config attribute will be the +name+ parameter.
        #
        # If you want to introduce another level of config DSL you can
        # define +builder_class+ parameter.
        # Builder should take a block as the initializer parameter and respond to function +build+
        # that returns the value of the config attribute.
        #
        # ==== Options
        #
        # * [:+as+] Set the builder method that goes inside +configure+ block
        # * [+:default+] The default value in case no option was set
        #
        # ==== Examples
        #
        #    option :name
        #    option :name, as: :set_name
        #    option :name, default: 'My Name'
        #    option :scopes builder_class: ScopesBuilder
        #
        def option(name, options = {})
          attribute = options[:as] || name
          attribute_builder = options[:builder_class]

          Builder.instance_eval do
            define_method name do |*args, &block|
              # TODO: is builder_class option being used?
              value = unless attribute_builder
                        block ? block : args.first
                      else
                        attribute_builder.new(&block).build
                      end

              @config.instance_variable_set(:"@#{attribute}", value)
            end
          end

          define_method attribute do |*args|
            if instance_variable_defined?(:"@#{attribute}")
              instance_variable_get(:"@#{attribute}")
            else
              options[:default]
            end
          end

          public attribute
        end

        def extended(base)
          base.send(:private, :option)
        end
      end

      extend Option

      option :token_payload,
        default: proc{ { token: SecureRandom.method(:hex) } }
      option :use_application_secret, default: false
      option :secret_key, default: nil
      option :secret_key_path, default: nil
      option :encryption_method, default: nil

      def use_application_secret
        @use_application_secret ||= false
      end

      def secret_key
        @secret_key ||= nil
      end

      def secret_key_path
        @secret_key_path ||= nil
      end

      def encryption_method
        @encryption_method ||= nil
      end
    end
  end
end
