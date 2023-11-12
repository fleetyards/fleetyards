# frozen_string_literal: true

# == Schema Information
#
# Table name: messages
#
#  id         :uuid             not null, primary key
#  archived   :boolean          default(FALSE)
#  body       :text
#  email      :string
#  from       :string
#  from_raw   :text
#  read       :boolean          default(FALSE)
#  subject    :string
#  to         :text
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  user_id    :uuid
#
class Message < ApplicationRecord
  belongs_to :user, optional: true
  has_many :message_attachments, dependent: :destroy

  validates :email, :from_raw, :to, presence: true

  serialize :from_raw, coder: YAML
  serialize :to, coder: YAML
end
