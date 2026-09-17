# frozen_string_literal: true

require "openapi_helper"

class Admin::Api::V1::SupporterContributionsTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"admin/v1/schema"

  api_path "/supporter-contributions" do
    post("Create Supporter Contribution") do
      operationId "createSupporterContribution"
      tags "SupporterContributions"
      consumes "application/json"
      produces "application/json"

      request_body required: true, schema: ::Admin::V1::Schemas::Inputs::SupporterContributionInput

      response(200, "successful") do
        schema ::Admin::V1::Schemas::SupporterContribution
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

    get("Supporter Contributions list") do
      operationId "supporterContributions"
      tags "SupporterContributions"
      produces "application/json"

      parameter "$ref": "#/components/parameters/PageParameter"
      parameter name: "perPage", in: :query, schema: {type: :string, default: SupporterContribution.default_per_page}, required: false
      parameter "$ref": "#/components/parameters/SortingParameter"
      parameter name: "q", in: :query,
        schema: ::Admin::V1::Schemas::Queries::SupporterContributionQuery,
        style: :deepObject,
        explode: true,
        required: false

      response(200, "successful") do
        schema ::Admin::V1::Schemas::SupporterContributions
      end

      response(403, "forbidden") do
        schema ::Shared::V1::Schemas::StandardError
      end

      response(401, "unauthorized") do
        schema ::Shared::V1::Schemas::StandardError
      end
    end
  end

  api_path "/supporter-contributions/{id}" do
    parameter name: "id", in: :path, description: "Supporter Contribution id", schema: {type: :string, format: :uuid}

    delete("Destroy Supporter Contribution") do
      operationId "destroySupporterContribution"
      tags "SupporterContributions"
      produces "application/json"

      response(200, "successful") do
        schema ::Admin::V1::Schemas::SupporterContribution
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

    get("Supporter Contribution Detail") do
      operationId "supporterContribution"
      tags "SupporterContributions"
      produces "application/json"

      response(200, "successful") do
        schema ::Admin::V1::Schemas::SupporterContribution
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

    put("Update Supporter Contribution") do
      operationId "updateSupporterContribution"
      tags "SupporterContributions"
      consumes "application/json"
      produces "application/json"

      request_body required: true, schema: ::Admin::V1::Schemas::Inputs::SupporterContributionInput

      response(200, "successful") do
        schema ::Admin::V1::Schemas::SupporterContribution
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
    @user = create(:admin_user, resource_access: [:supporters])
  end

  test "POST /supporter-contributions creates a contribution" do
    sign_in @user

    body = {name: "Test Supporter", amountCents: 500, startedAt: Date.current.iso8601}

    assert_api_response :post, 200, body: body do
      assert_equal "Test Supporter", parsed_body["name"]
      assert_equal 500, parsed_body["amountCents"]
      assert_equal false, parsed_body["anonymous"]
      assert_equal false, parsed_body["recurring"]
    end
  end

  test "POST /supporter-contributions links the contribution to a user" do
    user = create(:user)
    sign_in @user

    body = {amountCents: 500, startedAt: Date.current.iso8601, userId: user.id}

    assert_api_response :post, 200, body: body do
      assert_equal user.id, parsed_body["userId"]
      assert_equal user.username, parsed_body["user"]["username"]
      assert_equal false, parsed_body["anonymous"]
    end
  end

  # A hand-entered PayPal or Buy Me a Coffee payment resolves the same way a
  # webhook does, so an admin does not have to know who an address belongs to.
  test "POST /supporter-contributions resolves a payer email to its account" do
    donor = create(:user, email: "donor@example.test", confirmed_at: Time.current)
    sign_in @user

    body = {amountCents: 500, startedAt: Date.current.iso8601, payerEmail: "donor@example.test"}

    assert_api_response :post, 200, body: body do
      assert_equal "donor@example.test", parsed_body["payerEmail"]
      assert_equal donor.id, parsed_body["userId"]
    end
  end

  test "POST /supporter-contributions resolves a claim key written in the note" do
    donor = create(:user, confirmed_at: Time.current)
    key = donor.ensure_claim_key!
    sign_in @user

    body = {amountCents: 500, startedAt: Date.current.iso8601, note: "PayPal note: #{key}"}

    assert_api_response :post, 200, body: body do
      assert_equal donor.id, parsed_body["userId"]
    end
  end

  test "POST /supporter-contributions resolves a claim key given in its own field" do
    donor = create(:user, confirmed_at: Time.current)
    key = donor.ensure_claim_key!
    sign_in @user

    body = {amountCents: 500, startedAt: Date.current.iso8601, claimKey: key.downcase}

    assert_api_response :post, 200, body: body do
      assert_equal key, parsed_body["claimKey"]
      assert_equal donor.id, parsed_body["userId"]
      assert_equal "claim_key", parsed_body["linkedVia"]
    end
  end

  # Wrong length rather than wrong characters: SupporterClaimKey accepts a bare
  # eight-character body, so any word that long is key-shaped by design.
  test "POST /supporter-contributions rejects a claim key that is not key-shaped" do
    sign_in @user

    assert_api_response :post, 400,
      body: {amountCents: 500, startedAt: Date.current.iso8601, claimKey: "FY-7K2M-9QX"}
  end

  # A key is worth keeping even when it matches nobody: the donor may not have
  # registered yet, and the later re-run has nowhere else to read it from.
  test "POST /supporter-contributions keeps a claim key matching no account" do
    sign_in @user

    body = {amountCents: 500, startedAt: Date.current.iso8601, claimKey: "FY-7K2M-9QXD"}

    assert_api_response :post, 200, body: body do
      assert_equal "FY-7K2M-9QXD", parsed_body["claimKey"]
      refute parsed_body.key?("userId")
      refute parsed_body.key?("linkedVia")
    end
  end

  test "POST /supporter-contributions records an admin's own choice as manual" do
    user = create(:user)
    sign_in @user

    body = {amountCents: 500, startedAt: Date.current.iso8601, userId: user.id}

    assert_api_response :post, 200, body: body do
      assert_equal "manual", parsed_body["linkedVia"]
    end
  end

  test "POST /supporter-contributions records the platform an admin named" do
    sign_in @user

    body = {amountCents: 500, startedAt: Date.current.iso8601, source: "buymeacoffee"}

    assert_api_response :post, 200, body: body do
      assert_equal "buymeacoffee", parsed_body["source"]
    end
  end

  # An admin who states no platform is not claiming the money came from one --
  # which is why the answer is null rather than `other`. `other` says "a
  # platform, just not one of the named ones", and nobody said that here.
  test "POST /supporter-contributions leaves an unstated platform unspecified" do
    sign_in @user

    body = {amountCents: 500, startedAt: Date.current.iso8601}

    assert_api_response :post, 200, body: body do
      assert_nil parsed_body["source"]
    end
  end

  # A filter the controller does not permit is dropped before ransack sees it,
  # so the list comes back unfiltered while the UI shows a filter applied.
  test "GET /supporter-contributions can separate unspecified from other" do
    unspecified = create(:supporter_contribution, name: "No platform stated")
    stated = create(:supporter_contribution, name: "Stated as other", source: "other")
    sign_in @user

    assert_api_response :get, 200, params: {q: {sourceNull: true}} do
      assert_equal [unspecified.id], parsed_body["items"].map { |row| row["id"] }
    end

    assert_api_response :get, 200, params: {q: {sourceNull: false}} do
      assert_equal [stated.id], parsed_body["items"].map { |row| row["id"] }
    end
  end

  test "POST /supporter-contributions keeps other when an admin states it" do
    sign_in @user

    body = {amountCents: 500, startedAt: Date.current.iso8601, source: "other"}

    assert_api_response :post, 200, body: body do
      assert_equal "other", parsed_body["source"]
    end
  end

  test "POST /supporter-contributions keeps the account an admin chose" do
    chosen = create(:user)
    create(:user, email: "donor@example.test", confirmed_at: Time.current)
    sign_in @user

    body = {amountCents: 500, startedAt: Date.current.iso8601,
            payerEmail: "donor@example.test", userId: chosen.id}

    assert_api_response :post, 200, body: body do
      assert_equal chosen.id, parsed_body["userId"]
    end
  end

  test "POST /supporter-contributions rejects a userId with no account" do
    sign_in @user

    body = {amountCents: 500, startedAt: Date.current.iso8601, userId: SecureRandom.uuid}

    assert_api_response :post, 400, body: body
  end

  test "POST /supporter-contributions returns 401 when not signed in" do
    assert_api_response :post, 401, body: {amountCents: 100, startedAt: Date.current.iso8601}
  end

  test "POST /supporter-contributions returns 403 for admin without access" do
    sign_in create(:admin_user, resource_access: [])

    assert_api_response :post, 403, body: {amountCents: 100, startedAt: Date.current.iso8601}
  end

  test "GET /supporter-contributions lists contributions" do
    create_list(:supporter_contribution, 3)
    sign_in @user

    assert_api_response :get, 200 do
      assert_equal 3, parsed_body["items"].count
    end
  end

  test "GET /supporter-contributions filters by recurringEq" do
    create_list(:supporter_contribution, 2)
    create_list(:supporter_contribution, 3, :recurring)
    sign_in @user

    assert_api_response :get, 200, params: {q: {"recurringEq" => true}} do
      assert_equal 3, parsed_body["items"].count
    end
  end

  test "GET /supporter-contributions filters by userIdEq" do
    user = create(:user)
    create(:supporter_contribution, user:)
    create_list(:supporter_contribution, 2)
    sign_in @user

    assert_api_response :get, 200, params: {q: {"userIdEq" => user.id}} do
      assert_equal 1, parsed_body["items"].count
      assert_equal user.username, parsed_body["items"].first["user"]["username"]
    end
  end

  test "GET /supporter-contributions filters by userUsernameCont" do
    user = create(:user, username: "supporterone")
    create(:supporter_contribution, user:)
    create_list(:supporter_contribution, 2)
    sign_in @user

    assert_api_response :get, 200, params: {q: {"userUsernameCont" => "supporteron"}} do
      assert_equal 1, parsed_body["items"].count
    end
  end

  test "GET /supporter-contributions filters the unlinked ones by userIdNull" do
    create(:supporter_contribution, user: create(:user))
    create_list(:supporter_contribution, 2)
    sign_in @user

    assert_api_response :get, 200, params: {q: {"userIdNull" => true}} do
      assert_equal 2, parsed_body["items"].count
    end
  end

  test "GET /supporter-contributions filters by linkedViaEq" do
    create(:supporter_contribution, user: create(:user), linked_via: :claim_key)
    create(:supporter_contribution, user: create(:user), linked_via: :payer_email)
    create(:supporter_contribution)
    sign_in @user

    assert_api_response :get, 200, params: {q: {"linkedViaEq" => "claim_key"}} do
      assert_equal 1, parsed_body["items"].count
      assert_equal "claim_key", parsed_body["items"].first["linkedVia"]
    end
  end

  test "GET /supporter-contributions filters by sourceEq" do
    create(:supporter_contribution, :paypal)
    create(:supporter_contribution, :buymeacoffee)
    create(:supporter_contribution)
    sign_in @user

    assert_api_response :get, 200, params: {q: {"sourceEq" => "paypal"}} do
      assert_equal 1, parsed_body["items"].count
      assert_equal "paypal", parsed_body["items"].first["source"]
    end
  end

  test "GET /supporter-contributions returns 401 when not signed in" do
    assert_api_response :get, 401
  end

  test "GET /supporter-contributions returns 403 for admin without access" do
    sign_in create(:admin_user, resource_access: [])

    assert_api_response :get, 403
  end

  test "DELETE /supporter-contributions/:id destroys the contribution" do
    contribution = create(:supporter_contribution)
    sign_in @user

    assert_api_response :delete, 200, path_params: {id: contribution.id}
  end

  test "DELETE /supporter-contributions/:id returns 404 for missing id" do
    sign_in @user

    assert_api_response :delete, 404, path_params: {id: SecureRandom.uuid}
  end

  test "DELETE /supporter-contributions/:id returns 401 when not signed in" do
    contribution = create(:supporter_contribution)

    assert_api_response :delete, 401, path_params: {id: contribution.id}
  end

  test "DELETE /supporter-contributions/:id returns 403 for admin without access" do
    contribution = create(:supporter_contribution)
    sign_in create(:admin_user, resource_access: [])

    assert_api_response :delete, 403, path_params: {id: contribution.id}
  end

  test "GET /supporter-contributions/:id returns the contribution" do
    contribution = create(:supporter_contribution)
    sign_in @user

    assert_api_response :get, 200, path_params: {id: contribution.id}
  end

  test "GET /supporter-contributions/:id returns 404 for missing id" do
    sign_in @user

    assert_api_response :get, 404, path_params: {id: SecureRandom.uuid}
  end

  test "GET /supporter-contributions/:id returns 401 when not signed in" do
    contribution = create(:supporter_contribution)

    assert_api_response :get, 401, path_params: {id: contribution.id}
  end

  test "GET /supporter-contributions/:id returns 403 for admin without access" do
    contribution = create(:supporter_contribution)
    sign_in create(:admin_user, resource_access: [])

    assert_api_response :get, 403, path_params: {id: contribution.id}
  end

  test "PUT /supporter-contributions/:id updates the contribution" do
    contribution = create(:supporter_contribution)
    sign_in @user

    assert_api_response :put, 200, path_params: {id: contribution.id}, body: {name: "Updated Name", amountCents: 999, startedAt: Date.current.iso8601} do
      assert_equal "Updated Name", parsed_body["name"]
    end
  end

  test "PUT /supporter-contributions/:id resolves a payer email added later" do
    donor = create(:user, email: "donor@example.test", confirmed_at: Time.current)
    contribution = create(:supporter_contribution)
    sign_in @user

    assert_api_response :put, 200,
      path_params: {id: contribution.id},
      body: {amountCents: contribution.amount_cents,
             startedAt: contribution.started_at.iso8601,
             payerEmail: "donor@example.test"} do
      assert_equal donor.id, parsed_body["userId"]
    end
  end

  # An admin editing payer_email is saying who paid; leaving the entitlement
  # with the previous account is the surprising answer.
  test "PUT /supporter-contributions/:id re-resolves when the payer email is corrected" do
    wrong = create(:user, email: "wrong@example.test", confirmed_at: Time.current)
    right = create(:user, email: "right@example.test", confirmed_at: Time.current)
    contribution = create(:supporter_contribution, payer_email: "wrong@example.test", user: wrong)
    sign_in @user

    assert_api_response :put, 200,
      path_params: {id: contribution.id},
      body: {amountCents: contribution.amount_cents,
             startedAt: contribution.started_at.iso8601,
             payerEmail: "right@example.test"} do
      assert_equal right.id, parsed_body["userId"]
    end
  end

  # The form submits userId on every save, so an admin correcting the address
  # without touching the account select still has to re-resolve.
  test "PUT /supporter-contributions/:id re-resolves when userId is resubmitted unchanged" do
    wrong = create(:user, email: "wrong@example.test", confirmed_at: Time.current)
    right = create(:user, email: "right@example.test", confirmed_at: Time.current)
    contribution = create(:supporter_contribution, payer_email: "wrong@example.test", user: wrong)
    sign_in @user

    assert_api_response :put, 200,
      path_params: {id: contribution.id},
      body: {amountCents: contribution.amount_cents,
             startedAt: contribution.started_at.iso8601,
             payerEmail: "right@example.test",
             userId: wrong.id} do
      assert_equal right.id, parsed_body["userId"]
      assert_equal "payer_email", parsed_body["linkedVia"]
    end
  end

  test "PUT /supporter-contributions/:id re-resolves when the claim key is corrected" do
    wrong = create(:user, confirmed_at: Time.current)
    right = create(:user, confirmed_at: Time.current)
    contribution = create(:supporter_contribution, claim_key: wrong.ensure_claim_key!, user: wrong)
    sign_in @user

    assert_api_response :put, 200,
      path_params: {id: contribution.id},
      body: {amountCents: contribution.amount_cents,
             startedAt: contribution.started_at.iso8601,
             claimKey: right.ensure_claim_key!} do
      assert_equal right.id, parsed_body["userId"]
      assert_equal "claim_key", parsed_body["linkedVia"]
    end
  end

  test "PUT /supporter-contributions/:id keeps a user named in the same request" do
    wrong = create(:user, email: "wrong@example.test", confirmed_at: Time.current)
    chosen = create(:user, confirmed_at: Time.current)
    create(:user, email: "right@example.test", confirmed_at: Time.current)
    contribution = create(:supporter_contribution, payer_email: "wrong@example.test", user: wrong)
    sign_in @user

    assert_api_response :put, 200,
      path_params: {id: contribution.id},
      body: {amountCents: contribution.amount_cents,
             startedAt: contribution.started_at.iso8601,
             payerEmail: "right@example.test",
             userId: chosen.id} do
      assert_equal chosen.id, parsed_body["userId"]
    end
  end

  test "PUT /supporter-contributions/:id clears the link when userId is null" do
    contribution = create(:supporter_contribution, user: create(:user))
    sign_in @user

    body = {amountCents: 500, startedAt: Date.current.iso8601, userId: nil}

    assert_api_response :put, 200, path_params: {id: contribution.id}, body: body do
      refute parsed_body.key?("userId")
      assert_nil contribution.reload.user_id
    end
  end

  # The address still matches, and the linker would happily resolve it again --
  # but an admin who emptied the account select is saying the row does not
  # belong to that account.
  test "PUT /supporter-contributions/:id keeps a contribution an admin unlinked" do
    donor = create(:user, email: "donor@example.test", confirmed_at: Time.current)
    contribution = create(:supporter_contribution, payer_email: "donor@example.test", user: donor)
    sign_in @user

    assert_api_response :put, 200,
      path_params: {id: contribution.id},
      body: {amountCents: contribution.amount_cents,
             startedAt: contribution.started_at.iso8601,
             payerEmail: "donor@example.test",
             userId: nil} do
      refute parsed_body.key?("userId")
      refute parsed_body.key?("linkedVia")
      assert_nil contribution.reload.user_id
    end
  end

  test "PUT /supporter-contributions/:id keeps a contribution unlinked against a matching token" do
    donor = create(:user, confirmed_at: Time.current)
    contribution = create(:supporter_contribution, claim_key: donor.ensure_claim_key!, user: donor)
    sign_in @user

    assert_api_response :put, 200,
      path_params: {id: contribution.id},
      body: {amountCents: contribution.amount_cents,
             startedAt: contribution.started_at.iso8601,
             claimKey: donor.claim_key,
             userId: nil} do
      refute parsed_body.key?("userId")
      assert_nil contribution.reload.user_id
    end
  end

  # Clearing the account and correcting the address in one request: the explicit
  # choice wins, the same way it does when a user is named.
  test "PUT /supporter-contributions/:id does not re-resolve a correction made while unlinking" do
    wrong = create(:user, email: "wrong@example.test", confirmed_at: Time.current)
    create(:user, email: "right@example.test", confirmed_at: Time.current)
    contribution = create(:supporter_contribution, payer_email: "wrong@example.test", user: wrong)
    sign_in @user

    assert_api_response :put, 200,
      path_params: {id: contribution.id},
      body: {amountCents: contribution.amount_cents,
             startedAt: contribution.started_at.iso8601,
             payerEmail: "right@example.test",
             userId: nil} do
      refute parsed_body.key?("userId")
      assert_nil contribution.reload.user_id
    end
  end

  test "PUT /supporter-contributions/:id returns 404 for missing id" do
    sign_in @user

    assert_api_response :put, 404, path_params: {id: SecureRandom.uuid}, body: {amountCents: 100, startedAt: Date.current.iso8601}
  end

  test "PUT /supporter-contributions/:id returns 401 when not signed in" do
    contribution = create(:supporter_contribution)

    assert_api_response :put, 401, path_params: {id: contribution.id}, body: {amountCents: 100, startedAt: Date.current.iso8601}
  end

  test "PUT /supporter-contributions/:id returns 403 for admin without access" do
    contribution = create(:supporter_contribution)
    sign_in create(:admin_user, resource_access: [])

    assert_api_response :put, 403, path_params: {id: contribution.id}, body: {amountCents: 100, startedAt: Date.current.iso8601}
  end
end
