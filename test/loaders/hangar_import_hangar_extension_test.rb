# frozen_string_literal: true

require "test_helper"
require "support/hangar_import_fixtures"

class HangarImportHangarExtensionTest < ActiveSupport::TestCase
  include HangarImportFixtures

  EXAMPLE_FILE = Rails.root.join("public/examples/hangar-extension-example.json")

  setup do
    load_loader_fixtures
    @user = create(:user)
  end

  # The file the import modal offers as a download. A sample that stops
  # importing is worse than none, so it is imported here rather than trusted.
  test "the published example file imports cleanly" do
    result = ::HangarImporter.new(import_of_example).run

    assert_empty result[:missing]
    assert_equal ["Avenger Titan", "Carrack", "F7C-M Super Hornet Heartseeker Mk I"], result[:imported]
    assert_predicate Vehicle.where(user_id: @user.id).purchased, :any?
  end

  test "drops the craft listed as included with another ship" do
    import = import_of_example

    assert_equal ["Avenger Titan", "Carrack w/C8X", "F7C-M Super Hornet Heartseeker Mk I"],
      import.import_data.pluck(:matrix)

    ::HangarImporter.new(import).run

    owned = Vehicle.where(user_id: @user.id, loaner: false, bundled: false)
    assert_equal ["Avenger Titan", "Carrack", "F7C-M Super Hornet Heartseeker Mk I"],
      owned.joins(:model).order("models.name").pluck("models.name")
  end

  test "prefers the matrix name over the export alias" do
    import = import_for([{matrix: "F7C-M Super Hornet Heartseeker Mk I", name: "F7C-M Super Hornet Heartseeker"}])

    result = ::HangarImporter.new(import).run

    assert_equal ["F7C-M Super Hornet Heartseeker Mk I"], result[:imported]
  end

  test "falls back to the export alias when the matrix name matches nothing" do
    import = import_for([{matrix: "Avenger Titan Prototype", name: "Avenger Titan"}])

    result = ::HangarImporter.new(import).run

    assert_equal ["Avenger Titan"], result[:imported]
  end

  test "reports a miss under its matrix name" do
    import = import_for([{matrix: "Bengal Carrier", name: "Bengal"}])

    result = ::HangarImporter.new(import).run

    assert_equal ["Bengal Carrier"], result[:missing]
  end

  def import_of_example
    ::Imports::HangarImport.create!(user_id: @user.id, import: Rack::Test::UploadedFile.new(EXAMPLE_FILE))
  end

  def import_for(items)
    import = import_of_example
    import.update!(import_data: items)
    import
  end
end
