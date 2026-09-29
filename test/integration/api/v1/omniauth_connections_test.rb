# frozen_string_literal: true

require "openapi_helper"

class Api::V1::OmniauthConnectionsTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/omniauth-connections/{provider}" do
    parameter name: :provider, in: :path, schema: {type: :string}, required: true

    delete("Disconnect OAuth provider") do
      operationId "disconnectOauthProvider"
      tags "OmniAuth Connections"
      produces "application/json"

      security [{SessionCookie: []}]

      response(200, "successful") do
        schema ::V1::Schemas::User
      end

      response(401, "unauthorized") do
        schema ::Shared::V1::Schemas::StandardError
      end

      response(403, "forbidden - last connection for oauth-only user") do
        schema ::Shared::V1::Schemas::StandardError
      end
    end
  end

  test "DELETE /omniauth-connections/:provider disconnects the provider" do
    user = create(:user, password: "enterprise", password_set_manually: true)
    create(:omniauth_connection, user: user, provider: :discord)
    sign_in user

    assert_api_response :delete, 200, path_params: {provider: "discord"}

    assert_equal 0, user.reload.omniauth_connections.count
  end

  test "DELETE /omniauth-connections/discord revokes the fleet roles of the unlinked account" do
    user = create(:user, password: "enterprise", password_set_manually: true)
    create(:omniauth_connection, user: user, provider: :discord, uid: "discord-uid-unlinked")
    fleet = create(:fleet)
    fleet.fleet_memberships.create!(user: user, fleet_role: fleet.fleet_roles.ranked.last)
    sign_in user
    ::Discord::RevokeMemberRolesJob.jobs.clear

    assert_api_response :delete, 200, path_params: {provider: "discord"}

    assert_equal [["discord-uid-unlinked", [fleet.id]]], ::Discord::RevokeMemberRolesJob.jobs.map { |job| job["args"] }
  end

  test "DELETE /omniauth-connections/:provider returns 401 when not signed in" do
    assert_api_response :delete, 401, path_params: {provider: "discord"}
  end

  test "DELETE /omniauth-connections/:provider returns 403 when removing last connection of oauth-only user" do
    user = create(:user, :oauth_only)
    sign_in user

    assert_api_response :delete, 403, path_params: {provider: user.omniauth_connections.first.provider}
  end

  test "DELETE /omniauth-connections/citizenid clears a handle Citizen iD verified" do
    user = create(:user, password: "enterprise", password_set_manually: true)
    create(:omniauth_connection, user: user, provider: :citizenid, uid: "citizen-uid")
    user.verify_rsi_handle("TestPilot", via: :citizenid)
    user.save!
    sign_in user

    assert_api_response :delete, 200, path_params: {provider: "citizenid"}

    assert_not user.reload.rsi_handle_verified?
  end

  test "DELETE /omniauth-connections/citizenid keeps a handle proved through the RSI bio" do
    user = create(:user, password: "enterprise", password_set_manually: true)
    create(:omniauth_connection, user: user, provider: :citizenid, uid: "citizen-uid")
    user.verify_rsi_handle("TestPilot", via: :rsi_profile)
    user.save!
    sign_in user

    assert_api_response :delete, 200, path_params: {provider: "citizenid"}

    assert user.reload.rsi_handle_verified_via_rsi_profile?
  end

  test "DELETE /omniauth-connections/citizenid clears the memberships of a handle Citizen iD verified" do
    user = create(:user, password: "enterprise", password_set_manually: true)
    create(:omniauth_connection, user: user, provider: :citizenid, uid: "citizen-uid")
    user.verify_rsi_handle("TestPilot", via: :citizenid)
    user.save!
    user.store_rsi_organizations(%w[MAIN], read_at: Time.current)
    membership = create(:fleet, rsi_sid: "MAIN", members: [user]).fleet_memberships.find_by(user:)
    sign_in user

    assert_api_response :delete, 200, path_params: {provider: "citizenid"}

    assert_not membership.reload.verified?
  end

  test "DELETE /omniauth-connections/citizenid keeps the memberships of a handle the bio verified" do
    user = create(:user, password: "enterprise", password_set_manually: true)
    create(:omniauth_connection, user: user, provider: :citizenid, uid: "citizen-uid")
    user.verify_rsi_handle("TestPilot", via: :rsi_profile)
    user.save!
    user.store_rsi_organizations(%w[MAIN], read_at: Time.current)
    membership = create(:fleet, rsi_sid: "MAIN", members: [user]).fleet_memberships.find_by(user:)
    sign_in user

    assert_api_response :delete, 200, path_params: {provider: "citizenid"}

    assert membership.reload.verified?
  end
end
