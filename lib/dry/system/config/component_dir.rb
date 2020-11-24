# require "dry/initializer"
require "dry/configurable"

module Dry
  module System
    module Config
      class ComponentDir
        # extend Dry::Initializer

        # param :path

        # option :auto_register, default: proc { true }

        # option :add_to_load_path, default: proc { true }

        # option :default_namespace


        include Dry::Configurable

        # TODO: raise if not provided?
        setting :path

        setting :auto_register, true

        setting :add_to_load_path, true

        private

        def method_missing(name, *args, &block)
          if config.respond_to?(name)
            config.public_send(name, *args, &block)
          else
            super
          end
        end

        def respond_to_missing?(name, include_private = false)
          config.respond_to?(name, include_private) || super
        end
      end
    end
  end
end
