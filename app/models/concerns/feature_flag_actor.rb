# frozen_string_literal: true

# Flipper keeps an actor gate as a bare `"Class;id"` string with nothing tying
# it to the record, so a destroyed user or fleet would otherwise stay listed on
# every flag it was ever added to, as an actor /admin/features cannot name.
module FeatureFlagActor
  extend ActiveSupport::Concern

  included do
    after_destroy_commit :remove_feature_flag_gates
  end

  private def remove_feature_flag_gates
    Flipper.adapter.get_all.each do |feature_name, gates|
      next unless gates[:actors]&.include?(flipper_id)

      Flipper.feature(feature_name).disable_actor(self)
    end
  end
end
