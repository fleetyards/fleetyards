# frozen_string_literal: true

# == Schema Information
#
# Table name: user_blueprints
#
#  id           :uuid             not null, primary key
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  blueprint_id :uuid             not null
#  user_id      :uuid             not null
#
# Indexes
#
#  index_user_blueprints_on_blueprint_id        (blueprint_id)
#  index_user_blueprints_on_user_and_blueprint  (user_id,blueprint_id) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (blueprint_id => blueprints.id) ON DELETE => cascade
#  fk_rails_...  (user_id => users.id) ON DELETE => cascade
#
FactoryBot.define do
  factory :user_blueprint do
    user
    blueprint
  end
end
