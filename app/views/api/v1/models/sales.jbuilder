# frozen_string_literal: true

json.sales @sales, partial: "api/v1/model_sales/model_sale", as: :model_sale

json.sales_count @model.sales_count
json.last_sale_at @model.last_sale&.started_at
json.average_days_between_sales @model.average_days_between_sales
