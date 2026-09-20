# frozen_string_literal: true

require "openapi_helper"

class Api::V1::ModelsShowTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/models/{slug}" do
    parameter name: "slug", in: :path, schema: {type: :string}, description: "Model slug", required: true

    get("Model Detail") do
      operationId "model"
      tags "Models"
      produces "application/json"

      response(200, "successful") do
        schema ::V1::Schemas::Models::ModelExtended
      end

      response(404, "not found") do
        schema ::Shared::V1::Schemas::StandardError
      end
    end
  end

  test "GET /models/:slug names the ships that can carry it" do
    carrier = create(:model, name: "Big Carrier")
    create(:dock, :with_dimensions, parent: carrier, dock_type: :hangar)
    too_small = create(:model, name: "Small Carrier")
    create(:dock, parent: too_small, dock_type: :hangar, length: 8.0, beam: 6.0, height: 4.0)

    model = create(:model, length: 20.0, beam: 10.0, height: 5.0, size: "small")

    assert_api_response :get, 200, path_params: {slug: model.slug} do
      names = parsed_body["carriedBy"].map { |entry| entry["name"] }

      assert_includes names, carrier.name
      assert_not_includes names, too_small.name
      assert_equal "hangar", parsed_body["carriedBy"].first["dockType"]
    end
  end

  # Stated, not filtered on: the label says how the ship gets in, and a berth
  # nobody has looked at says nothing rather than guessing.
  test "GET /models/:slug says how a carrier's berth is reached" do
    carrier = create(:model, name: "Ramped Carrier")
    create(:dock, :with_dimensions, parent: carrier, dock_type: :hangar, access: :ramp)
    unrecorded = create(:model, name: "Unrecorded Carrier")
    create(:dock, :with_dimensions, parent: unrecorded, dock_type: :hangar, access: nil)

    model = create(:model, length: 20.0, beam: 10.0, height: 5.0, size: "small")

    assert_api_response :get, 200, path_params: {slug: model.slug} do
      entries = parsed_body["carriedBy"].index_by { |entry| entry["name"] }

      assert_equal "Ramp", entries[carrier.name]["accessLabel"]
      assert_not entries[unrecorded.name].key?("accessLabel")
    end
  end

  # The Galaxy's med bay carries a vehicle lift and its refinery does not, so a
  # berth that arrives with a module counts -- and says which module, because
  # the carrier is conditional on the owner having mounted it.
  test "GET /models/:slug names a carrier whose berth comes with a module" do
    carrier = create(:model, name: "Modular Carrier")
    model_module = create(:model_module, name: "Med Bay Module")
    create(:module_hardpoint, model: carrier, model_module: model_module)
    create(:dock, :with_dimensions, parent: model_module, dock_type: :hangar)

    model = create(:model, length: 20.0, beam: 10.0, height: 5.0, size: "small")

    assert_api_response :get, 200, path_params: {slug: model.slug} do
      entry = parsed_body["carriedBy"].find { |item| item["name"] == carrier.name }

      assert_not_nil entry
      assert_equal "Med Bay Module", entry["moduleName"]
    end
  end

  test "GET /models/:slug leaves moduleName off a berth built into the hull" do
    carrier = create(:model, name: "Fixed Carrier")
    create(:dock, :with_dimensions, parent: carrier, dock_type: :hangar)

    model = create(:model, length: 20.0, beam: 10.0, height: 5.0, size: "small")

    assert_api_response :get, 200, path_params: {slug: model.slug} do
      entry = parsed_body["carriedBy"].find { |item| item["name"] == carrier.name }

      assert_not_nil entry
      assert_nil entry["moduleName"]
    end
  end

  # A hover bike is size vehicle and ground false, so `ground` would have sent it
  # to a hangar instead of a bay.
  test "GET /models/:slug offers a bay to a hover bike" do
    carrier = create(:model, name: "Bay Carrier")
    create(:dock, :with_dimensions, parent: carrier, dock_type: :garage)

    bike = create(:model, length: 4.0, beam: 2.0, height: 2.0, size: "vehicle", ground: false)

    assert_api_response :get, 200, path_params: {slug: bike.slug} do
      assert_includes parsed_body["carriedBy"].map { |entry| entry["name"] }, carrier.name
    end
  end

  # An unmeasured hull is not compared at all: zeroes would satisfy every upper
  # bound and the answer would be confident and wrong.
  test "GET /models/:slug carries nothing for a model without dimensions" do
    carrier = create(:model)
    create(:dock, :with_dimensions, parent: carrier, dock_type: :hangar)

    unmeasured = create(:model, length: 0, beam: 0, height: 0, size: "small")

    assert_api_response :get, 200, path_params: {slug: unmeasured.slug} do
      assert_empty parsed_body["carriedBy"]
    end
  end

  # The curated answer, through the scope rather than the model: a described
  # berth says what it is built for, and the hall it sits in does not widen it.
  test "GET /models/:slug offers a carrier only what its class takes" do
    carrier = create(:model, name: "Described Carrier")
    dock = create(:dock, parent: carrier, dock_type: :hangar, length: 100, beam: 25, height: 8)
    create(:dock_capacity, dock:, ladder: :ship, size: "extra_small", quantity: 3)

    small = create(:model, length: 20.0, beam: 10.0, height: 5.0, size: "small")
    medium = create(:model, length: 55.0, beam: 30.0, height: 17.0, size: "small")

    assert_api_response :get, 200, path_params: {slug: small.slug} do
      assert_includes parsed_body["carriedBy"].map { |entry| entry["name"] }, carrier.name
    end

    assert_api_response :get, 200, path_params: {slug: medium.slug} do
      assert_not_includes parsed_body["carriedBy"].map { |entry| entry["name"] }, carrier.name
    end
  end

  # The Merchantman's case: one berth, no dimensions, and an answer anyway.
  test "GET /models/:slug offers a described carrier nobody measured" do
    carrier = create(:model, name: "Unmeasured Carrier")
    dock = create(:dock, parent: carrier, dock_type: :landingpad, length: nil, beam: nil, height: nil)
    create(:dock_capacity, dock:, ladder: :ship, size: "small", quantity: 1)

    model = create(:model, length: 20.0, beam: 10.0, height: 5.0, size: "small")

    assert_api_response :get, 200, path_params: {slug: model.slug} do
      assert_includes parsed_body["carriedBy"].map { |entry| entry["name"] }, carrier.name
    end
  end

  test "GET /models/:slug offers a carrier that names the ship outright" do
    carrier = create(:model, name: "Naming Carrier")
    dock = create(:dock, parent: carrier, dock_type: :hangar, length: 20, beam: 12, height: 6)
    create(:dock_capacity, dock:, ladder: :ship, size: "extra_extra_small", quantity: 1)

    oversized = create(:model, length: 120.0, beam: 60.0, height: 30.0, size: "large")
    create(:dock_addition, dock:, model: oversized)

    assert_api_response :get, 200, path_params: {slug: oversized.slug} do
      assert_includes parsed_body["carriedBy"].map { |entry| entry["name"] }, carrier.name
    end
  end

  # The scope has to read the same way as `Dock#fits?`: a berth nobody described
  # answers by its envelope, and a name on it adds to that rather than replacing
  # it.
  test "GET /models/:slug keeps an undescribed carrier's envelope answer beside its names" do
    carrier = create(:model, name: "Naming Undescribed Carrier")
    dock = create(:dock, parent: carrier, dock_type: :hangar, length: 40, beam: 20, height: 10)
    create(:dock_addition, dock:, model: create(:model, name: "Oversized", length: 120.0, beam: 60.0, height: 30.0, size: "large"))

    ordinary = create(:model, length: 20.0, beam: 10.0, height: 5.0, size: "small")

    assert_api_response :get, 200, path_params: {slug: ordinary.slug} do
      assert_includes parsed_body["carriedBy"].map { |entry| entry["name"] }, carrier.name
    end
  end

  # An unmeasured hull is not compared against anything, but a berth can still
  # name it -- and the carrier list has to say so.
  test "GET /models/:slug offers a carrier that names an unmeasured ship" do
    carrier = create(:model, name: "Naming Carrier For Unmeasured")
    dock = create(:dock, parent: carrier, dock_type: :hangar, length: 40, beam: 20, height: 10)
    unmeasured = create(:model, length: 0, beam: 0, height: 0, size: "small")
    create(:dock_addition, dock:, model: unmeasured)

    assert_api_response :get, 200, path_params: {slug: unmeasured.slug} do
      assert_includes parsed_body["carriedBy"].map { |entry| entry["name"] }, carrier.name
    end
  end

  # The same answer as `Dock#fits?` for a hull past every box: `capital` is the
  # rung it comes back as, and a capital berth is described at that rung.
  test "GET /models/:slug offers a capital berth a hull larger than every box" do
    carrier = create(:model, name: "Capital Carrier")
    dock = create(:dock, parent: carrier, dock_type: :hangar, length: 300, beam: 200, height: 80)
    create(:dock_capacity, dock:, ladder: :ship, size: "capital", quantity: 1)

    enormous = create(:model, length: 250.0, beam: 180.0, height: 70.0, size: "capital")

    assert_api_response :get, 200, path_params: {slug: enormous.slug} do
      assert_includes parsed_body["carriedBy"].map { |entry| entry["name"] }, carrier.name
    end
  end

  # A ship in a garage is the case that stays impossible.
  test "GET /models/:slug does not offer a garage to a ship" do
    carrier = create(:model)
    create(:dock, :with_dimensions, parent: carrier, dock_type: :garage)

    ship = create(:model, length: 4.0, beam: 2.0, height: 2.0, size: "small")

    assert_api_response :get, 200, path_params: {slug: ship.slug} do
      assert_empty parsed_body["carriedBy"]
    end
  end

  test "GET /models/:slug returns the model" do
    model = create(:model, :with_description, :with_store_image, :with_fleetchart_image)

    assert_api_response :get, 200, path_params: {slug: model.slug}
  end

  test "GET /models/:slug returns 404 for unknown model" do
    assert_api_response :get, 404, path_params: {slug: "unknown-model"}
  end
end
