# frozen_string_literal: true

require "openapi_helper"

class Admin::Api::V1::RafflesTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"admin/v1/schema"

  api_path "/raffles" do
    post("Create Raffle") do
      operationId "createRaffle"
      tags "Raffles"
      consumes "application/json"
      produces "application/json"

      request_body required: true, schema: ::Admin::V1::Schemas::Inputs::RaffleInput

      response(200, "successful") do
        schema ::Admin::V1::Schemas::Raffle
      end

      response(400, "bad request") do
        schema ::Shared::V1::Schemas::ValidationError
      end

      response(403, "forbidden") do
        schema ::Shared::V1::Schemas::StandardError
      end

      response(401, "unauthorized") do
        schema ::Shared::V1::Schemas::StandardError
      end
    end

    get("Raffles list") do
      operationId "raffles"
      tags "Raffles"
      produces "application/json"

      parameter "$ref": "#/components/parameters/PageParameter"
      parameter name: "perPage", in: :query, schema: {type: :string, default: Raffle.default_per_page}, required: false
      parameter "$ref": "#/components/parameters/SortingParameter"
      parameter name: "q", in: :query,
        schema: ::Admin::V1::Schemas::Queries::RaffleQuery,
        style: :deepObject,
        explode: true,
        required: false

      response(200, "successful") do
        schema ::Admin::V1::Schemas::Raffles
      end

      response(403, "forbidden") do
        schema ::Shared::V1::Schemas::StandardError
      end

      response(401, "unauthorized") do
        schema ::Shared::V1::Schemas::StandardError
      end
    end
  end

  api_path "/raffles/{id}" do
    parameter name: "id", in: :path, description: "Raffle id", schema: {type: :string, format: :uuid}

    get("Raffle Detail") do
      operationId "raffle"
      tags "Raffles"
      produces "application/json"

      response(200, "successful") do
        schema ::Admin::V1::Schemas::Raffle
      end

      response(404, "not found") do
        schema ::Shared::V1::Schemas::StandardError
      end

      response(403, "forbidden") do
        schema ::Shared::V1::Schemas::StandardError
      end

      response(401, "unauthorized") do
        schema ::Shared::V1::Schemas::StandardError
      end
    end

    put("Update Raffle") do
      operationId "updateRaffle"
      tags "Raffles"
      consumes "application/json"
      produces "application/json"

      request_body required: true, schema: ::Admin::V1::Schemas::Inputs::RaffleInput

      response(200, "successful") do
        schema ::Admin::V1::Schemas::Raffle
      end

      response(400, "bad request") do
        schema ::Shared::V1::Schemas::ValidationError
      end

      response(404, "not found") do
        schema ::Shared::V1::Schemas::StandardError
      end

      response(403, "forbidden") do
        schema ::Shared::V1::Schemas::StandardError
      end

      response(401, "unauthorized") do
        schema ::Shared::V1::Schemas::StandardError
      end
    end

    delete("Destroy Raffle") do
      operationId "destroyRaffle"
      tags "Raffles"
      produces "application/json"

      response(200, "successful") do
        schema ::Admin::V1::Schemas::Raffle
      end

      response(400, "bad request") do
        schema ::Shared::V1::Schemas::ValidationError
      end

      response(404, "not found") do
        schema ::Shared::V1::Schemas::StandardError
      end

      response(403, "forbidden") do
        schema ::Shared::V1::Schemas::StandardError
      end

      response(401, "unauthorized") do
        schema ::Shared::V1::Schemas::StandardError
      end
    end
  end

  api_path "/raffles/{id}/draw" do
    parameter name: "id", in: :path, description: "Raffle id", schema: {type: :string, format: :uuid}

    post("Draw Raffle") do
      operationId "drawRaffle"
      tags "Raffles"
      produces "application/json"

      response(200, "successful") do
        schema ::Admin::V1::Schemas::Raffle
      end

      response(400, "bad request") do
        schema ::Shared::V1::Schemas::ValidationError
      end

      response(404, "not found") do
        schema ::Shared::V1::Schemas::StandardError
      end

      response(403, "forbidden") do
        schema ::Shared::V1::Schemas::StandardError
      end

      response(401, "unauthorized") do
        schema ::Shared::V1::Schemas::StandardError
      end
    end
  end

  setup do
    @admin = create(:admin_user, resource_access: [:raffles])
  end

  test "POST /raffles creates a raffle without exposing the code" do
    sign_in @admin
    image = ActiveStorage::Blob.create_and_upload!(io: File.open(Rails.root.join("test/fixtures/files/test.png")), filename: "cover.png", content_type: "image/png")

    body = {title: "Win a Polaris", prize: "Anvil Polaris game package", code: "ABCD-EFGH-1234", images: [image.signed_id], startsAt: 1.day.from_now.utc.iso8601, runDays: 7, published: true}

    assert_api_response :post, 200, body: do
      assert_equal "Win a Polaris", parsed_body["title"]
      assert_equal "Anvil Polaris game package", parsed_body["prize"]
      assert_equal ["cover.png"], parsed_body["images"].map { |image| image["name"] }
      assert parsed_body["codeSet"]
      assert_equal 3, parsed_body["claimPeriodDays"]
      assert_equal 7, parsed_body["runDays"]
      assert_includes parsed_body.dig("socialPosts", "start"), "Win a Polaris"
      assert_not_includes response.body, "ABCD-EFGH-1234"
    end
  end

  test "POST /raffles rejects publishing without a code" do
    sign_in @admin

    assert_api_response :post, 400, body: {title: "No code", startsAt: 1.day.from_now.utc.iso8601, runDays: 7, published: true}
  end

  test "POST /raffles returns 401 when not signed in" do
    assert_api_response :post, 401, body: {title: "Test", startsAt: 1.day.from_now.utc.iso8601, runDays: 7}
  end

  test "POST /raffles returns 403 for admin without access" do
    sign_in create(:admin_user, resource_access: [])

    assert_api_response :post, 403, body: {title: "Test", startsAt: 1.day.from_now.utc.iso8601, runDays: 7}
  end

  test "GET /raffles lists raffles" do
    create_list(:raffle, 2)
    sign_in @admin

    assert_api_response :get, 200 do
      assert_equal 2, parsed_body["items"].count
    end
  end

  test "GET /raffles returns 401 when not signed in" do
    assert_api_response :get, 401
  end

  test "GET /raffles returns 403 for admin without access" do
    sign_in create(:admin_user, resource_access: [])

    assert_api_response :get, 403
  end

  test "GET /raffles/:id shows the current winner" do
    raffle = create(:raffle, :closed, drawn_at: 1.hour.ago)
    create(:raffle_entry, :after_close, raffle:, draw_position: 1, won_at: 1.hour.ago, claim_deadline_at: 5.days.from_now)
    sign_in @admin

    assert_api_response :get, 200, path_params: {id: raffle.id} do
      assert_equal "drawn", parsed_body["status"]
      assert_equal 1, parsed_body.dig("currentWinner", "drawPosition")
    end
  end

  test "GET /raffles/:id returns 404 for missing id" do
    sign_in @admin

    assert_api_response :get, 404, path_params: {id: SecureRandom.uuid}
  end

  test "GET /raffles/:id returns 401 when not signed in" do
    assert_api_response :get, 401, path_params: {id: create(:raffle).id}
  end

  test "GET /raffles/:id returns 403 for admin without access" do
    sign_in create(:admin_user, resource_access: [])

    assert_api_response :get, 403, path_params: {id: create(:raffle).id}
  end

  test "PUT /raffles/:id keeps the code when it is left out" do
    raffle = create(:raffle, code: "KEEP-ME")
    sign_in @admin

    assert_api_response :put, 200, path_params: {id: raffle.id}, body: {title: "Renamed", startsAt: raffle.starts_at.utc.iso8601, runDays: raffle.run_days} do
      assert_equal "Renamed", parsed_body["title"]
    end

    assert_equal "KEEP-ME", raffle.reload.code
  end

  test "PUT /raffles/:id replaces the gallery, shown in upload order" do
    raffle = create(:raffle)
    first, second = %w[first.png second.png].each_with_index.map do |filename, index|
      travel(index.minutes) do
        ActiveStorage::Blob.create_and_upload!(io: File.open(Rails.root.join("test/fixtures/files/test.png")), filename:, content_type: "image/png")
      end
    end
    sign_in @admin

    assert_api_response :put, 200, path_params: {id: raffle.id}, body: {title: raffle.title, startsAt: raffle.starts_at.utc.iso8601, runDays: raffle.run_days, images: [first.signed_id, second.signed_id]} do
      assert_equal %w[first.png second.png], parsed_body["images"].map { |image| image["name"] }
    end

    assert_api_response :put, 200, path_params: {id: raffle.id}, body: {title: raffle.title, startsAt: raffle.starts_at.utc.iso8601, runDays: raffle.run_days, images: [second.signed_id]} do
      assert_equal %w[second.png], parsed_body["images"].map { |image| image["name"] }
    end
  end

  test "PUT /raffles/:id replaces the translations" do
    raffle = create(:raffle, translations: {"fr" => {"title" => "Gagnez un Polaris"}})
    sign_in @admin

    body = {
      title: raffle.title, startsAt: raffle.starts_at.utc.iso8601, runDays: raffle.run_days,
      translations: [
        {locale: "de", title: "Gewinne eine Polaris", description: "", prize: "Polaris-Spielpaket"},
        {locale: "zh-CN", title: "赢取北极星"}
      ]
    }

    assert_api_response :put, 200, path_params: {id: raffle.id}, body: do
      assert_equal %w[de zh-CN], parsed_body["translations"].map { |entry| entry["locale"] }
      assert_equal "Gewinne eine Polaris", parsed_body["translations"].first["title"]
      assert_not parsed_body["translations"].first.key?("description")
    end

    assert_equal({"de" => {"title" => "Gewinne eine Polaris", "prize" => "Polaris-Spielpaket"}, "zh-CN" => {"title" => "赢取北极星"}}, raffle.reload.translations)
  end

  test "PUT /raffles/:id keeps the translations when they are left out" do
    raffle = create(:raffle, translations: {"de" => {"title" => "Gewinne eine Polaris"}})
    sign_in @admin

    assert_api_response :put, 200, path_params: {id: raffle.id}, body: {title: "Renamed", startsAt: raffle.starts_at.utc.iso8601, runDays: raffle.run_days}

    assert_equal "Gewinne eine Polaris", raffle.reload.translations.dig("de", "title")
  end

  test "PUT /raffles/:id refuses to change the code after the draw" do
    raffle = create(:raffle, :closed, drawn_at: 1.hour.ago)
    sign_in @admin

    assert_api_response :put, 400, path_params: {id: raffle.id}, body: {title: raffle.title, code: "OTHER", startsAt: raffle.starts_at.utc.iso8601, runDays: raffle.run_days}
  end

  test "PUT /raffles/:id returns 404 for missing id" do
    sign_in @admin

    assert_api_response :put, 404, path_params: {id: SecureRandom.uuid}, body: {title: "Test", startsAt: 1.day.from_now.utc.iso8601, runDays: 7}
  end

  test "PUT /raffles/:id returns 401 when not signed in" do
    assert_api_response :put, 401, path_params: {id: create(:raffle).id}, body: {title: "Test", startsAt: 1.day.from_now.utc.iso8601, runDays: 7}
  end

  test "PUT /raffles/:id returns 403 for admin without access" do
    sign_in create(:admin_user, resource_access: [])

    assert_api_response :put, 403, path_params: {id: create(:raffle).id}, body: {title: "Test", startsAt: 1.day.from_now.utc.iso8601, runDays: 7}
  end

  test "DELETE /raffles/:id destroys a raffle not drawn yet" do
    raffle = create(:raffle)
    sign_in @admin

    assert_api_response :delete, 200, path_params: {id: raffle.id}

    assert_not Raffle.exists?(raffle.id)
  end

  test "DELETE /raffles/:id keeps a drawn raffle" do
    raffle = create(:raffle, :closed, drawn_at: 1.hour.ago)
    sign_in @admin

    assert_api_response :delete, 400, path_params: {id: raffle.id}

    assert Raffle.exists?(raffle.id)
  end

  test "DELETE /raffles/:id returns 404 for missing id" do
    sign_in @admin

    assert_api_response :delete, 404, path_params: {id: SecureRandom.uuid}
  end

  test "DELETE /raffles/:id returns 401 when not signed in" do
    assert_api_response :delete, 401, path_params: {id: create(:raffle).id}
  end

  test "DELETE /raffles/:id returns 403 for admin without access" do
    sign_in create(:admin_user, resource_access: [])

    assert_api_response :delete, 403, path_params: {id: create(:raffle).id}
  end

  test "POST /raffles/:id/draw draws a winner" do
    raffle = create(:raffle)
    create_list(:raffle_entry, 2, raffle:)
    raffle.update_columns(starts_at: 10.days.ago, ends_at: 1.day.ago)
    sign_in @admin

    assert_api_response :post, 200, path_params: {id: raffle.id} do
      assert_equal "drawn", parsed_body["status"]
      assert_equal @admin.username, parsed_body["drawnBy"]
      assert_equal 1, parsed_body.dig("currentWinner", "drawPosition")
    end
  end

  test "POST /raffles/:id/draw refuses an open raffle" do
    raffle = create(:raffle)
    create(:raffle_entry, raffle:)
    sign_in @admin

    assert_api_response :post, 400, path_params: {id: raffle.id}
  end

  test "POST /raffles/:id/draw returns 404 for missing id" do
    sign_in @admin

    assert_api_response :post, 404, path_params: {id: SecureRandom.uuid}
  end

  test "POST /raffles/:id/draw returns 401 when not signed in" do
    assert_api_response :post, 401, path_params: {id: create(:raffle, :closed).id}
  end

  test "POST /raffles/:id/draw returns 403 for admin without access" do
    sign_in create(:admin_user, resource_access: [])

    assert_api_response :post, 403, path_params: {id: create(:raffle, :closed).id}
  end
end
