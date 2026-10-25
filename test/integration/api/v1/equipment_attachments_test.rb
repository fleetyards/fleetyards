# frozen_string_literal: true

require "openapi_helper"

class Api::V1::EquipmentAttachmentsTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/equipment/{slug}/attachments" do
    parameter name: :slug, in: :path, schema: {type: :string}, required: true

    get("Attachments that fit an equipment item") do
      operationId "equipmentItemAttachments"
      tags "Equipment"
      produces "application/json"

      response(200, "successful") do
        schema "$ref": "#/components/schemas/EquipmentAttachmentsList"
      end

      response(404, "not found") do
        schema ::Shared::V1::Schemas::StandardError
      end
    end
  end

  setup do
    @rifle = create(:equipment, name: "Gallant Rifle", sc_key: "klwe_rifle_energy_01")
    build = @rifle.builds.sole

    battery = attachment("Gallant Rifle Battery", "klwe_rifle_energy_01_mag", "Magazine")
    flashlight = attachment("FieldLite Flashlight", "lglt_flashlight_01", "BottomAttachment", family_key: "lglt_flashlight_01")
    red = attachment("FieldLite Flashlight Red", "lglt_flashlight_01_red", "BottomAttachment", family_key: "lglt_flashlight_01")
    sight = attachment("Gamma (1x Holographic)", "lbco_optics_holo_x1_s1", "IronSight")
    hidden = attachment("Gamma Placeholder", "lbco_optics_holo_x1_s1_test", "IronSight", hidden: true)

    create(:equipment_attachment, build:, attachment: battery, port_type: "Magazine", default: true)
    [flashlight, red].each { |light| create(:equipment_attachment, build:, attachment: light, port_name: "underbarrel_attach", port_type: "BottomAttachment") }
    [sight, hidden].each { |optic| create(:equipment_attachment, build:, attachment: optic, port_name: "optics_attach", port_type: "IronSight") }
  end

  test "GET /equipment/{slug}/attachments puts ports it has no place for after the rest, by name" do
    build = @rifle.builds.sole
    %w[Zeta Alpha Mid].each_with_index do |port_type, index|
      create(:equipment_attachment, build:, attachment: attachment("#{port_type} Module", "grin_module_#{index}", port_type),
        port_name: "#{port_type.downcase}_attach", port_type:)
    end

    assert_api_response :get, 200, path_params: {slug: @rifle.slug} do
      unknown = parsed_body.pluck("portType") - %w[Magazine IronSight Barrel BottomAttachment]

      assert_equal %w[Alpha Mid Zeta], unknown
    end
  end

  test "GET /equipment/{slug}/attachments lists one of each family per port, default first" do
    assert_api_response :get, 200, path_params: {slug: @rifle.slug} do
      assert_equal [
        ["Magazine", true, "Gallant Rifle Battery"],
        ["IronSight", false, "Gamma (1x Holographic)"],
        ["BottomAttachment", false, "FieldLite Flashlight"]
      ], parsed_body.map { |fit| [fit["portType"], fit["default"], fit.dig("attachment", "name")] }
    end
  end

  test "GET /equipment/{slug}/attachments returns 404 for an unknown item" do
    assert_api_response :get, 404, path_params: {slug: "nope-nope"}
  end

  private def attachment(name, sc_key, sub_type, **)
    create(:equipment, name:, sc_key:, sub_type:, equipment_type: "weapon_attachment", item_type: nil, size: "1", **)
  end
end
