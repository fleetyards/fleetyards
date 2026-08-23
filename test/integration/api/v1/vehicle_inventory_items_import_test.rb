# frozen_string_literal: true

require "openapi_helper"

class Api::V1::VehicleInventoryItemsImportTest < ActionDispatch::IntegrationTest
  setup do
    Flipper.enable("ship_inventories")
    @user = create(:user)
    @other_user = create(:user)
    @vehicle = create(:vehicle, user: @user, model: create(:model, name: "Ironclad"))
  end

  def csv_upload(content)
    file = Tempfile.new(["inventory", ".csv"])
    file.write(content)
    file.rewind

    Rack::Test::UploadedFile.new(file.path, "text/csv")
  end

  def import_path(vehicle = @vehicle)
    "/api/v1/vehicles/#{vehicle.id}/inventory/items/import"
  end

  test "imports rows as deposits and provisions the inventory" do
    sign_in @user

    assert_difference "Inventory.count", 1 do
      post import_path, params: {file: csv_upload(<<~CSV)}
        name,category,quantity,unit,notes
        Quantanium,commodity,100,scu,from mining run
        Med Pens,consumable,25,units,
      CSV
    end

    assert_response :success
    body = JSON.parse(response.body)

    assert_equal 2, body["imported"]
    assert_empty body["errors"]
    assert_equal "Ironclad Inventory", @vehicle.reload.inventory.name
    assert_equal 2, @vehicle.inventory.inventory_items.count
  end

  test "imports into the inventory the ship already has" do
    inventory = create(:inventory, holder: @user, vehicle: @vehicle)
    sign_in @user

    assert_no_difference "Inventory.count" do
      post import_path, params: {file: csv_upload("name,quantity\nQuantanium,10\n")}
    end

    assert_response :success
    assert_equal 1, inventory.inventory_items.count
  end

  test "an import that lands nothing leaves no inventory behind" do
    sign_in @user

    assert_no_difference "Inventory.count" do
      post import_path, params: {file: csv_upload(<<~CSV)}
        name,category,quantity,unit
        ,commodity,10,scu
        Titanium,spaceship,10,scu
      CSV
    end

    assert_response :success
    body = JSON.parse(response.body)

    assert_equal 0, body["imported"]
    assert_equal 2, body["errors"].count
  end

  test "a malformed file leaves no inventory behind" do
    sign_in @user

    assert_no_difference "Inventory.count" do
      post import_path, params: {file: csv_upload("name,quantity\n\"unclosed,10\n")}
    end

    assert_response :success
    assert_equal 0, JSON.parse(response.body)["imported"]
  end

  test "reports per-row errors without aborting valid rows" do
    sign_in @user

    post import_path, params: {file: csv_upload(<<~CSV)}
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

  test "returns 404 for another user's ship" do
    sign_in @other_user

    assert_no_difference "Inventory.count" do
      post import_path, params: {file: csv_upload("name,quantity\nQuantanium,10\n")}
    end

    assert_response :not_found
  end

  test "returns 401 when not signed in" do
    assert_no_difference "Inventory.count" do
      post import_path, params: {file: csv_upload("name,quantity\nQuantanium,10\n")}
    end

    assert_response :unauthorized
  end
end
