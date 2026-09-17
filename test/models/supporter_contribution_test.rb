# frozen_string_literal: true

# == Schema Information
#
# Table name: supporter_contributions
#
#  id                  :uuid             not null, primary key
#  amount_cents        :integer          not null
#  anonymous           :boolean          default(FALSE), not null
#  claim_key           :string
#  currency            :string           default("EUR"), not null
#  ended_at            :date
#  linked_via          :string
#  name                :string
#  note                :text
#  payer_email         :string
#  recurring           :boolean          default(FALSE), not null
#  source              :string           default("other"), not null
#  source_amount_cents :integer
#  source_currency     :string
#  started_at          :date             not null
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  kofi_transaction_id :string
#  patreon_member_id   :string
#  patreon_user_id     :string
#  user_id             :uuid
#
# Indexes
#
#  index_supporter_contributions_on_kofi_transaction_id     (kofi_transaction_id) UNIQUE WHERE (kofi_transaction_id IS NOT NULL)
#  index_supporter_contributions_on_linked_via              (linked_via) WHERE (linked_via IS NOT NULL)
#  index_supporter_contributions_on_patreon_member_id       (patreon_member_id) UNIQUE WHERE (patreon_member_id IS NOT NULL)
#  index_supporter_contributions_on_patreon_user_id         (patreon_user_id) WHERE (patreon_user_id IS NOT NULL)
#  index_supporter_contributions_on_payer_email             (payer_email) WHERE (payer_email IS NOT NULL)
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

  test "normalizes a claim key however it was typed" do
    contribution = create(:supporter_contribution, claim_key: " fy7k2m9qxd ")

    assert_equal "FY-7K2M-9QXD", contribution.claim_key
  end

  # The characters the alphabet leaves out are folded on the way in, so a key
  # read off a screen and retyped still lands on its canonical form.
  test "folds the ambiguous characters in a claim key" do
    contribution = create(:supporter_contribution, claim_key: "FY-7KLM-9QXO")

    assert_equal "FY-7K1M-9QX0", contribution.claim_key
  end

  # Left as entered rather than normalized away: silently blanking a typo is the
  # failure a field of its own exists to avoid.
  test "rejects a claim key that is not key-shaped" do
    contribution = build(:supporter_contribution, claim_key: "FY-7K2M-9QX")

    refute contribution.valid?
    assert_includes contribution.errors[:claim_key], contribution.errors.generate_message(:claim_key, :invalid)
  end

  test "treats a blank claim key as absent" do
    assert create(:supporter_contribution, claim_key: "  ").claim_key.nil?
  end

  test "#claim_key_for_linking falls back to a key written in the note" do
    contribution = build(:supporter_contribution, note: "thanks! FY-7K2M-9QXD")

    assert_equal "FY-7K2M-9QXD", contribution.claim_key_for_linking
  end

  test "#claim_key_for_linking prefers the field an admin filled in" do
    contribution = build(:supporter_contribution, claim_key: "FY-ABCD-EFGH", note: "thanks! FY-7K2M-9QXD")

    assert_equal "FY-ABCD-EFGH", contribution.claim_key_for_linking
  end

  test "records an unexplained link as manual" do
    contribution = create(:supporter_contribution, user: create(:user))

    assert_equal "manual", contribution.linked_via
  end

  test "keeps the rule when the link and the rule are written together" do
    contribution = create(:supporter_contribution)
    contribution.update!(user: create(:user), linked_via: :payer_email)

    assert_equal "payer_email", contribution.reload.linked_via
  end

  test "clears the rule when the link is removed" do
    contribution = create(:supporter_contribution)
    contribution.update!(user: create(:user), linked_via: :claim_key)

    contribution.update!(user: nil)

    assert_nil contribution.reload.linked_via
  end

  test "source defaults to other" do
    assert_equal "other", SupporterContribution.new.source
    assert SupporterContribution.new.other?
  end

  test "source names every platform a contribution can arrive on" do
    assert_equal %w[patreon kofi buymeacoffee paypal other], SupporterContribution.sources.keys
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
    elsewhere = create(:supporter_contribution, source: "paypal")
    imported = create(:supporter_contribution, :patreon)

    assert imported.patreon?
    ids = SupporterContribution.patreon.pluck(:id)
    assert_includes ids, imported.id
    refute_includes ids, elsewhere.id
  end

  test "a one-off runs to the end of the month it arrived in" do
    contribution = create(:supporter_contribution, started_at: Date.new(2026, 6, 10))

    assert_equal Date.new(2026, 6, 30), contribution.active_until
  end

  test "an open-ended recurring pledge has no last day" do
    contribution = create(:supporter_contribution, :recurring)

    assert_nil contribution.active_until
  end

  # `active_in` matches a pledge ended mid-month for the whole of that month,
  # so cover runs to the end of it. Answering the 5th while the row is still
  # active would put a date already past beside a badge reading as live.
  test "a pledge ended mid-month runs to the end of that month" do
    contribution = create(
      :supporter_contribution, :recurring,
      started_at: Date.new(2026, 1, 1), ended_at: Date.new(2026, 8, 5)
    )

    assert_equal Date.new(2026, 8, 31), contribution.active_until
  end

  # The scope and the predicate are the same rule written twice -- once in SQL
  # for a query, once in Ruby for a preloaded association -- so they are held
  # against each other rather than trusted to stay in step.
  test "active_in? matches the scope over every shape of contribution" do
    month_start = Date.new(2026, 8, 1)
    month_end = Date.new(2026, 8, 31)

    [
      {recurring: false, started_at: Date.new(2026, 8, 10), ended_at: nil},
      {recurring: false, started_at: Date.new(2026, 7, 31), ended_at: nil},
      {recurring: false, started_at: Date.new(2026, 9, 1), ended_at: nil},
      {recurring: true, started_at: Date.new(2026, 1, 1), ended_at: nil},
      {recurring: true, started_at: Date.new(2026, 1, 1), ended_at: Date.new(2026, 8, 5)},
      {recurring: true, started_at: Date.new(2026, 1, 1), ended_at: Date.new(2026, 7, 31)},
      {recurring: true, started_at: Date.new(2026, 9, 1), ended_at: nil}
    ].each { |attrs| create(:supporter_contribution, **attrs) }

    by_scope = SupporterContribution.active_in(month_start, month_end).pluck(:id).sort
    in_ruby = SupporterContribution.all.select { |c| c.active_in?(month_start, month_end) }.map(&:id).sort

    assert_equal by_scope, in_ruby
  end
end
