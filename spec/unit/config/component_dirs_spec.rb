require "dry/system/config/component_dirs"

RSpec.describe Dry::System::Config::ComponentDirs do
  subject(:component_dirs) { described_class.new }

  it "works?" do
    component_dirs.add "test/path" do |dir|
      dir.auto_register = false
      dir.add_to_load_path = false
    end

    expect(component_dirs.dirs.length).to eq 1

    # Hmm, do I want a hash or an array here?
    dir = component_dirs.dirs["test/path"]

    expect(dir.auto_register).to eq false
    expect(dir.add_to_load_path).to eq false
  end
end
