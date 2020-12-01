# frozen_string_literal: true

require "dry/system/container"
require "dry/system/loader/autoloading"
require "zeitwerk"

RSpec.describe "Auto-registration" do
  specify "Resolving components from a non-finalized container, using a default namespace" do
    module Test
      class Container < Dry::System::Container
        configure do |config|
          config.root = SPEC_ROOT.join("fixtures/standard_container_with_default_namespace").realpath
          config.component_dirs.add "lib"
          config.default_namespace = "test"
        end
      end

      Import = Container.injector
    end

    example_with_dep = Test::Container["example_with_dep"]

    expect(example_with_dep).to be_a Test::ExampleWithDep
    expect(example_with_dep.dep).to be_a Test::Dep
  end
end
