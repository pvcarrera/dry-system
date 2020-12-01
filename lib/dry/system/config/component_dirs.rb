require "dry/configurable"
require "set"
require_relative "component_dir"

module Dry
  module System
    module Config
      class ComponentDirs
        attr_reader :dirs

        def initialize
          # I guess I really want a concurrent hash here?
          @dirs = {}
        end

        def initialize_copy(source)
          super
          @dirs = source.dirs.dup
        end

        # Hack for dry-configurable, which needs more smarts when it comes to determining what to clone
        def is_a?(klass)
          return true if klass == Set
          super
        end

        def add(path_or_component_dir, &block)
          if path_or_component_dir.is_a?(ComponentDir)
            add_component_dir(path_or_component_dir)
          else
            build_and_add_component_dir(path_or_component_dir, &block)
          end
        end

        def to_a
          dirs.values
        end

        def each(&block)
          to_a.each(&block)
        end

        private

        def build_and_add_component_dir(path, &block)
          add_component_dir ComponentDir.new(path, &block)
        end

        def add_component_dir(dir)
          raise "Directory already added" if dirs.key?(dir.path)
          dirs[dir.path] = dir
        end
      end
    end
  end
end
