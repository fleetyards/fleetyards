# frozen_string_literal: true

# `source` now names the platform the money came from rather than whether a row
# was typed in by hand, and there is no platform called "manual". A hand-entered
# row whose platform nobody stated is `other`, so that is what the column
# defaults to.
class ChangeSupporterContributionSourceDefaultToOther < ActiveRecord::Migration[8.1]
  def change
    change_column_default :supporter_contributions, :source, from: "manual", to: "other"
  end
end
