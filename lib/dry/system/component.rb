# frozen_string_literal: true

require "concurrent/map"

require "dry-equalizer"
require "dry/inflector"
require "dry/system/loader"
require "dry/system/errors"
require "dry/system/constants"

module Dry
  module System
    # Components are objects providing information about auto-registered files.
    # They expose an API to query this information and use a configurable
    # loader object to initialize class instances.
    #
    # Components are created automatically through auto-registration and can be
    # accessed through `Container.auto_register!` which yields them.
    #
    # @api public
    class Component
      include Dry::Equalizer(:identifier, :path)

      DEFAULT_OPTIONS = {
        separator: DEFAULT_SEPARATOR,
        # namespace: nil,
        inflector: Dry::Inflector.new,
        loader: Loader
      }.freeze

      # @!attribute [r] identifier
      #   @return [String] component's unique identifier
      attr_reader :identifier

      # @!attribute [r] path
      #   @return [String] component's relative path
      attr_reader :path

      # TODO: need better naming, above should just be
      attr_reader :file_path

      # @!attribute [r] file
      #   @return [String] component's file name
      attr_reader :file

      # @!attribute [r] options
      #   @return [Hash] component's options
      attr_reader :options

      # @!attribute [r] loader
      #   @return [Object#call] component's loader object
      attr_reader :loader

      # self.locate?
      def self.find(identifier, component_dirs, **options)
        # byebug

        options = DEFAULT_OPTIONS.merge(options || EMPTY_HASH)

        path = identifier.to_s.gsub(options[:separator], PATH_SEPARATOR)

        # byebug
        found_path, found_namespace = component_dirs.reduce(nil) { |_, dir|
          # byebug
          component_file = dir.component_file(path)
          break [component_file, dir.default_namespace] if component_file
        }

        # byebug

        # found_path


        # byebug unless found_path

        # raise "Not found" unless found_path

        # TODO: read options from top of file? that's what the auto-registrar does (or
        # maybe we should be doing that in Container.component?)

        # TODO: component should have a reference to its full file path

        # byebug
        puts "namespace: #{found_namespace}"
        # if found_path
          new(
            identifier,
            namespace: found_namespace,
            file_path: found_path,
            **options
          )
        # end
      end

      # @api private
      # def self.old_new(*args)#, &block)
      #   # Honestly not sure why we cache components
      #   # cache.fetch_or_store([*args, block].hash) do

      #   name, options = args
      #   options = DEFAULT_OPTIONS.merge(options || EMPTY_HASH)

      #   namespace, separator, inflector = options.values_at(:namespace, :separator, :inflector)
      #   identifier = extract_identifier(name, namespace, separator)

      #   path = name.to_s.gsub(separator, PATH_SEPARATOR)
      #   loader = options.fetch(:loader, Loader).new(path, inflector)



      #   super(identifier, path, options.merge(loader: loader))

      #   # end
      # end

      def self.new(identifier, **options)
        # byebug
        options = DEFAULT_OPTIONS.merge(options || EMPTY_HASH)

        namespace, separator, inflector, loader = \
          options.values_at(:namespace, :separator, :inflector, :loader)

        # byebug

        identifier = extract_identifier(identifier, namespace, separator)

        path = identifier.to_s.gsub(separator, PATH_SEPARATOR)
        # path = identifier.to_s.gsub(separator, PATH_SEPARATOR)

        namespace = namespace.to_s.gsub(separator, PATH_SEPARATOR) if namespace

        path = [namespace, path].compact.join(PATH_SEPARATOR)

        # byebug

        loader = loader.new(path, inflector)

        super(identifier, path: path, **options.merge(loader: loader))
      end

      # @api private
      def self.extract_identifier(identifier, namespace, separator)
        identifier = identifier.to_s

        identifier = namespace ? remove_namespace_from_name(identifier, namespace) : identifier

        identifier.scan(WORD_REGEX).join(separator)
      end

      # @api private
      def self.remove_namespace_from_name(name, namespace)
        match_value = name.match(/^(?<remove_namespace>#{namespace})(?<separator>\W)(?<identifier>.*)/)

        match_value ? match_value[:identifier] : name
      end

      # @api private
      def self.cache
        @cache ||= Concurrent::Map.new
      end

      # @api private
      def initialize(identifier, path:, file_path: nil, **options)
        # @options =
        # @options =

        # byebug

        @identifier = identifier
        # @path = [options[:namespace], path].compact.join("/") # FIXME make nicer
        @path = path
        @file_path = file_path
        @options = options
        @file = "#{path}#{RB_EXT}"
        @loader = options.fetch(:loader)
        freeze

        # byebug
      end

      def require!
        loader.require!
      end

      # Returns components instance
      #
      # @example
      #   class MyApp < Dry::System::Container
      #     configure do |config|
      #       config.name = :my_app
      #       config.root = Pathname('/my/app')
      #     end
      #
      #     auto_register!('lib/clients') do |component|
      #       # some custom initialization logic, ie:
      #       constant = component.loader.constant
      #       constant.create
      #     end
      #   end
      #
      # @return [Object] component's class instance
      #
      # @api public
      def instance(*args)
        loader.call(*args)
      end
      ruby2_keywords(:instance) if respond_to?(:ruby2_keywords, true)

      # @api private
      def bootable?
        false
      end

      # @api private
      # SHOULDN"T BE NEEDED ANYMORE
      def file_exists?(paths)
        paths.any? { |path| path.join(file).exist? }
      end

      def file_really_exists?
        !!file_path
      end

      # @api private
      def prepend(name)
        # FIXME: should this actually keep the path and file_path??!?!

        self.class.new(
          [name, identifier].join(separator),
          path: path,
          file_path: file_path,
          **options.merge(loader: loader.class)
        )
      end

      # @api private
      def namespaced(namespace)
        # FIXME: should this actually keep the path and file_path??!?!

        self.class.new(
          identifier,
          path: path,
          file_path: file_path,
          **options.merge(loader: loader.class, namespace: namespace)
        )
      end

      # @api private
      def separator
        options[:separator]
      end

      # @api private
      def namespace
        options[:namespace]
      end

      # @api private
      def auto_register?
        !!options.fetch(:auto_register) { true }
      end

      # @api private
      def root_key
        namespaces.first
      end

      private

      def namespaces
        identifier.split(separator).map(&:to_sym)
      end
    end
  end
end
