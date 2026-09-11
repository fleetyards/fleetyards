# frozen_string_literal: true

require "test_helper"
require "support/hangar_import_fixtures"

class HangarImporterTest < ActiveSupport::TestCase
  include HangarImportFixtures

  setup do
    load_loader_fixtures
    @user = create(:user)
    @import_file = Rack::Test::UploadedFile.new(Rails.root.join("test/fixtures/imports/export.json"))
    @import = ::Imports::HangarImport.create!(user_id: @user.id, import: @import_file)
    @model = Model.order(:name).first
  end

  test "imports all data" do
    result = ::HangarImporter.new(@import).run
    assert_equal({missing: [], imported: HangarImportFixtures::IMPORTED_SHIPS, success: true}, result)
  end

  # An import runs inline in the request, so the user is the `whodunnit` -- no
  # actor-based guard excludes it. It builds the hangar rather than editing it.
  test "records no versions" do
    assert_no_difference -> { PaperTrail::Version.where(item_type: "Vehicle").count } do
      ::HangarImporter.new(@import).run
    end

    assert_predicate Vehicle.where(user_id: @user.id), :any?
  end

  # Neither of these was asserted, which is how `wanted: item[:wanted] ||
  # !item[:purchased] || true` survived: every import landed on the wishlist,
  # and `Vehicle#reset_hangar_groups` then destroyed any group assignment the
  # importer had just made.
  test "imports owned ships as owned, not onto the wishlist" do
    ::HangarImporter.new(@import).run

    assert_predicate Vehicle.where(user_id: @user.id).purchased, :any?
    assert_empty Vehicle.where(user_id: @user.id).wanted
  end

  test "keeps an explicit wishlist entry on the wishlist" do
    file = Rack::Test::UploadedFile.new(Rails.root.join("test/fixtures/imports/export.json"))
    import = ::Imports::HangarImport.create!(user_id: @user.id, import: file)
    import.update!(import_data: [{name: @model.name, slug: @model.slug, wanted: true}])

    ::HangarImporter.new(import).run

    assert_predicate Vehicle.find_by(user_id: @user.id), :wanted?
  end
end
