# frozen_string_literal: true

# == Schema Information
#
# Table name: supporter_contributions
#
#  id                  :uuid             not null, primary key
#  amount_cents        :integer          not null
#  anonymous           :boolean          default(FALSE), not null
#  currency            :string           default("EUR"), not null
#  ended_at            :date
#  name                :string
#  note                :text
#  recurring           :boolean          default(FALSE), not null
#  source              :string           default("manual"), not null
#  source_amount_cents :integer
#  source_currency     :string
#  started_at          :date             not null
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  patreon_member_id   :string
#  user_id             :uuid
#
# Indexes
#
#  index_supporter_contributions_on_patreon_member_id       (patreon_member_id) UNIQUE WHERE (patreon_member_id IS NOT NULL)
#  index_supporter_contributions_on_recurring_and_ended_at  (recurring,ended_at)
#  index_supporter_contributions_on_started_at              (started_at)
#  index_supporter_contributions_on_user_id                 (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (user_id => users.id)
#
require "test_helper"

class SupporterContributionTest < ActiveSupport::TestCase
  test "requires amount_cents > 0 and started_at; name is optional" do
    refute SupporterContribution.new(amount_cents: 0, started_at: Date.current).valid?
    refute SupporterContribution.new(amount_cents: 100, started_at: nil).valid?
    assert SupporterContribution.new(amount_cents: 100, started_at: Date.current).valid?
    assert SupporterContribution.new(name: nil, amount_cents: 100, started_at: Date.current).valid?
    assert SupporterContribution.new(name: "", amount_cents: 100, started_at: Date.current).valid?
  end

  test "auto-sets anonymous when name is blank" do
    contribution = create(:supporter_contribution, name: nil, anonymous: false)
    assert contribution.anonymous?

    contribution = create(:supporter_contribution, name: "", anonymous: false)
    assert contribution.anonymous?

    contribution = create(:supporter_contribution, name: "Alice", anonymous: false)
    refute contribution.anonymous?
  end

  test "validates ended_at is on or after started_at" do
    record = SupporterContribution.new(
      amount_cents: 100,
      started_at: Date.new(2026, 6, 1),
      ended_at: Date.new(2026, 5, 1)
    )

    refute record.valid?
    assert_includes record.errors[:ended_at], record.errors.generate_message(:ended_at, :must_be_after_started_at)
  end

  test ".active_in includes one-time contributions whose started_at lands in the month" do
    in_month = create(:supporter_contribution, started_at: Date.new(2026, 6, 10))
    before_month = create(:supporter_contribution, started_at: Date.new(2026, 5, 28))
    after_month = create(:supporter_contribution, started_at: Date.new(2026, 7, 1))

    ids = SupporterContribution.active_in(Date.new(2026, 6, 1), Date.new(2026, 6, 30)).pluck(:id)

    assert_includes ids, in_month.id
    refute_includes ids, before_month.id
    refute_includes ids, after_month.id
  end

  test ".active_in includes ongoing recurring contributions that overlap the month" do
    ongoing = create(:supporter_contribution, :recurring, started_at: Date.new(2026, 1, 1))
    ended_before = create(:supporter_contribution, :recurring, started_at: Date.new(2025, 1, 1), ended_at: Date.new(2026, 5, 31))
    ended_during = create(:supporter_contribution, :recurring, started_at: Date.new(2025, 1, 1), ended_at: Date.new(2026, 6, 15))
    starts_after = create(:supporter_contribution, :recurring, started_at: Date.new(2026, 7, 1))

    ids = SupporterContribution.active_in(Date.new(2026, 6, 1), Date.new(2026, 6, 30)).pluck(:id)

    assert_includes ids, ongoing.id
    assert_includes ids, ended_during.id
    refute_includes ids, ended_before.id
    refute_includes ids, starts_after.id
  end

  test ".monthly_total sums amount_cents of active contributions" do
    create(:supporter_contribution, amount_cents: 500, started_at: Date.new(2026, 6, 5))
    create(:supporter_contribution, :recurring, amount_cents: 1_000, started_at: Date.new(2026, 1, 1))
    create(:supporter_contribution, amount_cents: 9_999, started_at: Date.new(2026, 5, 28))

    assert_equal 1_500, SupporterContribution.monthly_total(Date.new(2026, 6, 15))
  end

  test "source defaults to manual" do
    assert_equal "manual", SupporterContribution.new.source
    assert SupporterContribution.new.manual?
  end

  test "rejects a user_id that points at no account" do
    record = SupporterContribution.new(
      amount_cents: 100,
      started_at: Date.current,
      user_id: SecureRandom.uuid
    )

    refute record.valid?
    assert_includes record.errors.attribute_names, :user
  end

  test "a linked contribution keeps a blank name attributable" do
    user = create(:user)
    contribution = create(:supporter_contribution, name: nil, anonymous: false, user:)

    refute contribution.anonymous?
    assert_equal user.username, contribution.public_name
  end

  test "an explicit name wins over the linked username" do
    user = create(:user)
    contribution = create(:supporter_contribution, name: "Alice", user:)

    assert_equal "Alice", contribution.public_name
  end

  test "anonymous withholds both the name and the profile link" do
    user = create(:user, :public_hangar)
    contribution = create(:supporter_contribution, :anonymous, name: "Alice", user:)

    assert_nil contribution.public_name
    assert_nil contribution.public_profile_username
  end

  test "the profile link only points at reachable hangars" do
    public_user = create(:user, :public_hangar)
    private_user = create(:user, :private_hangar)

    assert_equal public_user.username,
      create(:supporter_contribution, user: public_user).public_profile_username
    assert_nil create(:supporter_contribution, user: private_user).public_profile_username
    assert_nil create(:supporter_contribution).public_profile_username
  end

  test ".active_now spans the month around the given date" do
    in_month = create(:supporter_contribution, started_at: Date.new(2026, 6, 10))
    next_month = create(:supporter_contribution, started_at: Date.new(2026, 7, 2))

    ids = SupporterContribution.active_now(Date.new(2026, 6, 15)).pluck(:id)

    assert_includes ids, in_month.id
    refute_includes ids, next_month.id
  end

  test "patreon scope and enum select source-tagged rows" do
    manual = create(:supporter_contribution)
    imported = create(:supporter_contribution, :patreon)

    assert imported.patreon?
    ids = SupporterContribution.patreon.pluck(:id)
    assert_includes ids, imported.id
    refute_includes ids, manual.id
  end
end
