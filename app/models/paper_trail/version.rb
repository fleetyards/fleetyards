class PaperTrail::Version < ApplicationRecord
  include PaperTrail::VersionConcern

  def self.ransackable_attributes(auth_object = nil)
    [
      "author_id", "created_at", "event", "id", "id_value", "item_id", "item_type", "object",
      "object_changes", "old_object", "old_object_changes", "reason", "reason_description",
      "whodunnit"
    ]
  end
end
