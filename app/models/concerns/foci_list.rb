# frozen_string_literal: true

# A list of keys from `Model::FOCI`, on a ship or on a crew slot asking for one.
module FociList
  extend ActiveSupport::Concern

  included do
    validate :foci_must_be_known
    before_save :keep_focus_with_foci
  end

  private def foci_must_be_known
    errors.add(:foci, :inclusion) if (foci - ::Model::FOCI).any?
  end

  # `focus` is the string the list replaced, still served and sorted by for
  # clients that read it. Whatever changes the keys without saying a focus
  # rewrites it from them, so it never contradicts them -- and a slot cleared
  # of its keys is not left asking for its old focus.
  private def keep_focus_with_foci
    return unless will_save_change_to_foci? && !will_save_change_to_focus?

    self.focus = I18n.with_locale(:en) { ::Model.focus_labels(foci).join(" / ") }.presence
  end
end
