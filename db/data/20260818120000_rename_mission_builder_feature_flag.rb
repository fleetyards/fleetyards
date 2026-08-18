# frozen_string_literal: true

class RenameMissionBuilderFeatureFlag < ActiveRecord::Migration[8.1]
  OLD_NAME = "mission_builder"
  NEW_NAME = "fleet_mission_builder"

  def up
    rename_flag(OLD_NAME, NEW_NAME)
  end

  def down
    rename_flag(NEW_NAME, OLD_NAME)
  end

  # Rewrites the Flipper rows in place instead of add + remove, so every gate
  # value the flag carries — the enabled beta actors above all — survives the
  # rename. Has to land before `bin/feature-flags sync`, which prunes any key
  # missing from the registry along with its gates; the pre-deploy hook runs
  # data migrations first.
  private def rename_flag(from, to)
    feature = Flipper::Adapters::ActiveRecord::Feature.find_by(key: from)
    return if feature.nil?

    # Both keys present means a sync already created the target; the source is
    # then a leftover, and merging two sets of gates is not something to guess at.
    if Flipper::Adapters::ActiveRecord::Feature.exists?(key: to)
      Flipper.remove(from)
      return
    end

    Flipper::Adapters::ActiveRecord::Gate.where(feature_key: from).update_all(feature_key: to)
    feature.update!(key: to)

    # The synchronizer seeds the new name and drops rows for unknown flags, but
    # only when pruning is on — moving it here keeps the rename self-contained.
    FeatureSetting.where(feature_name: from).update_all(feature_name: to) unless FeatureSetting.exists?(feature_name: to)
  end
end
