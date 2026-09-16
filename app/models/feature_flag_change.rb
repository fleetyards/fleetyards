# frozen_string_literal: true

# One row per write to a Flipper flag, written by FeatureFlags::AuditSubscriber
# off the `feature_operation.flipper` notification.
#
# Append-only, and never pruned: `feature_name` is a plain string rather than a
# reference precisely so a flag's history survives the sync that removes it.
# == Schema Information
#
# Table name: feature_flag_changes
#
#  id            :uuid             not null, primary key
#  feature_name  :string           not null
#  gate_name     :string
#  operation     :string           not null
#  source        :string           not null
#  state_after   :string           not null
#  thing         :string
#  created_at    :datetime         not null
#  admin_user_id :uuid
#  user_id       :uuid
#
# Indexes
#
#  index_feature_flag_changes_on_admin_user_id                (admin_user_id)
#  index_feature_flag_changes_on_feature_name_and_created_at  (feature_name,created_at DESC)
#  index_feature_flag_changes_on_user_id                      (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (admin_user_id => admin_users.id) ON DELETE => nullify
#  fk_rails_...  (user_id => users.id) ON DELETE => nullify
#
class FeatureFlagChange < ApplicationRecord
  # The operations that change something. Flipper publishes `enabled?` and
  # `exist?` on the same event -- see FeatureFlags::AuditSubscriber, which is
  # where they get filtered out.
  OPERATIONS = %w[enable disable add remove clear].freeze

  # Who was responsible. `console` is the honest answer for a `bin/rails runner`
  # and for the e2e scenarios, since neither carries a request to attribute to.
  SOURCE_ADMIN = "admin"
  SOURCE_SELF_SERVICE = "self_service"
  SOURCE_SYNC = "sync"
  SOURCE_CONSOLE = "console"
  SOURCE_BACKFILL = "backfill"
  SOURCES = [SOURCE_ADMIN, SOURCE_SELF_SERVICE, SOURCE_SYNC, SOURCE_CONSOLE, SOURCE_BACKFILL].freeze

  # What `gate_name` holds, keyed by the column flipper_gates stores it under.
  #
  # Flipper names the actor and group gates in the singular but keys them in the
  # plural, and the notification carries the name while the table carries the
  # key -- so a row read out of flipper_gates and a row written by the
  # subscriber would otherwise disagree about what the same gate is called.
  # Derived rather than listed so a gate added by a future flipper cannot drift.
  GATE_NAMES_BY_STORAGE_KEY = Flipper::Feature
    .new(:_, Flipper::Adapters::Memory.new)
    .gates
    .to_h { |gate| [gate.key.to_s, gate.name.to_s] }
    .freeze

  # Flipper's own three, stringified.
  STATE_ON = "on"
  STATE_OFF = "off"
  STATE_CONDITIONAL = "conditional"
  STATES = [STATE_ON, STATE_OFF, STATE_CONDITIONAL].freeze

  belongs_to :admin_user, optional: true
  belongs_to :user, optional: true

  validates :feature_name, presence: true
  validates :operation, inclusion: {in: OPERATIONS}
  validates :state_after, inclusion: {in: STATES}
  validates :source, inclusion: {in: SOURCES}

  scope :for_feature, ->(feature_name) { where(feature_name: feature_name.to_s) }
  scope :newest_first, -> { order(created_at: :desc, id: :desc) }

  # Writes the row for one `feature_operation.flipper` payload.
  #
  # The state is read back from Flipper rather than derived from the operation,
  # because an operation alone does not say where the flag ended up: disabling
  # one actor of six leaves it `conditional`, and the sixth leaves it `off`.
  # Safe to read here -- Flipper's memoizable adapter expires its cache entry on
  # every write, and this runs after the write, so it is never the pre-write
  # value.
  def self.record!(payload)
    feature_name = payload[:feature_name].to_s
    thing = payload[:thing]

    create!(
      feature_name: feature_name,
      operation: payload[:operation].to_s,
      gate_name: payload[:gate_name]&.to_s,
      thing: thing.respond_to?(:value) ? thing.value.to_s : thing&.to_s,
      state_after: Flipper.feature(feature_name).state.to_s,
      source: FeatureFlags::Current.source || SOURCE_CONSOLE,
      admin_user: FeatureFlags::Current.resolved_admin_user,
      user: FeatureFlags::Current.resolved_user
    )
  end

  # When the flag last became on for everyone, or nil if it is not on now.
  #
  # The *start of the current run* rather than the newest `on` row: switching a
  # flag on and then granting an extra actor writes a second `on` row, and the
  # flag has been fully open since the first of them. A run is broken by any row
  # that is not `on`, which is the off-and-on-again case `flipper_gates` gets
  # wrong -- it reports the re-enable as though the flag had never been off.
  def self.fully_on_since(feature_name)
    states = for_feature(feature_name).newest_first.pluck(:state_after, :created_at)
    return unless states.first&.first == STATE_ON

    states.take_while { |state, _| state == STATE_ON }.last.last
  end
end
