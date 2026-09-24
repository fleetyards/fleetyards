# frozen_string_literal: true

# == Schema Information
#
# Table name: fleets
#
#  id                        :uuid             not null, primary key
#  allies_fleet              :boolean          default(FALSE), not null
#  allies_fleet_members      :boolean          default(FALSE), not null
#  allies_fleet_stats        :boolean          default(FALSE), not null
#  calendar_feed_token       :string
#  created_by                :uuid
#  default_timezone          :string           default("UTC"), not null
#  description               :text
#  discarded_at              :datetime
#  discord                   :string
#  fid                       :string
#  guilded                   :string
#  homepage                  :string
#  inventory_transfer_policy :integer          default("everyone"), not null
#  name                      :string
#  normalized_fid            :string
#  public_fleet              :boolean          default(FALSE)
#  public_fleet_stats        :boolean          default(FALSE)
#  rsi_sid                   :string
#  sid                       :string
#  slug                      :string
#  transfers_blocked_at      :datetime
#  transfers_blocked_reason  :text
#  ts                        :string
#  twitch                    :string
#  youtube                   :string
#  created_at                :datetime         not null
#  updated_at                :datetime         not null
#
# Indexes
#
#  index_fleets_on_calendar_feed_token  (calendar_feed_token) UNIQUE
#  index_fleets_on_discarded_at         (discarded_at)
#  index_fleets_on_fid                  (fid) UNIQUE WHERE (discarded_at IS NULL)
#
require "test_helper"

