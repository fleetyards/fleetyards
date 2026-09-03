# frozen_string_literal: true

# == Schema Information
#
# Table name: model_sales
#
#  id         :uuid             not null, primary key
#  ended_at   :datetime
#  started_at :datetime         not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  model_id   :uuid             not null
#
# Indexes
#
#  index_model_sales_on_model_id                 (model_id)
#  index_model_sales_on_model_id_and_started_at  (model_id,started_at) UNIQUE
#  index_model_sales_on_model_id_ongoing         (model_id) UNIQUE WHERE (ended_at IS NULL)
#  index_model_sales_on_started_at               (started_at)
#
# Foreign Keys
#
#  fk_rails_...  (model_id => models.id) ON DELETE => cascade
#
FactoryBot.define do
  factory :model_sale do
    model
    started_at { 1.week.ago }

    trait :finished do
      ended_at { 5.days.ago }
    end
  end
end
