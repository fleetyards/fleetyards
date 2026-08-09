# frozen_string_literal: true

require "openapi_helper"

class Api::V1::HangarInventoryItemsImportTest < ActionDispatch::IntegrationTest
  setup do
    Flipper.enable("hangar_inventories")
    @user = create(:user)
    @other_user = create(:user)
    @inventory = create(:hangar_inventory, user: @user)
  end

  def csv_upload(content)
    file = Tempfile.new(["inventory", ".csv"])
    file.write(content)
    file.rewind

    Rack::Test::UploadedFile.new(file.path, "text/csv")
  end

  test "imports rows as deposits" do
    sign_in @user

    post "/api/v1/hangar/inventories/#{@inventory.slug}/items/import",
      params: {file: csv_upload(<<~CSV)}
        name,category,quantity,unit,notes
        Quantanium,commodity,100,scu,from mining run
        Med Pens,consumable,25,units,
      CSV

    assert_response :success
    body = JSON.parse(response.body)
    assert_equal 2, body["imported"]
    assert_empty body["errors"]
    assert_equal 2, @inventory.hangar_inventory_items.count
  end

  test "reports per-row errors without aborting valid rows" do
    sign_in @user

    post "/api/v1/hangar/inventories/#{@inventory.slug}/items/import",
      params: {file: csv_upload(<<~CSV)}
        name,category,quantity,unit
        Quantanium,commodity,100,scu
        ,commodity,10,scu
        Titanium,spaceship,10,scu
      CSV

    assert_response :success
    body = JSON.parse(response.body)
    assert_equal 1, body["imported"]
    assert_equal 2, body["errors"].count
  end

  test "returns 404 for another user's inventory" do
    sign_in @other_user

    post "/api/v1/hangar/inventories/#{@inventory.slug}/items/import",
      params: {file: csv_upload("name,quantity\nQuantanium,10\n")}

    assert_response :not_found
  end

  test "returns 401 when not signed in" do
    post "/api/v1/hangar/inventories/#{@inventory.slug}/items/import",
      params: {file: csv_upload("name,quantity\nQuantanium,10\n")}

    assert_response :unauthorized
  end
end
