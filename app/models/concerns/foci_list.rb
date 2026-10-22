# frozen_string_literal: true

# A list of keys from `Model::FOCI`, on a ship or on a crew slot asking for one.
module FociList
  extend ActiveSupport::Concern

  included do
    # Ignored before it is dropped, so this release keeps working while the
    # next one's pre-deploy migration removes the column.
    self.ignored_columns += ["focus"]

    validate :foci_must_be_known
  end

  private def foci_must_be_known
    errors.add(:foci, :inclusion) if (foci - ::Model::FOCI).any?
  end
end
