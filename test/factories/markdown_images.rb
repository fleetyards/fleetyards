# == Schema Information
#
# Table name: markdown_images
#
#  id         :uuid             not null, primary key
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  user_id    :uuid
#
# Indexes
#
#  index_markdown_images_on_user_id_and_created_at  (user_id,created_at)
#
# Foreign Keys
#
#  fk_rails_...  (user_id => users.id) ON DELETE => nullify
#
FactoryBot.define do
  factory :markdown_image do
    association :user

    file do
      ActiveStorage::Blob.create_and_upload!(
        io: Rails.root.join("test/fixtures/files/test.png").open,
        filename: "test.png",
        content_type: "image/png"
      ).signed_id
    end
  end
end
