# frozen_string_literal: true

require "test_helper"

# Outside test/integration/api/v1 so it adds nothing to the OpenAPI schema.
class FleetDiscordGuildLinkTest < ActionDispatch::IntegrationTest
  GUILD = "100000000000000001"

  setup do
    @admin = create(:user)
    create(:omniauth_connection, user: @admin, provider: "discord", uid: "400000000000000001")
    @fleet = create(:fleet, admins: [@admin])
    sign_in @admin
  end

  def link(guild = GUILD)
    patch "/api/v1/fleets/#{@fleet.slug}/notifications", params: {discordGuildId: guild}, as: :json
  end

  test "a fleet admin who does not run the server cannot link it" do
    ::Discord::GuildManagerCheck.any_instance.stubs(:manager?).returns(false)

    link

    assert_response :bad_request
    assert_equal ["discordGuildId"], response.parsed_body["errors"].map { |error| error["attribute"] }
    assert_nil @fleet.reload.fleet_notification_setting&.discord_guild_id
  end

  test "the check is asked about the linking user's own Discord account" do
    ::Discord::GuildManagerCheck.expects(:new)
      .with(guild_id: GUILD, discord_uid: "400000000000000001")
      .returns(stub(manager?: true))

    link

    assert_response :success
    assert_equal GUILD, @fleet.reload.fleet_notification_setting.discord_guild_id
  end

  test "resending the linked server does not ask Discord again" do
    @fleet.create_fleet_notification_setting!(discord_guild_id: GUILD)
    ::Discord::GuildManagerCheck.expects(:new).never

    link

    assert_response :success
  end

  test "a discarded fleet no longer answers for its server" do
    ::Discord::GuildManagerCheck.any_instance.stubs(:manager?).returns(true)
    old = create(:fleet, created_by: create(:user).id)
    old.create_fleet_notification_setting!(discord_guild_id: GUILD)
    old.discard!

    link

    assert_response :success
    assert_equal [@fleet.id], FleetNotificationSetting.for_guild(GUILD).map(&:fleet_id)
  end
end
