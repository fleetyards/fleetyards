# frozen_string_literal: true

require "openapi_helper"

class Api::V1::VehiclesTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/vehicles" do
    post("Create new Vehicle") do
      operationId "createVehicle"
      tags "Vehicles"
      consumes "application/json"
      produces "application/json"

      security [
        {SessionCookie: []},
        {Oauth2: ["hangar", "hangar:write"]},
        {OpenId: ["hangar", "hangar:write"]}
      ]

      request_body required: true, schema: ::V1::Schemas::Inputs::VehicleCreateInput

      response(201, "successful") do
        schema ::V1::Schemas::Vehicles::Vehicle
      end

      response(401, "unauthorized") do
        schema ::Shared::V1::Schemas::StandardError
      end
    end
  end

  api_path "/vehicles/bulk" do
    put("Update multiple vehicles") do
      operationId "updateBulkVehicle"
      tags "Vehicles"
      consumes "application/json"
      produces "application/json"

      security [
        {SessionCookie: []},
        {Oauth2: ["hangar", "hangar:write"]},
        {OpenId: ["hangar", "hangar:write"]}
      ]

      request_body required: true, schema: ::V1::Schemas::Inputs::VehicleUpdateBulkInput

      response(204, "successful")

      response(401, "unauthorized") do
        schema ::Shared::V1::Schemas::StandardError
      end
    end
  end

  api_path "/vehicles/destroy-all-ingame" do
    delete("Delete all ingame bought Vehicles") do
      operationId "destroyAllIngameVehicles"
      tags "Vehicles"

      security [
        {SessionCookie: []},
        {Oauth2: ["hangar", "hangar:write"]},
        {OpenId: ["hangar", "hangar:write"]}
      ]

      response(204, "successful")

      response(401, "unauthorized") do
        schema ::Shared::V1::Schemas::StandardError
      end
    end
  end

  api_path "/vehicles/{id}" do
    parameter name: "id", in: :path, description: "Vehicle id or serial", schema: {type: :string}

    delete("Delete Vehicle") do
      operationId "destroyVehicle"
      tags "Vehicles"
      consumes "application/json"
      produces "application/json"

      security [
        {SessionCookie: []},
        {Oauth2: ["hangar", "hangar:write"]},
        {OpenId: ["hangar", "hangar:write"]}
      ]

      response(200, "successful") do
        schema ::V1::Schemas::Vehicles::Vehicle
      end

      response(401, "unauthorized") do
        schema ::Shared::V1::Schemas::StandardError
      end

      response(404, "not found") do
        schema ::Shared::V1::Schemas::StandardError
      end
    end

    get("Show Vehicle") do
      operationId "showVehicle"
      tags "Vehicles"
      produces "application/json"

      security [
        {SessionCookie: []},
        {Oauth2: ["hangar", "hangar:read"]},
        {OpenId: ["hangar", "hangar:read"]}
      ]

      response(200, "successful") do
        schema ::V1::Schemas::Vehicles::Vehicle
      end

      response(401, "unauthorized") do
        schema ::Shared::V1::Schemas::StandardError
      end

      response(404, "not found") do
        schema ::Shared::V1::Schemas::StandardError
      end
    end

    put("Update Vehicle") do
      operationId "updateVehicle"
      tags "Vehicles"
      consumes "application/json"
      produces "application/json"

      security [
        {SessionCookie: []},
        {Oauth2: ["hangar", "hangar:write"]},
        {OpenId: ["hangar", "hangar:write"]}
      ]

      request_body required: true, schema: ::V1::Schemas::Inputs::VehicleUpdateInput

      response(200, "successful") do
        schema ::V1::Schemas::Vehicles::Vehicle
      end

      response(400, "bad request") do
        schema ::Shared::V1::Schemas::ValidationError
      end

      response(401, "unauthorized") do
        schema ::Shared::V1::Schemas::StandardError
      end

      response(403, "supporter required") do
        schema ::Shared::V1::Schemas::StandardError
      end

      response(404, "not found") do
        schema ::Shared::V1::Schemas::StandardError
      end
    end
  end

  setup do
    @user = create(:user)
  end

  # POST /vehicles
  test "POST /vehicles creates a vehicle" do
    model = create(:model)
    sign_in @user

    assert_api_response :post, 201, body: {modelId: model.id}
  end

  test "POST /vehicles returns 401 when not signed in" do
    model = create(:model)

    assert_api_response :post, 401, body: {modelId: model.id}
  end

  test "POST /vehicles with OAuth bearer token" do
    model = create(:model)

    assert_api_response :post, 201,
      headers: oauth_headers_for(@user, scopes: ["hangar", "hangar:write"]),
      body: {modelId: model.id}
  end

  # PUT /vehicles/bulk
  test "PUT /vehicles/bulk updates the listed vehicles" do
    vehicles = create_list(:vehicle, 3, user: @user)
    sign_in @user

    assert_api_response :put, 204, body: {ids: vehicles.map(&:id), wanted: true}
  end

  test "PUT /vehicles/bulk returns 401 when not signed in" do
    vehicles = create_list(:vehicle, 3, user: @user)

    assert_api_response :put, 401, body: {ids: vehicles.map(&:id), wanted: true}
  end

  test "PUT /vehicles/bulk with OAuth bearer token" do
    vehicles = create_list(:vehicle, 3, user: @user)

    assert_api_response :put, 204,
      headers: oauth_headers_for(@user, scopes: ["hangar", "hangar:write"]),
      body: {ids: vehicles.map(&:id), wanted: true}
  end

  # DELETE /vehicles/destroy-all-ingame
  test "DELETE /vehicles/destroy-all-ingame keeps non-ingame vehicles" do
    create_list(:vehicle, 3, user: @user, bought_via: :pledge_store)
    create_list(:vehicle, 3, user: @user, bought_via: :ingame)
    sign_in @user

    assert_api_response :delete, 204 do
      assert_equal 3, @user.vehicles.where(bought_via: :pledge_store).count
      assert_equal 0, @user.vehicles.where(bought_via: :ingame).count
    end
  end

  test "DELETE /vehicles/destroy-all-ingame returns 401 when not signed in" do
    assert_api_response :delete, 401
  end

  test "DELETE /vehicles/destroy-all-ingame with OAuth bearer token" do
    create_list(:vehicle, 2, user: @user, bought_via: :ingame)

    assert_api_response :delete, 204, headers: oauth_headers_for(@user, scopes: ["hangar", "hangar:write"])
  end

  # DELETE /vehicles/:id
  test "DELETE /vehicles/:id removes the vehicle" do
    vehicle = create(:vehicle, user: @user)
    sign_in @user

    assert_api_response :delete, 200, path_params: {id: vehicle.id}
  end

  test "DELETE /vehicles/:id returns 404 for missing id" do
    sign_in @user

    assert_api_response :delete, 404, path_params: {id: SecureRandom.uuid}
  end

  test "DELETE /vehicles/:id returns 401 when not signed in" do
    vehicle = create(:vehicle, user: @user)

    assert_api_response :delete, 401, path_params: {id: vehicle.id}
  end

  test "DELETE /vehicles/:id with OAuth bearer token" do
    vehicle = create(:vehicle, user: @user)

    assert_api_response :delete, 200,
      path_params: {id: vehicle.id},
      headers: oauth_headers_for(@user, scopes: ["hangar", "hangar:write"])
  end

  # GET /vehicles/:id
  test "GET /vehicles/:id returns the vehicle" do
    vehicle = create(:vehicle, user: @user)
    sign_in @user

    assert_api_response :get, 200, path_params: {id: vehicle.id}
  end

  test "GET /vehicles/:id names the fleets the ship is listed in" do
    vehicle = create(:vehicle, user: @user)
    fleet = create(:fleet, name: "Dusk Haulers")
    create(:fleet_membership, :accepted, fleet:, user: @user)
    FleetVehicle.find_or_create_by!(fleet:, vehicle:)
    left = create(:fleet)
    FleetVehicle.create!(fleet: left, vehicle:)
    sign_in @user

    assert_api_response :get, 200, path_params: {id: vehicle.id} do
      assert_equal ["Dusk Haulers"], parsed_body["fleets"].pluck("name")
    end
  end

  test "GET /vehicles/:id returns 404 for missing id" do
    sign_in @user

    assert_api_response :get, 404, path_params: {id: SecureRandom.uuid}
  end

  test "GET /vehicles/:id returns 401 when not signed in" do
    vehicle = create(:vehicle, user: @user)

    assert_api_response :get, 401, path_params: {id: vehicle.id}
  end

  test "GET /vehicles/:id with OAuth bearer token" do
    vehicle = create(:vehicle, user: @user)

    assert_api_response :get, 200,
      path_params: {id: vehicle.id},
      headers: oauth_headers_for(@user, scopes: ["hangar", "hangar:read"])
  end

  # PUT /vehicles/:id
  test "PUT /vehicles/:id updates the vehicle" do
    vehicle = create(:vehicle, user: @user)
    sign_in @user

    assert_api_response :put, 200, path_params: {id: vehicle.id}, body: {name: "Enterprise A"}
  end

  # The controller sets `whodunnit` from `current_resource_owner`, so the owner
  # is on the record the moment their edit is filed at all -- which it was not
  # until the `author_id` gate came off.
  test "PUT /vehicles/:id records the change against the user who made it" do
    vehicle = create(:vehicle, user: @user)
    sign_in @user

    assert_difference -> { PaperTrail::Version.where(item_type: "Vehicle", item_id: vehicle.id).count }, 1 do
      assert_api_response :put, 200, path_params: {id: vehicle.id}, body: {name: "Enterprise A"}
    end

    version = PaperTrail::Version
      .where(item_type: "Vehicle", item_id: vehicle.id).order(created_at: :desc).first

    assert_equal "Enterprise A", version.changeset["name"].last
    assert_equal @user.id, version.whodunnit
    assert_nil version.author_id, "an owner's own edit is not an admin action"
  end

  test "PUT /vehicles/:id returns 404 for missing id" do
    sign_in @user

    assert_api_response :put, 404, path_params: {id: SecureRandom.uuid}, body: {name: "x"}
  end

  test "PUT /vehicles/:id returns 401 when not signed in" do
    vehicle = create(:vehicle, user: @user)

    assert_api_response :put, 401, path_params: {id: vehicle.id}, body: {name: "x"}
  end

  test "PUT /vehicles/:id with OAuth bearer token" do
    vehicle = create(:vehicle, user: @user)

    assert_api_response :put, 200,
      path_params: {id: vehicle.id},
      headers: oauth_headers_for(@user, scopes: ["hangar", "hangar:write"]),
      body: {name: "Enterprise A"}
  end
  test "PUT /vehicles/:id attaches an uploaded image" do
    Flipper.enable("vehicle_overview")
    vehicle = create(:vehicle, user: @user)
    sign_in @user

    assert_api_response :put, 200, path_params: {id: vehicle.id}, body: {image: upload_blob("ship.jpg", "image/jpeg").signed_id} do
      assert_equal "ship.jpg", parsed_body.dig("image", "name")
    end

    assert vehicle.reload.image.attached?
  end

  test "PUT /vehicles/:id removes the image when sent null" do
    Flipper.enable("vehicle_overview")
    vehicle = create(:vehicle, user: @user)
    vehicle.update!(image: upload_blob("ship.jpg", "image/jpeg").signed_id)
    sign_in @user

    assert_api_response :put, 200, path_params: {id: vehicle.id}, body: {image: nil} do
      assert_nil parsed_body["image"]
    end

    assert_not vehicle.reload.image.attached?
  end

  test "PUT /vehicles/:id links the ship to a starmap location" do
    Flipper.enable("vehicle_overview")
    vehicle = create(:vehicle, user: @user)
    location = create(:location, name: "Lorville")
    sign_in @user

    assert_api_response :put, 200, path_params: {id: vehicle.id}, body: {locationId: location.id} do
      assert_equal "Lorville", parsed_body["location"]
      assert_equal location.id, parsed_body.dig("linkedLocation", "id")
    end
  end

  test "PUT /vehicles/:id returns 400 for a location that does not exist" do
    Flipper.enable("vehicle_overview")
    vehicle = create(:vehicle, user: @user)
    sign_in @user

    assert_api_response :put, 400, path_params: {id: vehicle.id}, body: {locationId: SecureRandom.uuid}
  end

  test "PUT /vehicles/:id keeps a location the starmap does not carry as text" do
    Flipper.enable("vehicle_overview")
    vehicle = create(:vehicle, user: @user)
    sign_in @user

    assert_api_response :put, 200, path_params: {id: vehicle.id}, body: {location: "Behind the moon"} do
      assert_equal "Behind the moon", parsed_body["location"]
      assert_nil parsed_body["linkedLocation"]
    end
  end

  test "PUT /vehicles/:id sets the dedication plaque" do
    Flipper.enable("vehicle_overview")
    create(:supporter_contribution, user: @user)
    vehicle = create(:vehicle, user: @user)
    vehicle.model.manufacturer.update!(short_name: "Crusader", shipyard: "Orison, Crusader (Stanton II)")
    port = create(:location, name: "Port Olisar")
    sign_in @user

    assert_api_response :put, 200, path_params: {id: vehicle.id}, body: {
      dedication: "To boldly go", launchedOn: "2026-10-12", launchPortLocationId: port.id, affiliation: "Maru Inc.", operationsGroup: "uee"
    } do
      assert_equal "To boldly go", parsed_body["dedication"]
      assert_equal "2026-10-12", parsed_body["launchedOn"]
      assert_equal "Port Olisar", parsed_body["launchPort"]
      assert_equal port.id, parsed_body.dig("launchPortLocation", "id")
      assert_equal "Maru Inc.", parsed_body["affiliation"]
      assert_equal "uee", parsed_body["operationsGroup"]
      assert_equal "Orison, Crusader (Stanton II)", parsed_body["shipyard"]
      assert_equal "Crusader", parsed_body["manufacturerShortName"]
    end
  end

  test "PUT /vehicles/:id lets anyone put a plaque on their ship in the default style" do
    Flipper.enable("vehicle_overview")
    vehicle = create(:vehicle, user: @user)
    sign_in @user

    assert_api_response :put, 200, path_params: {id: vehicle.id}, body: {dedication: "To boldly go", plaqueStyle: "brass"} do
      assert_equal "To boldly go", parsed_body["dedication"]
      assert_equal "brass", parsed_body["plaqueStyle"]
    end
  end

  test "PUT /vehicles/:id keeps the other plaque styles for supporters" do
    Flipper.enable("vehicle_overview")
    vehicle = create(:vehicle, user: @user)
    sign_in @user

    assert_api_response :put, 403, path_params: {id: vehicle.id}, body: {dedication: "To boldly go", plaqueStyle: "neon"} do
      assert_equal "supporter_required", parsed_body["code"]
    end

    assert_nil vehicle.reload.dedication
  end

  test "PUT /vehicles/:id lets a lapsed supporter clear their plaque" do
    Flipper.enable("vehicle_overview")
    vehicle = create(:vehicle, user: @user, dedication: "To boldly go", plaque_style: "neon")
    sign_in @user

    assert_api_response :put, 200, path_params: {id: vehicle.id}, body: {dedication: nil, plaqueStyle: nil} do
      assert_nil parsed_body["dedication"]
    end
  end

  test "PUT /vehicles/:id accepts an unchanged plaque from a lapsed supporter" do
    Flipper.enable("vehicle_overview")
    vehicle = create(:vehicle, user: @user, dedication: "To boldly go")
    sign_in @user

    assert_api_response :put, 200, path_params: {id: vehicle.id}, body: {dedication: "To boldly go", name: "Contorta"}
  end

  test "PUT /vehicles/:id lets a supporter pick a plaque style" do
    Flipper.enable("vehicle_overview")
    create(:supporter_contribution, user: @user)
    vehicle = create(:vehicle, user: @user)
    sign_in @user

    assert_api_response :put, 200, path_params: {id: vehicle.id}, body: {dedication: "To boldly go", plaqueStyle: "neon"} do
      assert_equal "neon", parsed_body["plaqueStyle"]
    end
  end

  test "GET /vehicles/:id draws a lapsed supporter's plaque in the default style" do
    vehicle = create(:vehicle, user: @user, dedication: "To boldly go", plaque_style: "neon")
    create(:supporter_contribution, user: @user, started_at: 3.months.ago)
    sign_in @user

    assert_api_response :get, 200, path_params: {id: vehicle.id} do
      assert_equal "brass", parsed_body["plaqueStyle"]
    end
    assert_equal "neon", vehicle.reload.plaque_style
  end

  test "PUT /vehicles/:id clears the dedication plaque" do
    Flipper.enable("vehicle_overview")
    create(:supporter_contribution, user: @user)
    vehicle = create(:vehicle, user: @user, dedication: "To boldly go", launched_on: Date.new(2026, 10, 12), affiliation: "Maru Inc.", operations_group: "nine_tails")
    sign_in @user

    assert_api_response :put, 200, path_params: {id: vehicle.id}, body: {dedication: "", launchedOn: nil, affiliation: "", operationsGroup: nil} do
      assert_nil parsed_body["dedication"]
      assert_nil parsed_body["launchedOn"]
      assert_nil parsed_body["affiliation"]
      assert_nil parsed_body["operationsGroup"]
    end
  end

  test "PUT /vehicles/:id rejects a dedication over the limit" do
    Flipper.enable("vehicle_overview")
    create(:supporter_contribution, user: @user)
    vehicle = create(:vehicle, user: @user)
    sign_in @user

    assert_api_response :put, 400, path_params: {id: vehicle.id}, body: {dedication: "a" * (Vehicle::DEDICATION_LIMIT + 1)}
  end

  test "PUT /vehicles/:id rejects an operations group the lore does not know" do
    Flipper.enable("vehicle_overview")
    create(:supporter_contribution, user: @user)
    vehicle = create(:vehicle, user: @user)
    sign_in @user

    assert_api_response :put, 400, path_params: {id: vehicle.id}, body: {operationsGroup: "vanduul_clan"}
  end

  test "PUT /vehicles/:id picks a picture from the model's gallery" do
    Flipper.enable("vehicle_overview")
    vehicle = create(:vehicle, user: @user)
    image = create(:image, gallery: vehicle.model)
    sign_in @user

    assert_api_response :put, 200, path_params: {id: vehicle.id}, body: {modelImageId: image.id} do
      assert parsed_body.dig("modelImage", "url").present?
    end

    assert_equal image, vehicle.reload.model_image
  end

  test "GET /vehicles/:id leaves out a gallery picture disabled since the pick" do
    Flipper.enable("vehicle_overview")
    vehicle = create(:vehicle, user: @user)
    image = create(:image, gallery: vehicle.model)
    vehicle.update!(model_image: image)
    image.update!(enabled: false)
    sign_in @user

    assert_api_response :get, 200, path_params: {id: vehicle.id} do
      assert_nil parsed_body["modelImage"]
    end
  end

  test "PUT /vehicles/:id rejects a picture from another model's gallery" do
    Flipper.enable("vehicle_overview")
    vehicle = create(:vehicle, user: @user)
    image = create(:image, gallery: create(:model))
    sign_in @user

    assert_api_response :put, 400, path_params: {id: vehicle.id}, body: {modelImageId: image.id}

    assert_nil vehicle.reload.model_image_id
  end

  test "PUT /vehicles/:id rejects a disabled gallery picture" do
    Flipper.enable("vehicle_overview")
    vehicle = create(:vehicle, user: @user)
    image = create(:image, :disabled, gallery: vehicle.model)
    sign_in @user

    assert_api_response :put, 400, path_params: {id: vehicle.id}, body: {modelImageId: image.id}
  end

  test "PUT /vehicles/:id rejects an SVG image" do
    Flipper.enable("vehicle_overview")
    vehicle = create(:vehicle, user: @user)
    sign_in @user

    assert_api_response :put, 400, path_params: {id: vehicle.id}, body: {image: upload_blob("vector.svg", "image/svg+xml").signed_id}

    assert_not vehicle.reload.image.attached?
  end

  test "PUT /vehicles/:id ignores the overview fields while the feature is off" do
    vehicle = create(:vehicle, user: @user)
    sign_in @user

    assert_api_response :put, 200,
      path_params: {id: vehicle.id},
      body: {image: upload_blob("ship.jpg", "image/jpeg").signed_id, logEntriesPublicByDefault: true, dedication: "To boldly go"}

    vehicle.reload
    assert_not vehicle.image.attached?
    assert_not vehicle.log_entries_public_by_default
    assert_nil vehicle.dedication
  end

  private def upload_blob(filename, content_type)
    ActiveStorage::Blob.create_and_upload!(
      io: file_fixture(filename).open, filename:, content_type:
    )
  end
end
