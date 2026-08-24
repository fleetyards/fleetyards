# frozen_string_literal: true

# Points a loader at the curated export in test/fixtures/sc_data instead of
# the real parsed tree. See that directory's README for what it holds and why.
module ScDataFixtureTree
  FIXTURE_BASE_FOLDER = Rails.root.join("test/fixtures/sc_data").freeze
  FIXTURE_ENVIRONMENT = "test"
  EMPTY_ENVIRONMENT = "empty"

  def fixture_loader(loader_class)
    loader_class.new(base_folder: FIXTURE_BASE_FOLDER).tap do |loader|
      loader.sc_environment = FIXTURE_ENVIRONMENT
    end
  end

  # A tree that carries no catalogue at all -- what a build whose files failed
  # to sync looks like from a loader's side.
  def empty_tree_loader(loader_class)
    fixture_loader(loader_class).tap do |loader|
      loader.sc_environment = EMPTY_ENVIRONMENT
    end
  end
end
