# frozen_string_literal: true

module Admin
  module V1
    module Schemas
      module Models
        module Loaners
          class ModelLoaner < ::V1::Schemas::Models::Loaners::ModelLoaner
            include SchemaConcern

            schema({
              properties: {}
            })
          end
        end
      end
    end
  end
end
