# frozen_string_literal: true

# == Schema Information
#
# Table name: imports
#
#  id            :uuid             not null, primary key
#  aasm_state    :string
#  failed_at     :datetime
#  finished_at   :datetime
#  import_data   :text
#  info          :text
#  input         :jsonb
#  output        :jsonb
#  started_at    :datetime
#  type          :string
#  version       :string
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  admin_user_id :uuid
#  user_id       :uuid
#
# Indexes
#
#  index_imports_on_aasm_state_and_type  (aasm_state,type)
#  index_imports_on_admin_user_id        (admin_user_id)
#  index_imports_on_type                 (type)
#
# Foreign Keys
#
#  fk_rails_...  (admin_user_id => admin_users.id)
#
class Import < ApplicationRecord
  include AASM

  belongs_to :admin_user, optional: true
  belongs_to :user, optional: true

  validates :type, presence: true

  def self.ransackable_attributes(auth_object = nil)
    [
      "aasm_state", "admin_user_id", "created_at", "failed_at", "finished_at", "id", "id_value",
      "import", "import_data", "info", "input", "output", "started_at", "type", "updated_at",
      "user_id", "version"
    ]
  end

  def self.ransackable_associations(auth_object = nil)
    ["admin_user", "user"]
  end

  aasm timestamps: true do
    state :created, initial: true
    state :started
    state :finished
    state :failed

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
    AdminUser.find_each do |admin_user|
      ::ImportsChannel.broadcast_to(admin_user, to_jbuilder_hash)
    end

    report_run
  end

  def label
    type.to_s.demodulize.underscore.humanize
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
