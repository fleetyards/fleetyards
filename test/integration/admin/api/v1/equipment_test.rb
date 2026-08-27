# frozen_string_literal: true

require "openapi_helper"

class Admin::Api::V1::EquipmentTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"admin/v1/schema"

  api_path "/equipment" do
    post("Create Equipment") do
      operationId "createEquipment"
      tags "Equipment"
      consumes "application/json"
      produces "application/json"

      request_body required: true, schema: {"$ref": "#/components/schemas/EquipmentInput"}

      response(200, "successful") do
        schema "$ref": "#/components/schemas/Equipment"
      end

      response(403, "forbidden") do
        schema "$ref": "#/components/schemas/StandardError"
      end

      response(401, "unauthorized") do
        schema "$ref": "#/components/schemas/StandardError"
      end
    end

    get("Equipment list") do
      operationId "equipment"
      tags "Equipment"
      produces "application/json"

      parameter "$ref": "#/components/parameters/PageParameter"
      parameter name: "perPage", in: :query, schema: {type: :string, default: Equipment.default_per_page}, required: false
      parameter "$ref": "#/components/parameters/SortingParameter"
      parameter name: "q", in: :query,
        schema: {"$ref": "#/components/schemas/EquipmentQuery"},
        style: :deepObject,
        explode: true,
        required: false
      parameter name: "cacheId", in: :query, schema: {type: :string}, required: false

      response(200, "successful") do
        schema "$ref": "#/components/schemas/Equipments"
      end

      response(403, "forbidden") do
        schema "$ref": "#/components/schemas/StandardError"
      end

      response(401, "unauthorized") do
        schema "$ref": "#/components/schemas/StandardError"
      end
    end
  end

  api_path "/equipment/{id}" do
    parameter name: "id", in: :path, description: "Equipment id", schema: {type: :string, format: :uuid}, required: true

    delete("Destroy Equipment") do
      operationId "destroyEquipment"
      tags "Equipment"
      produces "application/json"

      response(200, "successful") do
        schema "$ref": "#/components/schemas/Equipment"
      end

      response(404, "not found") do
        schema "$ref": "#/components/schemas/StandardError"
      end

      response(403, "forbidden") do
        schema "$ref": "#/components/schemas/StandardError"
      end

      response(401, "unauthorized") do
        schema "$ref": "#/components/schemas/StandardError"
      end
    end

    get("Equipment Detail") do
      operationId "equipmentDetail"
      tags "Equipment"
      produces "application/json"

      response(200, "successful") do
        schema "$ref": "#/components/schemas/Equipment"
      end

      response(404, "not found") do
        schema "$ref": "#/components/schemas/StandardError"
      end

      response(403, "forbidden") do
        schema "$ref": "#/components/schemas/StandardError"
      end

      response(401, "unauthorized") do
        schema "$ref": "#/components/schemas/StandardError"
      end
    end

    put("Update Equipment") do
      operationId "updateEquipment"
      tags "Equipment"
      consumes "application/json"
      produces "application/json"

      request_body required: true, schema: {"$ref": "#/components/schemas/EquipmentInput"}

      response(200, "successful") do
        schema "$ref": "#/components/schemas/Equipment"
      end

      response(404, "not found") do
        schema "$ref": "#/components/schemas/StandardError"
      end

      response(403, "forbidden") do
        schema "$ref": "#/components/schemas/StandardError"
      end

      response(401, "unauthorized") do
        schema "$ref": "#/components/schemas/StandardError"
      end
    end
  end

  setup do
    @user = create(:admin_user, resource_access: [:equipment])
  end

  # POST /equipment
  test "POST /equipment creates equipment" do
    sign_in @user

    assert_api_response :post, 200, api_path: "/equipment", body: {name: "P4-AR Rifle"} do
      assert_equal "P4-AR Rifle", parsed_body["name"]
    end
  end

  # The schema declares the request body in camelCase and the generated client
  # sends it that way, while the controller permits snake_case. What bridges the
  # two is Middleware::TransformParameters, which decamelizes every request key
  # app-wide -- so multi-word fields have to be asserted, not just `name`, which
  # reads the same in both.
  test "POST /equipment accepts the camelCase fields the schema declares" do
    manufacturer = create(:manufacturer)
    sign_in @user

    body = {
      name: "P4-AR Rifle",
      equipmentType: "weapon",
      itemType: "assault_rifle",
      subType: "Medium",
      weaponClass: "ballistic",
      manufacturerId: manufacturer.id,
      scKey: "test_p4ar_rifle"
    }

    assert_api_response :post, 200, api_path: "/equipment", body: body do
      assert_equal "weapon", parsed_body["equipmentType"]
      assert_equal "assault_rifle", parsed_body["itemType"]
      assert_equal "Medium", parsed_body["subType"]
      assert_equal "ballistic", parsed_body["weaponClass"]
      assert_equal manufacturer.id, parsed_body["manufacturer"]["id"]

      created = Equipment.find(parsed_body["id"])
      assert_equal "test_p4ar_rifle", created.sc_key
    end
  end

  test "POST /equipment returns 401 when not signed in" do
    assert_api_response :post, 401, api_path: "/equipment", body: {name: "x"}
  end

  test "POST /equipment returns 403 for admin without access" do
    sign_in create(:admin_user, resource_access: [])

    assert_api_response :post, 403, api_path: "/equipment", body: {name: "x"}
  end

  # GET /equipment
  test "GET /equipment lists equipment" do
    create_list(:equipment, 2)
    create(:equipment, name: "Custodian SMG")
    sign_in @user

    assert_api_response :get, 200, api_path: "/equipment" do
      assert_equal 3, parsed_body["items"].count
    end
  end

  test "GET /equipment includes hidden equipment" do
    create(:equipment, :hidden, name: "Hidden Rifle")
    sign_in @user

    assert_api_response :get, 200, api_path: "/equipment" do
      items = parsed_body["items"]
      assert_equal 1, items.count
      assert items.first["hidden"]
    end
  end

  test "GET /equipment filters by nameCont query" do
    create_list(:equipment, 2)
    create(:equipment, name: "Custodian SMG")
    sign_in @user

    assert_api_response :get, 200, api_path: "/equipment", params: {q: {"nameCont" => "Custodian"}} do
      items = parsed_body["items"]
      assert_equal 1, items.count
      assert_equal "Custodian SMG", items.first["name"]
    end
  end

  test "GET /equipment filters by equipmentTypeIn query" do
    create(:equipment, name: "Rifle")
    create(:equipment, :attachment, name: "Scope")
    sign_in @user

    assert_api_response :get, 200, api_path: "/equipment", params: {q: {"equipmentTypeIn" => ["weapon_attachment"]}} do
      items = parsed_body["items"]
      assert_equal 1, items.count
      assert_equal "Scope", items.first["name"]
    end
  end

  test "GET /equipment carries the cheapest price of each direction" do
    equipment = create(:equipment, name: "P4-AR")
    create(:item_price, item: equipment, price_type: :buy, price: 1250)
    create(:item_price, item: equipment, price_type: :buy, price: 1400)
    sign_in @user

    assert_api_response :get, 200, api_path: "/equipment" do
      item = parsed_body["items"].first

      assert_in_delta 1250, item["buyPrice"]
      assert_nil item["sellPrice"]
    end
  end

  test "GET /equipment filters by storeImageBlank" do
    create(:equipment, :with_store_image, name: "Karna Rifle")
    create(:equipment, name: "Devastator Shotgun")
    sign_in @user

    assert_api_response :get, 200, api_path: "/equipment", params: {q: {"storeImageBlank" => true}} do
      assert_equal ["Devastator Shotgun"], parsed_body["items"].map { |item| item["name"] }
    end

    assert_api_response :get, 200, api_path: "/equipment", params: {q: {"storeImageBlank" => false}} do
      assert_equal ["Karna Rifle"], parsed_body["items"].map { |item| item["name"] }
    end
  end

  test "GET /equipment filters by a buy price range" do
    cheap = create(:equipment, name: "Pistol")
    create(:item_price, item: cheap, price_type: :buy, price: 200)
    dear = create(:equipment, name: "Railgun")
    create(:item_price, item: dear, price_type: :buy, price: 4000)
    sign_in @user

    query = {q: {"buyPriceGteq" => 1000}}

    assert_api_response :get, 200, api_path: "/equipment", params: query do
      assert_equal ["Railgun"], parsed_body["items"].map { |item| item["name"] }
    end
  end

  # `slot` reaches ransack through a ransacker, which ransack ignores unless the
  # attribute is whitelisted -- the condition is dropped without erroring.
  test "GET /equipment filters by slotIn query" do
    create(:equipment, :armor, name: "Chest Plate", slot: :torso)
    create(:equipment, :armor, name: "Helm", slot: :helmet)
    sign_in @user

    assert_api_response :get, 200, api_path: "/equipment", params: {q: {"slotIn" => ["helmet"]}} do
      items = parsed_body["items"]
      assert_equal 1, items.count
      assert_equal "Helm", items.first["name"]
    end
  end

  # Ransack drops a `name` sort silently because of the model's ransack_alias,
  # so the controller orders by name itself -- assert it actually happens.
  test "GET /equipment sorts by name" do
    create(:equipment, name: "Zeus Rifle")
    create(:equipment, name: "Arrowhead Sniper")
    sign_in @user

    assert_api_response :get, 200, api_path: "/equipment", params: {q: {"sorts" => ["name asc"]}} do
      assert_equal ["Arrowhead Sniper", "Zeus Rifle"], parsed_body["items"].map { |item| item["name"] }
    end
  end

  test "GET /equipment sorts by name descending" do
    create(:equipment, name: "Arrowhead Sniper")
    create(:equipment, name: "Zeus Rifle")
    sign_in @user

    assert_api_response :get, 200, api_path: "/equipment", params: {q: {"sorts" => ["name desc"]}} do
      assert_equal ["Zeus Rifle", "Arrowhead Sniper"], parsed_body["items"].map { |item| item["name"] }
    end
  end

  test "GET /equipment defaults to name ascending" do
    create(:equipment, name: "Zeus Rifle")
    create(:equipment, name: "Arrowhead Sniper")
    sign_in @user

    assert_api_response :get, 200, api_path: "/equipment" do
      assert_equal ["Arrowhead Sniper", "Zeus Rifle"], parsed_body["items"].map { |item| item["name"] }
    end
  end

  test "GET /equipment paginates with perPage" do
    create_list(:equipment, 3)
    sign_in @user

    assert_api_response :get, 200, api_path: "/equipment", params: {perPage: 2} do
      assert_equal 2, parsed_body["items"].count
    end
  end

  test "GET /equipment returns 401 when not signed in" do
    assert_api_response :get, 401, api_path: "/equipment"
  end

  test "GET /equipment returns 403 for admin without access" do
    sign_in create(:admin_user, resource_access: [])

    assert_api_response :get, 403, api_path: "/equipment"
  end

  # DELETE /equipment/:id
  test "DELETE /equipment/:id destroys the equipment" do
    equipment = create(:equipment)
    sign_in @user

    assert_api_response :delete, 200, path_params: {id: equipment.id}
  end

  test "DELETE /equipment/:id returns 404 for missing id" do
    sign_in @user

    assert_api_response :delete, 404, path_params: {id: SecureRandom.uuid}
  end

  test "DELETE /equipment/:id returns 401 when not signed in" do
    equipment = create(:equipment)

    assert_api_response :delete, 401, path_params: {id: equipment.id}
  end

  test "DELETE /equipment/:id returns 403 for admin without access" do
    equipment = create(:equipment)
    sign_in create(:admin_user, resource_access: [])

    assert_api_response :delete, 403, path_params: {id: equipment.id}
  end

  # GET /equipment/:id
  test "GET /equipment/:id returns the equipment" do
    equipment = create(:equipment)
    sign_in @user

    assert_api_response :get, 200, path_params: {id: equipment.id}, api_path: "/equipment/{id}"
  end

  test "GET /equipment/:id returns 404 for missing id" do
    sign_in @user

    assert_api_response :get, 404, path_params: {id: SecureRandom.uuid}, api_path: "/equipment/{id}"
  end

  test "GET /equipment/:id returns 401 when not signed in" do
    equipment = create(:equipment)

    assert_api_response :get, 401, path_params: {id: equipment.id}, api_path: "/equipment/{id}"
  end

  test "GET /equipment/:id returns 403 for admin without access" do
    equipment = create(:equipment)
    sign_in create(:admin_user, resource_access: [])

    assert_api_response :get, 403, path_params: {id: equipment.id}, api_path: "/equipment/{id}"
  end

  # PUT /equipment/:id
  test "PUT /equipment/:id updates the equipment" do
    equipment = create(:equipment)
    sign_in @user

    assert_api_response :put, 200, path_params: {id: equipment.id}, body: {name: "Updated Rifle"} do
      assert_equal "Updated Rifle", parsed_body["name"]
    end
  end

  test "PUT /equipment/:id assigns a manufacturer" do
    equipment = create(:equipment)
    manufacturer = create(:manufacturer)
    sign_in @user

    assert_api_response :put, 200, path_params: {id: equipment.id}, body: {manufacturerId: manufacturer.id} do
      assert_equal manufacturer.id, parsed_body["manufacturer"]["id"]
    end
  end

  test "PUT /equipment/:id toggles hidden" do
    equipment = create(:equipment)
    sign_in @user

    assert_api_response :put, 200, path_params: {id: equipment.id}, body: {hidden: true} do
      assert parsed_body["hidden"]
    end

    assert_predicate equipment.reload, :hidden?
  end

  test "PUT /equipment/:id sets the slot enum" do
    equipment = create(:equipment)
    sign_in @user

    assert_api_response :put, 200, path_params: {id: equipment.id}, body: {slot: "torso"} do
      assert_equal "torso", parsed_body["slot"]
    end
  end

  # slot, coreCompatibility and backpackCompatibility are Rails enums, and
  # assigning an out-of-set value raises ArgumentError rather than failing
  # validation -- a 500 for what is really just a bad field. Enumerating them in
  # EquipmentInput is what prevents that: request validation is enabled in every
  # environment, so the value is rejected before it reaches the model.
  test "PUT /equipment/:id rejects an unknown slot instead of erroring" do
    equipment = create(:equipment, slot: :torso)
    sign_in @user

    put "/admin/api/v1/equipment/#{equipment.id}",
      params: {slot: "nonsense"}.to_json,
      headers: {"Content-Type" => "application/json", "Accept" => "application/json"}

    assert_response :bad_request
    assert_equal "torso", equipment.reload.slot
  end

  test "POST /equipment rejects an unknown coreCompatibility instead of erroring" do
    sign_in @user

    assert_no_difference -> { Equipment.count } do
      post "/admin/api/v1/equipment",
        params: {name: "Rifle", coreCompatibility: "nonsense"}.to_json,
        headers: {"Content-Type" => "application/json", "Accept" => "application/json"}
    end

    assert_response :bad_request
  end

  test "PUT /equipment/:id attaches a store image" do
    equipment = create(:equipment)
    sign_in @user

    blob = ActiveStorage::Blob.create_and_upload!(
      io: Rails.root.join("test/fixtures/files/test.png").open,
      filename: "test.png",
      content_type: "image/png"
    )

    assert_api_response :put, 200, path_params: {id: equipment.id}, body: {storeImage: blob.signed_id} do
      assert parsed_body["storeImage"]["url"].present?
    end

    assert_predicate equipment.reload.store_image, :attached?
  end

  test "PUT /equipment/:id returns 404 for missing id" do
    sign_in @user

    assert_api_response :put, 404, path_params: {id: SecureRandom.uuid}, body: {name: "x"}
  end

  test "PUT /equipment/:id returns 401 when not signed in" do
    equipment = create(:equipment)

    assert_api_response :put, 401, path_params: {id: equipment.id}, body: {name: "x"}
  end

  test "PUT /equipment/:id returns 403 for admin without access" do
    equipment = create(:equipment)
    sign_in create(:admin_user, resource_access: [])

    assert_api_response :put, 403, path_params: {id: equipment.id}, body: {name: "x"}
  end
end
