# frozen_string_literal: true

# A ship's fuel consumption is what its thrusters draw at full thrust since
# #5775, and the builds loaded before it still hold the old figure. Every patch
# compare and the change log read the jump between the two as every ship's fuel
# changing at once -- 190 of 194 "changed" ships between 4.10.1 and 4.10.2.
#
# Each retained build is worked out again from its own hardpoints, so a figure
# moves only where the thrusters did. Builds before #5775 never recorded a
# thruster's draw, so the component's current one stands in: the only figure
# there is.
#
# The change log is then recorded again, each build against the one that
# preceded it. The oldest retained build is left alone: the build before it is
# pruned, so its recorded changes cannot be worked out again.
class RecomputeModelBuildFuelConsumption < ActiveRecord::Migration[8.1]
  def up
    builds = ModelBuild.includes(:model).order(:created_at).to_a

    builds.each do |build|
      source = ::ScData::Source.new(environment: build.environment, version: build.version)
      fuel = build.model.fuel_consumption_from_hardpoints(source)
      next if build.fuel_consumption == fuel

      build.update_columns(fuel_consumption: fuel, updated_at: Time.current)
    end

    builds.group_by { |build| [build.model_id, build.environment] }.each_value do |history|
      history.each_cons(2) do |previous, build|
        ModelBuildChange.record!(build, previous:)
      end
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
