# frozen_string_literal: true

if import.progress.present?
  json.progress do
    json.step import.progress["step"]
    json.step_number import.progress["step_number"]
    json.steps import.progress["steps"]
    json.done import.progress["done"]
    json.total import.progress["total"] if import.progress["total"]
    json.progressed_at import.progressed_at
  end
end
