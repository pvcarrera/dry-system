# frozen_string_literal: true

require "dry/system/components/bootable"
require "dry/system/errors"
require "dry/system/constants"
require "dry/system/lifecycle"
require "dry/system/booter/component_registry"
require "pathname"

module Dry
  module System
    # Default booter implementation
    #
    # This is currently configured by default for every System::Container.
    # Booter objects are responsible for loading system/boot files and expose
    # an API for calling lifecycle triggers.
    #
    # @api private
    class Booter
      attr_reader :paths

      attr_reader :booted

      attr_reader :components

      # @api private
      def initialize(paths)
        @paths = paths
        @booted = []
        @components = ComponentRegistry.new
      end

      # @api private
      def bootable?(component)
        !boot_file(component).nil?
      end

      # @api private
      def register_component(component)
        components.register(component)
        self
      end

      # WIP (and ugh, it's a bit gross atm)
      def find_component(identifier)
        # with_component(identifier) do |component|
        #   return component
        # end

        # Yep, total hack, FIXME later
        return nil if identifier.is_a?(String)

        require_boot_file(identifier) unless components.exists?(identifier)
        components[identifier] if components.exists?(identifier)
      end

      # @api private
      def finalize!
        boot_files.each do |path|
          load_component(path)
        end

        components.each do |component|
          start(component)
        end

        freeze
      end

      # @api private
      def shutdown
        components.each do |component|
          next unless booted.include?(component)

          stop(component)
        end
      end

      # @api private
      def init(name_or_component)
        with_component(name_or_component) do |component|
          call(component) do
            component.init.finalize
            yield if block_given?
          end

          self
        end
      end

      # @api private
      def start(name_or_component)
        with_component(name_or_component) do |component|
          return self if booted.include?(component)

          init(name_or_component) do
            component.start
          end

          booted << component.finalize

          self
        end
      end

      # @api private
      def stop(name_or_component)
        call(name_or_component) do |component|
          raise ComponentNotStartedError, name_or_component unless booted.include?(component)

          component.stop
          booted.delete(component)

          yield if block_given?
        end
      end

      # @api private
      def call(name_or_component)
        with_component(name_or_component) do |component|
          raise ComponentFileMismatchError, name unless component

          yield(component) if block_given?

          component
        end
      end

      # @api private
      def boot_dependency(component)
        boot_file = boot_file(component)

        start(boot_file.basename(".*").to_s.to_sym) if boot_file
      end

      # @api private
      def boot_files
        @boot_files ||= paths.each_with_object([[], []]) { |path, (boot_files, loaded)|
          files = Dir["#{path}/#{RB_GLOB}"].sort

          files.each do |file|
            basename = File.basename(file)

            unless loaded.include?(basename)
              boot_files << Pathname(file)
              loaded << basename
            end
          end
        }.first
      end

      private

      def with_component(id_or_component)
        component =
          case id_or_component
          when Symbol
            require_boot_file(id_or_component) unless components.exists?(id_or_component)
            components[id_or_component]
          when Components::Bootable
            id_or_component
          end

        raise InvalidComponentError, id_or_component unless component

        yield(component)
      end

      def load_component(path)
        identifier = Pathname(path).basename(RB_EXT).to_s.to_sym

        Kernel.require path unless components.exists?(identifier)

        self
      end

      def boot_file(name)
        name = name.respond_to?(:root_key) ? name.root_key.to_s : name

        find_boot_file(name)
      end

      def require_boot_file(identifier)
        boot_file = find_boot_file(identifier)

        Kernel.require boot_file if boot_file
      end

      def find_boot_file(name)
        boot_files.detect { |file| File.basename(file, RB_EXT) == name.to_s }
      end
    end
  end
end