class FleetTest < ActiveSupport::TestCase
  test "#setup_default_roles! creates 3 default roles on fleet creation" do
    fleet = create(:fleet)
    assert_equal 3, fleet.fleet_roles.count
  end

  test "#default_member_role returns the last ranked role" do
    fleet = create(:fleet)
    assert_equal "Member", fleet.default_member_role.name
  end

  test "#default_member_role creates roles if none exist" do
    fleet = create(:fleet)
    fleet.fleet_roles.destroy_all
    assert_equal 0, fleet.fleet_roles.reload.count

    role = fleet.default_member_role

    assert_equal "Member", role.name
    assert_equal 3, fleet.fleet_roles.reload.count
  end

  # A fleet is touched by seven of its children, and rails' `touch` skips
  # dirty-tracking -- so paper_trail files the version with no `object_changes`
  # at all. Those are the ones the admin history showed as an empty heading.
  class VersioningTest < FleetTest
    setup do
      @fleet = create(:fleet, created_by: create(:user).id)
    end

    test "a touch records no version" do
      assert_no_difference -> { @fleet.versions.count } do
        @fleet.touch
      end
    end

    test "a child write that touches the fleet records no fleet version" do
      assert_no_difference -> { @fleet.versions.count } do
        @fleet.fleet_roles.first.update!(name: "Quartermaster")
      end
    end

    test "a real edit still records a version with its changes" do
      assert_difference -> { @fleet.versions.count }, 1 do
        @fleet.update!(description: "A crew")
      end

      assert_equal [nil, "A crew"], @fleet.versions.last.changeset["description"]
    end
  end

  class UrlValidationTest < FleetTest
    setup do
      user = create(:user)
      @fleet = create(:fleet, created_by: user.id)
    end

    %w[guilded homepage discord twitch youtube].each do |field|
      test "strips protocol from #{field} url" do
        @fleet.update!(field => "https://foo.bar")
        @fleet.reload
        assert_equal "foo.bar", @fleet.send(field)
      end

      test "strips double slashes from #{field} url" do
        @fleet.update!(field => "//foo.bar")
        @fleet.reload
        assert_equal "foo.bar", @fleet.send(field)
      end
    end

    test "adds ts3server protocol to ts url" do
      @fleet.update!(ts: "foo.bar")
      @fleet.reload
      assert_equal "ts3server://foo.bar", @fleet.ts
    end

    test "replaces http with ts3server for ts url" do
      @fleet.update!(ts: "http://foo.bar")
      @fleet.reload
      assert_equal "ts3server://foo.bar", @fleet.ts
    end

    test "replaces https with ts3server for ts url" do
      @fleet.update!(ts: "https://foo.bar")
      @fleet.reload
      assert_equal "ts3server://foo.bar", @fleet.ts
    end
  end
  test "subscribed? follows the record rather than a stored state" do
    fleet = create(:fleet)

    refute fleet.subscribed?

    create(:fleet_subscription, fleet:)

    assert Fleet.find(fleet.id).subscribed?
  end

  # Lapse is a read, not a job: no sweep runs, no column is written, and the
  # next request simply stops granting.
  test "a lapsed subscription stops granting with nothing having run" do
    fleet = create(:fleet)
    create(:fleet_subscription, fleet:, started_at: 2.months.ago.to_date, ended_at: 1.day.ago.to_date)

    refute Fleet.find(fleet.id).subscribed?
  end

  test "subscribed? answers per date" do
    fleet = create(:fleet)
    create(:fleet_subscription, fleet:, started_at: Date.current - 10, ended_at: Date.current - 5)

    refute fleet.subscribed?
    assert fleet.subscribed?(Date.current - 7)
  end

  # `#features` iterates every flag in the registry, and Frontend::BaseController
  # does the same per request. An entitlement read reached from inside either
  # loop would multiply by the flag count, so it is memoised -- asserted here
  # rather than left to inspection.
  test "subscribed? issues one query however many times it is asked" do
    fleet = create(:fleet)
    create(:fleet_subscription, fleet:)
    subject = Fleet.find(fleet.id)

    queries = count_queries { 10.times { subject.subscribed? } }

    assert_equal 1, queries, "expected one query, got #{queries}"
  end

  # The memo answers for the life of the instance, so a write has to say so --
  # otherwise the fleet that already asked keeps granting after it lapsed.
  test "a subscription write clears the memo on the fleet it belongs to" do
    fleet = create(:fleet)
    subscription = create(:fleet_subscription, fleet:)
    subject = Fleet.find(fleet.id)

    assert subject.subscribed?

    subscription.fleet = subject
    subscription.update!(started_at: Date.current - 10, ended_at: Date.current - 1)

    refute subject.subscribed?, "the memo outlived the row it was reading"
  end

  test "reload clears the memo" do
    fleet = create(:fleet)
    subscription = create(:fleet_subscription, fleet:)
    subject = Fleet.find(fleet.id)

    assert subject.subscribed?

    FleetSubscription.where(id: subscription.id)
      .update_all(started_at: Date.current - 10, ended_at: Date.current - 1)

    assert subject.subscribed?, "still memoised, which is the documented contract"
    refute subject.reload.subscribed?
  end

  test "active_subscription is memoised the same way" do
    fleet = create(:fleet)
    create(:fleet_subscription, fleet:)
    subject = Fleet.find(fleet.id)

    queries = count_queries { 10.times { subject.active_subscription } }

    assert_equal 1, queries, "expected one query, got #{queries}"
  end

  test "a full feature listing is not multiplied by the entitlement read" do
    fleet = create(:fleet)
    create(:fleet_subscription, fleet:)
    subject = Fleet.find(fleet.id)

    before = count_queries { subject.features }
    subject.subscribed?
    after = count_queries { subject.features }

    assert_equal before, after,
      "listing features must not issue more queries once a subscription exists"
  end

  private def count_queries(&block)
    count = 0
    counter = ->(_name, _start, _finish, _id, payload) {
      count += 1 unless payload[:name].in?(%w[CACHE SCHEMA TRANSACTION])
    }
    ActiveSupport::Notifications.subscribed(counter, "sql.active_record", &block)
    count
  end
  # A list of fleets renders `subscribed` for each, so the read has to answer
  # from an eager-loaded association rather than querying per row.
  test "subscribed? answers from a loaded association without querying" do
    fleet = create(:fleet)
    create(:fleet_subscription, fleet:)
    loaded = Fleet.includes(:fleet_subscriptions).find(fleet.id)

    queries = count_queries { assert loaded.subscribed? }

    assert_equal 0, queries, "expected no query, got #{queries}"
  end

  test "active_subscription does the same" do
    fleet = create(:fleet)
    subscription = create(:fleet_subscription, fleet:)
    loaded = Fleet.includes(:fleet_subscriptions).find(fleet.id)

    queries = count_queries { assert_equal subscription, loaded.active_subscription }

    assert_equal 0, queries
  end

  test "a loaded association still answers false when nothing is active" do
    fleet = create(:fleet)
    create(:fleet_subscription, fleet:, started_at: Date.current - 30, ended_at: Date.current - 1)
    loaded = Fleet.includes(:fleet_subscriptions).find(fleet.id)

    refute loaded.subscribed?
  end

  # The form draws the same number as a running count, so the two have to agree
  # on where the limit is.
  class DescriptionLengthTest < FleetTest
    setup do
      @fleet = create(:fleet, created_by: create(:user).id)
    end

    test "a description is accepted up to 10000 characters" do
      assert @fleet.update(description: "a" * 10_000),
        @fleet.errors.full_messages.to_sentence
    end

    test "a longer description is refused" do
      refute @fleet.update(description: "a" * 10_001)
      assert_includes @fleet.errors.details[:description].pluck(:error), :too_long
    end
  end
end
