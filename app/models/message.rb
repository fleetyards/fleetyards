# frozen_string_literal: true

# == Schema Information
#
# Table name: messages
#
#  id         :uuid             not null, primary key
#  body       :text
#  from       :string
#  subject    :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  user_id    :uuid
#
class Message < ApplicationRecord
end
