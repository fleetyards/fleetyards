# frozen_string_literal: true

require "test_helper"

class FleetNotificationSettingDiscordIdsTest < ActiveSupport::TestCase
  setup do
    @setting = create(:fleet).create_fleet_notification_setting!
  end

  test "rejects a server's name where its id belongs" do
    FleetNotificationSetting::DISCORD_ID_ATTRIBUTES.each do |attribute|
      @setting.assign_attributes(attribute => "Stanton Haulers [SHL]")

      assert_not @setting.valid?, "#{attribute} accepted a name"
      assert_includes @setting.errors[attribute], I18n.t("activerecord.errors.models.fleet_notification_setting.not_a_discord_id")

      @setting.restore_attributes
    end
  end

  test "accepts an id and strips the whitespace a paste brings along" do
    @setting.update!(discord_guild_id: " 123456789012345678\n", discord_member_role_id: "234567890123456789")

    assert_equal "123456789012345678", @setting.discord_guild_id
  end

  test "stores a cleared id as nil" do
    @setting.update!(discord_guild_id: "123456789012345678")
    @setting.update!(discord_guild_id: "")

    assert_nil @setting.discord_guild_id
  end
end
