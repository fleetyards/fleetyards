# frozen_string_literal: true

# A free-text place a record names, linked to one of ours where it is one. The
# text stays: it is what a reader sees, and the only thing there is for a
# place the starmap does not carry. The link sits beside it.
#
# The two are kept in step. Linking a place with no text of its own fills the
# text with the place's name, and so does linking another place where the text
# was only the old one's name. Changing the text away from the linked name
# drops the link -- "Lorville" retyped as "Lorville, near the elevators" no
# longer is Lorville.
module LinkedLocations
  extend ActiveSupport::Concern

  class_methods do
    # links_location :location gives `linked_location` on `location_id`.
    def links_location(text, foreign_key: :"#{text}_id", as: :"linked_#{text}")
      belongs_to as, class_name: "Location", foreign_key:, optional: true

      before_validation { sync_linked_location(text, foreign_key, as) }
    end
  end

  private def sync_linked_location(text, foreign_key, association)
    link = public_send(association)
    return if link.nil?

    if will_save_change_to_attribute?(foreign_key) && !will_save_change_to_attribute?(text)
      self[text] = link.name if self[text].blank? || self[text] == previously_linked_name(foreign_key)
    elsif will_save_change_to_attribute?(text) && !will_save_change_to_attribute?(foreign_key) && self[text] != link.name
      self[foreign_key] = nil
    end
  end

  private def previously_linked_name(foreign_key)
    previous_id = attribute_in_database(foreign_key)

    Location.where(id: previous_id).pick(:name) if previous_id
  end
end
