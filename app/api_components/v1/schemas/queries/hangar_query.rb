# frozen_string_literal: true

module V1
  module Schemas
    module Queries
      class HangarQuery
        include SchemaConcern

        schema({
          type: :object,
          properties: {
            searchCont: {type: :string, nullable: true},
            nameCont: {type: :string, nullable: true}
          }
        })
      end
    end
  end
end

# :search_cont, :name_cont, :model_name_or_model_description_cont, :on_sale_eq,
# :public_eq, :length_gteq, :length_lteq, :price_gteq, :price_lteq,
# :pledge_price_gteq, :pledge_price_lteq, :loaner_eq, :bought_via_eq,
# manufacturer_in: [], classification_in: [], focus_in: [],
# size_in: [], price_in: [], pledge_price_in: [],
# production_status_in: [], hangar_groups_in: [], hangar_groups_not_in: []
