# frozen_string_literal: true

require "rails_helper"

RSpec.describe "short/model_compare_share", type: :request do
  def create_model_with_slug(slug)
    model = create(:model)
    model.update_columns(slug: slug)
    model
  end

  let(:short_host) { Rails.configuration.app.short_domain }
  let!(:carrack) { create_model_with_slug("anvil-carrack") }
  let!(:cutlass) { create_model_with_slug("drake-cutlass-black") }
  let(:share_record) do
    CompareImage.create!(
      slug_set: "anvil-carrack,drake-cutlass-black",
      share_key: "anvil-carrack,drake-cutlass-black",
      short_code: "abcd1234"
    )
  end

  it "redirects a valid short_code to the canonical compare URL" do
    share_record

    get "/c/abcd1234", headers: {"Host" => short_host}

    expect(response).to have_http_status(:found)
    expect(response.location).to include("/compare")
    expect(response.location).to include("anvil-carrack")
    expect(response.location).to include("drake-cutlass-black")
  end

  it "redirects unknown short_codes to the bare compare page" do
    get "/c/zzzzzzzz", headers: {"Host" => short_host}

    expect(response).to have_http_status(:found)
    expect(response.location).to match(%r{/compare/?\z})
  end
end
