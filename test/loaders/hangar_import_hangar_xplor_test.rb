# frozen_string_literal: true

require "test_helper"
require "webmock/minitest"
require_relative "../support/hangar_import_fixtures"

class HangarImportHangarXplorTest < ActiveSupport::TestCase
  include HangarImportFixtures

  setup do
    @loader = ::Rsi::ModelsLoader.new
    @user = create(:user)
    @import_file = Rack::Test::UploadedFile.new(Rails.root.join("spec/fixtures/imports/hangarXPLOR.json"))
    @import = ::Imports::HangarImport.create!(user_id: @user.id, import: @import_file)
    @pledge_store_data = JSON.parse(File.read("spec/fixtures/rsi/pledge_store.json"))

    Timecop.freeze("2017-01-01 14:00:00")
    stub_rsi_matrix_and_pledge_store(@pledge_store_data)

    @loader.all
    load Rails.root.join("db/seeds/01_manual_models.rb")
  end

  teardown do
    Import.destroy_all
    Timecop.return
  end

  test "imports all data from hangarXPLOR export" do
    result = ::HangarImporter.new(@import).run
    assert_equal({missing: [], imported: HangarImportFixtures::IMPORTED_SHIPS_HANGAR_XPLOR, success: true}, result)
  end
end
