# frozen_string_literal: true

# Four columns nothing has written since the scunpacked loader was archived.
# paper_trail records `sc_loader` as the last writer of every one of them, on
# 2024-05-24.
#
# They are also misnamed. The values are **seconds**, not accelerations -- the
# Razor's stored 1.41 is the time it takes to reach its SCM speed, and dividing
# that speed by the main thrusters' thrust over the ship's mass gives 1.41 back.
# Same for the Mercury Star Runner (3.28 against 3.30), the Cutlass Steel (2.65
# against 2.60) and the Mantis (1.60 against 1.57); `*_decceleration` is the same
# figure against the retro thrusters.
#
# Nothing displays them: no jbuilder, no OpenAPI schema, no frontend. They are
# reachable only through `ransackable_attributes`, which is why they have sat
# unnoticed with stale values.
#
# So they go, and the two figures they were derived from arrive on the build
# instead: the acceleration the main thrusters give and the deceleration the retro
# thrusters give, both in m/s^2, both saying what they hold. Every time the old
# columns tried to express follows from those and a speed we already carry --
# seconds to SCM is `scm_speed / main_acceleration`.
class ReplaceAccelerationColumns < ActiveRecord::Migration[8.1]
  COLUMNS = %i[
    scm_speed_acceleration scm_speed_decceleration
    max_speed_acceleration max_speed_decceleration
  ].freeze

  def up
    COLUMNS.each { |column| remove_column :models, column }

    add_column :model_builds, :main_acceleration, :decimal, precision: 15, scale: 2
    add_column :model_builds, :retro_acceleration, :decimal, precision: 15, scale: 2
    add_column :models, :main_acceleration, :decimal, precision: 15, scale: 2
    add_column :models, :retro_acceleration, :decimal, precision: 15, scale: 2
  end

  def down
    remove_column :model_builds, :main_acceleration
    remove_column :model_builds, :retro_acceleration
    remove_column :models, :main_acceleration
    remove_column :models, :retro_acceleration

    COLUMNS.each { |column| add_column :models, column, :decimal, precision: 15, scale: 2 }
  end
end
