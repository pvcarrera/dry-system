require "dry/configurable"
require_relative "component_dir"

module Dry
  module System
    module Config
      class ComponentDirs
        # include Dry::Configurable

        attr_reader :dirs

        def initialize
          # I guess I really want a concurrent hash here?
          @dirs = {}
        end

        def add(path, &block)
          raise "Directory already added" if dirs.key?(path)

          dirs[path] = ComponentDir.new(path, &block)
        end
      end
    end
  end
end
