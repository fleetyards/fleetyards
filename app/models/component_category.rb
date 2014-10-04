class ComponentCategory < ActiveRecord::Base
  translates :name

  has_many :components

  validates_presence_of :name

  before_validation :set_name
  before_save :update_slugs

  private def set_name
    self.name = self.rsi_name.capitalize
  end

  private def update_slugs
    self.slug = SlugHelper::generate_slug self.name
  end
end
