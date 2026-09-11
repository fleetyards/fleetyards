# frozen_string_literal: true

# == Schema Information
#
# Table name: imports
#
#  id                  :uuid             not null, primary key
#  aasm_state          :string
#  cancel_requested_at :datetime
#  cancelled_at        :datetime
#  failed_at           :datetime
#  finished_at         :datetime
#  import_data         :text
#  info                :text
#  input               :jsonb
#  output              :jsonb
#  started_at          :datetime
#  type                :string
#  version             :string
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  admin_user_id       :uuid
#  hangar_group_id     :uuid
#  user_id             :uuid
#
# Indexes
#
#  index_imports_on_aasm_state_and_type  (aasm_state,type)
#  index_imports_on_admin_user_id        (admin_user_id)
#  index_imports_on_hangar_group_id      (hangar_group_id)
#  index_imports_on_type                 (type)
#  index_imports_on_type_and_id          (type,id)
#  index_imports_on_user_id              (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (admin_user_id => admin_users.id)
#  fk_rails_...  (hangar_group_id => hangar_groups.id) ON DELETE => nullify
#
class Import < ApplicationRecord
  include AASM

  belongs_to :admin_user, optional: true
  belongs_to :user, optional: true

  # The group a hangar import or sync was aimed at. Optional on every type --
  # only the two user-facing ones ever set it.
  belongs_to :hangar_group, optional: true

  validates :type, presence: true

  # An import that entered `started` and is still there long after any run would
  # have finished. Not a state of its own: the job died without ever reaching
  # `fail`, so nothing marked it.
  #
  # `started_at` rather than `created_at`: an import can sit queued for a while
  # before it runs, and that wait is not the job hanging.
  STUCK_AFTER = 1.hour

  scope :stuck, -> { where(aasm_state: "started").where(started_at: ...STUCK_AFTER.ago) }

  DEFAULT_SORTING_PARAMS = "created_at desc"
  ALLOWED_SORTING_PARAMS = ["createdAt asc", "createdAt desc"].freeze

  # Set while an admin clears a stuck import by hand. Neither half of
  # `notify_admin` belongs to that: the broadcast raises a red "import failed"
  # toast on the page the admin is looking at, once per row they just cleared,
  # and the notification would trade the dashboard's stuck tile for a larger
  # notifications one.
  attr_accessor :skip_admin_notice

  def self.ransackable_attributes(auth_object = nil)
    [
      "aasm_state", "admin_user_id", "cancel_requested_at", "cancelled_at", "created_at",
      "failed_at", "finished_at", "hangar_group_id", "id", "id_value", "import", "import_data",
      "info", "input", "output", "started_at", "type", "updated_at", "user_id", "version"
    ]
  end

  def self.ransackable_associations(auth_object = nil)
    ["admin_user", "hangar_group", "user"]
  end

  aasm timestamps: true do
    state :created, initial: true
    state :started
    state :finished
    state :failed
    state :cancelled

    event :start, after_commit: :notify_admin do
      transitions from: :created, to: :started
    end

    event :finish, after_commit: :notify_admin do
      transitions from: :started, to: :finished
    end

    event :fail, after_commit: :notify_admin do
      transitions from: :created, to: :failed
      transitions from: :started, to: :failed
    end

    # The state moves at once so the user gets an answer and the
    # already-running guard lets them start again. A job that is still alive
    # stops at its next checkpoint; one that is already gone leaves a row that
    # has stopped claiming to run, which is the same outcome `cleanup!` gives
    # an admin.
    event :cancel, after_commit: :notify_admin do
      transitions from: :created, to: :cancelled
      transitions from: :started, to: :cancelled
    end
  end

  # Set in the same write as the transition. The running job polls this column
  # rather than the state because it is the flag that means "stop", and reading
  # one column avoids dragging the whole `import_data` blob back on every check.
  def request_cancel!
    return false unless may_cancel?

    self.cancel_requested_at = Time.current
    cancel!
  end

  def cancel_requested?
    self.class.where(id:).pick(:cancel_requested_at).present?
  end

  def running?
    created? || started?
  end

  # Imports whose job files its own report, with the detail a status line
  # cannot carry. Reporting both would put every paints run into the center
  # twice - once with the missing models, once saying it finished.
  SELF_REPORTED_TYPES = %w[
    Imports::ModelsImport
    Imports::ModulesImport
    Imports::PaintsImport
    Imports::UexPricesImport
    Imports::UexCommodityPricesImport
    Imports::ScData::AllImport
  ].freeze

  def notify_admin
    return if skip_admin_notice

    AdminUser.find_each do |admin_user|
      ::ImportsChannel.broadcast_to(admin_user, to_jbuilder_hash)
    end

    report_run
  end

  def label
    type.to_s.demodulize.underscore.humanize
  end

  # Nothing here reaches the job. A Sidekiq process that turns out to be alive
  # after all carries on working and then raises on its own `finish!`, because
  # the transition it expects is no longer there -- which is why this is the
  # admin's call and never a sweeper.
  def cleanup!(admin_user: nil)
    self.skip_admin_notice = true
    self.info = [info.presence, cleanup_note(admin_user)].compact.join(" -- ")

    # Validations belong to the run, not to the record of it: an abandoned
    # `Imports::HangarImport` whose attached file has since gone is exactly the
    # kind of row that gets stuck, and it must not be the one row that cannot
    # be written off.
    fail_without_validation!

    # That path writes the state column with an `update_all` and nothing else,
    # and `failed_at` is set by a transition callback that runs after it. Both
    # the timestamp and the note need a save of their own.
    save!(validate: false)
  end

  private def cleanup_note(admin_user)
    "Marked as failed by #{admin_user&.username || "an admin"}: the job stopped reporting."
  end

  # The cable broadcast reaches whoever has the imports page open; this is for
  # everyone who does not, which is the point of the notification center.
  private def report_run
    # A user's import belongs to that user - they ran it, they get told in
    # their own center, and thousands of syncs a week are not admin news.
    return if user_id.present?
    return unless finished? || failed?
    return if finished? && SELF_REPORTED_TYPES.include?(type.to_s)

    AdminNotification.notify!(
      type: :import_run,
      title: "#{label} #{aasm_state}",
      body: info.presence,
      severity: failed? ? :error : :info,
      link: "/maintenance/imports",
      record: self
    )
  end
end
