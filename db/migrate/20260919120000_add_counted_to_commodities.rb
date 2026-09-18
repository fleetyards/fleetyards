# frozen_string_literal: true

# Whether the game counts this commodity in pieces rather than hauling it in
# bulk. A fourth fact for the smallest of the four catalogues, so it lands on
# the row and on the build the same way the other three do.
#
# `false` rather than null: bulk is what the app has said about every commodity
# it has ever held, and a build parsed before the parser read the container said
# exactly that rather than saying nothing. It also keeps the API's boolean a
# boolean -- a nullable one reaches the frontend as `boolean | null` and every
# caller has to answer for a third case that means "bulk" anyway.
class AddCountedToCommodities < ActiveRecord::Migration[8.1]
  def change
    add_column :commodities, :counted, :boolean, null: false, default: false
    add_column :commodity_builds, :counted, :boolean, null: false, default: false
  end
end
