# frozen_string_literal: true

require "dry/system/constants"
require "dry/system/magic_comments_parser"
require "dry/system/auto_registrar/configuration"

module Dry
  module System
    # Default auto-registration implementation
    #
    # This is currently configured by default for every System::Container.
    # Auto-registrar objects are responsible for loading files from configured
    # auto-register paths and registering components automatically within the
    # container.
    #
    # @api private
    class AutoRegistrar
      attr_reader :container

      attr_reader :config

      def initialize(container)
        @container = container
        @config = container.config
      end

      # @api private
      def finalize!
        config.component_dirs.each do |dir|
          call(dir.path) if dir.auto_register
        end
      end

      # @api private
      def call(dir)
        registration_config = Configuration.new
        yield(registration_config) if block_given?
        components(dir).each do |component|
          next if !component.auto_register? || registration_config.exclude.(component)

          container.require_component(component) do
            register(component.identifier, memoize: registration_config.memoize) {
              registration_config.instance.(component)
            }
          end
        end
      end

      private

      # @api private
      def components(dir)
        files(dir)
          .map { |file_name| [file_name, file_options(file_name)] }
          .map { |file_name, options| component(relative_path(dir, file_name), **options) }
          .reject { |component| registered?(component.identifier) }
      end

      # @api private
      def files(dir)
        components_dir = File.join(root, dir)

        unless ::Dir.exist?(components_dir)
          raise ComponentsDirMissing, "Components dir '#{components_dir}' not found"
        end

        ::Dir["#{components_dir}/**/#{RB_GLOB}"].sort
      end

      # @api private
      def relative_path(dir, file_path)
        dir_root = root.join(dir.to_s.split("/")[0])
        file_path.to_s.sub("#{dir_root}/", "").sub(RB_EXT, EMPTY_STRING)
      end

      # @api private
      def file_options(file_name)
        MagicCommentsParser.(file_name)
      end

      # @api private
      def component(path, **options)
        container.component(path, **options)
      end

      # @api private
      def root
        container.root
      end

      # @api private
      def registered?(name)
        container.registered?(name)
      end

      # @api private
      def register(*args, &block)
        container.register(*args, &block)
      end
    end
  end
end
