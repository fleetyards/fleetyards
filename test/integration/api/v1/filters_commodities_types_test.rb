# frozen_string_literal: true

require "openapi_helper"

class Api::V1::FiltersCommoditiesTypesTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/filters/commodities/types" do
    get("Commodity Types Filters") do
      operationId "commodityTypesFilters"
      tags "CommoditiesFilters"
      produces "application/json"

      response(200, "successful") do
        schema ::Shared::V1::Schemas::FilterOptionsList
      end
    end
  end

  setup do
    create(:commodity, commodity_type: "metal")
    create(:commodity, commodity_type: "metal")
    create(:commodity, commodity_type: "consumer_goods")
  end

  test "GET /filters/commodities/types returns one option per type" do
    assert_api_response :get, 200 do
      assert_equal %w[consumer_goods metal], parsed_body.map { |filter| filter["value"] }
      assert_equal "commodity_type", parsed_body.first["category"]
    end
  end

  test "GET /filters/commodities/types falls back to the raw value without a translation" do
    create(:commodity, commodity_type: "newfangledgoo")

    assert_api_response :get, 200 do
      option = parsed_body.find { |filter| filter["value"] == "newfangledgoo" }

      assert_equal "Newfangledgoo", option["label"]
    end
  end

  # Until this branch `filter.commodity.*` existed in no locale at all, so every
  # one of the 21 types fell through to `titleize` -- and the public API sets the
  # locale from `Accept-Language`, so a German client read the whole facet in
  # English. Asserted per locale rather than per type, because the failure mode
  # is a locale file that was never filled in, not one label that was missed.
  test "every commodity type is labelled in every locale" do
    I18n.available_locales.each do |locale|
      I18n.with_locale(locale) do
        untranslated = Commodity::TYPES.reject do |type|
          I18n.exists?("filter.commodity.commodity_type.items.#{type}")
        end

        assert_empty untranslated,
          "#{locale} has no label for #{untranslated.join(", ")}, so the facet falls back to English"
      end
    end
  end

  test "GET /filters/commodities/types labels a type in the language asked for" do
    assert_api_response :get, 200, headers: {"Accept-Language" => "de"} do
      option = parsed_body.find { |filter| filter["value"] == "consumer_goods" }

      assert_equal "Konsumgüter", option["label"]
    end

    # The test process reuses its thread the way Puma does, so a locale the
    # request left behind would reach whichever test runs next.
    assert_equal I18n.default_locale, I18n.locale
  end

  test "GET /filters/commodities/types skips commodities without a type" do
    create(:commodity, commodity_type: nil)

    assert_api_response :get, 200 do
      assert_equal %w[consumer_goods metal], parsed_body.map { |filter| filter["value"] }
    end
  end
end
