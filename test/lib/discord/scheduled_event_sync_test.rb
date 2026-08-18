# frozen_string_literal: true

require "test_helper"
require "discord/scheduled_event_sync"

module Discord
  class ScheduledEventSyncTest < ActiveSupport::TestCase
    setup do
      @fleet = create(:fleet)
      @setting = @fleet.create_fleet_notification_setting!(
        discord_guild_id: "123456789",
        enabled_in_app_events: FleetNotificationSetting::DEFAULT_IN_APP_EVENTS
      )
      @event = create(:fleet_event, :open,
        fleet: @fleet,
        title: "Strike Op",
        starts_at: 2.days.from_now,
        ends_at: 2.days.from_now + 2.hours)
      @api = mock("Discord::ApiClient")
      ::Discord::ApiClient.stubs(:configured?).returns(true)
      ::Discord::ApiClient.stubs(:new).returns(@api)
    end

    class RunnableTest < ScheduledEventSyncTest
      test "is false when the bot token is missing" do
        ::Discord::ApiClient.stubs(:configured?).returns(false)
        refute ::Discord::ScheduledEventSync.new(@event).runnable?
      end

      test "is false when the fleet has no Discord guild" do
        @setting.update!(discord_guild_id: nil)
        refute ::Discord::ScheduledEventSync.new(@event).runnable?
      end

      test "is true when both are present" do
        assert ::Discord::ScheduledEventSync.new(@event).runnable?
      end
    end

    class UpsertTest < ScheduledEventSyncTest
      test "creates a Discord scheduled event when discord_event_id is missing" do
        @api.expects(:create_guild_scheduled_event)
          .with("123456789", has_entries(name: "Strike Op", privacy_level: 2, entity_type: 3))
          .returns("id" => "999")

        ::Discord::ScheduledEventSync.new(@event).upsert!

        assert_equal "999", @event.reload.discord_event_id
        refute_nil @event.reload.discord_synced_at
      end

      test "uses entity_type voice when a channel is configured" do
        @setting.update!(discord_channel_id: "555")
        @api.expects(:create_guild_scheduled_event)
          .with("123456789", has_entries(entity_type: 2, channel_id: "555"))
          .returns("id" => "999")

        ::Discord::ScheduledEventSync.new(@event).upsert!
      end

      test "patches the existing Discord event when discord_event_id is set" do
        @event.update_column(:discord_event_id, "888")
        @api.expects(:update_guild_scheduled_event)
          .with("123456789", "888", has_entries(name: "Strike Op"))
          .returns("id" => "888")

        ::Discord::ScheduledEventSync.new(@event).upsert!
        assert_equal "888", @event.reload.discord_event_id
      end

      test "marks the event completed when status is cancelled" do
        @event.update!(status: "cancelled")
        @api.expects(:create_guild_scheduled_event)
          .with("123456789", has_entries(status: 4))
          .returns("id" => "999")

        ::Discord::ScheduledEventSync.new(@event).upsert!
      end

      test "resets and retries when Discord 404s a stale event id" do
        @event.update_column(:discord_event_id, "stale")
        call_count = 0
        @api.stubs(:update_guild_scheduled_event).with do
          call_count += 1
          raise ::Discord::ApiClient::Error.new(404, "Unknown event")
        end
        @api.stubs(:create_guild_scheduled_event).returns("id" => "fresh")

        ::Discord::ScheduledEventSync.new(@event).upsert!
        assert_equal "fresh", @event.reload.discord_event_id
        assert_equal 1, call_count
      end
    end

    class DescriptionPayloadTest < ScheduledEventSyncTest
      setup do
        @creator = create(:user, username: "TorlekMaru")
        @starts_at = 2.days.from_now
        @event = create(:fleet_event, :open,
          fleet: @fleet,
          created_by: @creator,
          title: "Strike Op",
          description: "Briefing body.",
          starts_at: @starts_at)
        @captured = {}
        @api.stubs(:create_guild_scheduled_event).with do |_guild, payload|
          @captured.merge!(payload)
          true
        end.returns("id" => "999")
      end

      test "puts the Sesh-style chip line first so it survives the card preview truncation" do
        ::Discord::ScheduledEventSync.new(@event).upsert!
        assert @captured[:description].lines.first.start_with?("🚩 ")
      end

      test "renders the host as a Discord @-mention when the creator linked Discord" do
        create(:omniauth_connection, user: @creator, provider: "discord", uid: "344036297326723073")

        ::Discord::ScheduledEventSync.new(@event).upsert!
        assert_includes @captured[:description], "🚩 <@344036297326723073>"
      end

      test "falls back to the plain handle when Discord isn't linked" do
        ::Discord::ScheduledEventSync.new(@event).upsert!
        assert_includes @captured[:description], "🚩 TorlekMaru"
        refute_includes @captured[:description], "<@"
      end

      test "shows confirmed and interested counts in Sesh's `N (+M)` format" do
        create_list(:fleet_event_signup, 2, fleet_event: @event, fleet_event_slot: nil, status: "confirmed")
        create_list(:fleet_event_signup, 3, fleet_event: @event, fleet_event_slot: nil, status: "interested")
        create(:fleet_event_signup, fleet_event: @event, fleet_event_slot: nil, status: "withdrawn")

        ::Discord::ScheduledEventSync.new(@event).upsert!
        assert_includes @captured[:description], "👥 2 (+3)"
      end

      test "uses Discord's `<t:UNIX:R>` tag for the relative-time chip" do
        ::Discord::ScheduledEventSync.new(@event).upsert!
        assert_includes @captured[:description], "⏳ <t:#{@starts_at.to_i}:R>"
      end

      test "wraps the short URL in <> to suppress Discord's link preview" do
        ::Discord::ScheduledEventSync.new(@event).upsert!
        assert_match %r{\*\*Open in Fleetyards:\*\* <https?://[^>]+/fe/}, @captured[:description]
      end
    end

    class ExternalLocationChipTest < ScheduledEventSyncTest
      setup do
        @event = create(:fleet_event, :open, fleet: @fleet, meetup_location: "Lorville Outpost")
        @captured = {}
        @api.stubs(:create_guild_scheduled_event).with do |_guild, payload|
          @captured.merge!(payload)
          true
        end.returns("id" => "999")
      end

      test "uses the in-game meetup location when set" do
        ::Discord::ScheduledEventSync.new(@event).upsert!
        assert_equal "Lorville Outpost", @captured[:entity_metadata][:location]
      end

      test "falls back to 'Star Citizen' when neither meetup_location nor location is set" do
        @event.update!(meetup_location: nil, location: nil)

        ::Discord::ScheduledEventSync.new(@event).upsert!
        assert_equal "Star Citizen", @captured[:entity_metadata][:location]
      end
    end

    class DeleteTest < ScheduledEventSyncTest
      test "deletes the Discord event and clears local references" do
        @event.update_column(:discord_event_id, "777")
        @api.expects(:delete_guild_scheduled_event).with("123456789", "777")

        ::Discord::ScheduledEventSync.new(@event).delete!
        assert_nil @event.reload.discord_event_id
      end

      test "is a no-op when there is no discord_event_id" do
        @api.expects(:delete_guild_scheduled_event).never
        ::Discord::ScheduledEventSync.new(@event).delete!
      end

      test "swallows 404s when Discord already lost the event" do
        @event.update_column(:discord_event_id, "777")
        @api.stubs(:delete_guild_scheduled_event)
          .raises(::Discord::ApiClient::Error.new(404, "Unknown event"))

        ::Discord::ScheduledEventSync.new(@event).delete!
        assert_nil @event.reload.discord_event_id
      end
    end
  end
end
