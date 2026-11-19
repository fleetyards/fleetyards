# frozen_string_literal: true

json.items do
  json.array! @feedbacks, partial: "api/v1/feedbacks/feedback", as: :feedback
end
json.partial! "api/shared/meta", result: @feedbacks
