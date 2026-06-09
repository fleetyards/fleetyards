# frozen_string_literal: true

require_relative "../../test_helper"

class Short::ModelCompareShareTest < ActionDispatch::IntegrationTest
  setup do
    @short_host = Rails.configuration.app.short_domain
    @carrack = create_model_with_slug("anvil-carrack")
    @cutlass = create_model_with_slug("drake-cutlass-black")
  end

  test "redirects a valid short_code to the canonical compare URL" do
    CompareImage.create!(
      slug_set: "anvil-carrack,drake-cutlass-black",
      share_key: "anvil-carrack,drake-cutlass-black",
      short_code: "abcd1234"
    )

    get "/c/abcd1234", headers: {"Host" => @short_host}

    assert_response :found
    assert_includes response.location, "/compare"
    assert_includes response.location, "anvil-carrack"
    assert_includes response.location, "drake-cutlass-black"
  end

  test "redirects unknown short_codes to the bare compare page" do
    get "/c/zzzzzzzz", headers: {"Host" => @short_host}

    assert_response :found
    assert_match(%r{/compare/?\z}, response.location)
  end

  private

  def create_model_with_slug(slug)
    model = create(:model)
    model.update_columns(slug: slug)
    model
  end
end
