# frozen_string_literal: true

require "openapi_helper"

class Api::V1::ComponentsChangesTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/components/{slug}/changes" do
    parameter name: "slug", in: :path, schema: {type: :string}, description: "Component slug", required: true

    get("Component Changes") do
      operationId "componentChanges"
      tags "Components"
      produces "application/json"

      response(200, "successful") do
        schema ::V1::Schemas::Components::Changes::ComponentBuildChangesList
      end

      response(404, "not found") do
        schema ::Shared::V1::Schemas::StandardError
      end
    end
  end

  test "GET /components/:slug/changes returns the newest patch first" do
    component = create(:component)
    record(component, field: "size", to_version: "4.9.0", recorded_at: 3.months.ago)
    record(component, field: "grade", to_version: "4.10.0", recorded_at: 1.day.ago)

    assert_api_response :get, 200, path_params: {slug: component.slug} do
      assert_equal %w[grade size], parsed_body.map { |change| change["field"] }
    end
  end

  test "GET /components/:slug/changes leaves out other components" do
    component = create(:component)
    record(component, field: "grade")
    record(create(:component), field: "size")

    assert_api_response :get, 200, path_params: {slug: component.slug} do
      assert_equal %w[grade], parsed_body.map { |change| change["field"] }
    end
  end

  # The prefix is how the log keeps a `typeData` key apart from a column of the
  # same name. It is storage: the payload says `metric` and spells the field the
  # way `typeData` does, so a reader can label it from the key it already knows.
  test "GET /components/:slug/changes says which rows are typeData figures" do
    component = create(:component)
    record(component, field: "type_data.damage_per_shot", old_value: "120", new_value: "140")

    assert_api_response :get, 200, path_params: {slug: component.slug} do
      change = parsed_body.sole

      assert_equal "damage_per_shot", change["field"]
      assert change["metric"]
    end
  end

  test "GET /components/:slug/changes marks a build fact as not a metric" do
    component = create(:component)
    record(component, field: "size")

    assert_api_response :get, 200, path_params: {slug: component.slug} do
      assert_not parsed_body.sole["metric"]
    end
  end

  # A fact the previous build did not carry has no old value, and null is the
  # honest answer rather than an empty string.
  test "GET /components/:slug/changes reports a fact that was not there before" do
    component = create(:component)
    record(component, field: "grade", old_value: nil, new_value: "A")

    assert_api_response :get, 200, path_params: {slug: component.slug} do
      assert_nil parsed_body.sole["oldValue"]
      assert_equal "A", parsed_body.sole["newValue"]
    end
  end

  test "GET /components/:slug/changes answers for a component no patch has changed" do
    component = create(:component)

    assert_api_response :get, 200, path_params: {slug: component.slug} do
      assert_empty parsed_body
    end
  end

  test "GET /components/:slug/changes 404s for a slug nobody has" do
    assert_api_response :get, 404, path_params: {slug: "no-such-component"}
  end

  private def record(component, field:, to_version: "4.10.0", old_value: "1", new_value: "2", recorded_at: 1.day.ago)
    ComponentBuildChange.create!(
      component:, field:, to_version:, old_value:, new_value:, recorded_at:,
      environment: ScData::Source.environment, from_version: "4.9.0"
    )
  end
end
