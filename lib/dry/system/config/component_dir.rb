require "dry/configurable"

module Dry
  module System
    module Config
      class ComponentDir
        include Dry::Configurable

        setting :auto_register, true
        setting :add_to_load_path, true

        # Maybe a clearer name for this?
        setting :default_namespace

        attr_reader :path

        def initialize(path)
          super()

          @path = path

          yield self if block_given?
        end

        # I am pretty unhappy with this. I think it indicates I should probably create a
        # new class for a RootedComponentDir or something
        def with_root(root)
          dup.tap do |dir|
            dir.instance_variable_set :@root, root
          end
        end

        def root
          raise "root not provided, use dir.with_root first" unless @root

          @root
        end

        def full_path
          root.join(path)
        end

        def component_file(component_path)
          # puts "component_file(#{component_path})"

          # TODO: make smarter?
          component_path = "#{component_path}.rb"

          if config.default_namespace
            # TODO: use constant for path separator
            # TODO: use constant for RB_EXT
            # TODO: use proper separators
            component_path = [config.default_namespace.gsub(".", "/"), component_path].join("/")
          end

          # p component_path

          full_component_path = full_path.join(component_path)

          full_component_path if full_component_path.exist?
        end

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
