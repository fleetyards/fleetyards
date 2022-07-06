# frozen_string_literal: true

# == Schema Information
#
# Table name: email_rejections
#
#  id         :uuid             not null, primary key
#  email      :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
class EmailRejection < ApplicationRecord
end
