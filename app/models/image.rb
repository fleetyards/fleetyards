class Image < ActiveRecord::Base
  belongs_to :gallery, polymorphic: true

  mount_uploader :name, ImageUploader
end
