# == Schema Information
#
# Table name: model_loaners
#
#  id              :uuid             not null, primary key
#  hidden          :boolean          default(FALSE)
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  loaner_model_id :uuid
#  model_id        :uuid
#
FactoryBot.define do
  factory :model_loaner do
    model
    loaner_model { create(:model) }
  end
end
