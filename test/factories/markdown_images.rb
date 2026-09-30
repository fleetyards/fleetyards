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
