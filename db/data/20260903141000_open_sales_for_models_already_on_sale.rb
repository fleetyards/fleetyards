# frozen_string_literal: true

# Opens a sale row for every ship the store currently has discounted.
#
# `started_at` is the moment this runs, not the moment the sale began -- nothing
# recorded that, and a backdated guess would be indistinguishable from a
# measurement. It is deliberately wrong in one direction only: these first rows
# under-report how long the sale ran, and are excluded from nothing else.
#
# Without them the flag's *next* flip has no open row to close, so the sale that
# is running right now would vanish entirely rather than merely start late.
class OpenSalesForModelsAlreadyOnSale < ActiveRecord::Migration[8.1]
  def up
    now = Time.current

    Model.where(on_sale: true).find_each do |model|
      next if model.sales.ongoing.exists?

      model.sales.create!(started_at: now)
    end
  end

  def down
    ModelSale.ongoing.delete_all
  end
end
