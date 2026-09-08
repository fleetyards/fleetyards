# frozen_string_literal: true

json.from do
  json.environment @from.environment
  json.version @from.version
end

json.to do
  json.environment @to.environment
  json.version @to.version
end

json.catalogues do
  @comparisons.each do |name, result|
    json.set! name do
      # False when one side has no rows for this catalogue at all: it was not
      # recorded for that build, which is a different statement from "everything
      # appeared". The lists are empty in that case, so a reader that ignores
      # this still cannot draw the wrong conclusion.
      json.recorded result.recorded?

      json.counts result.counts

      json.appeared result.appeared
      json.vanished result.vanished

      # The changes carry the fields that differ, so a reader can pick the ones
      # it cares about -- a rename is the interesting one, and it is a change on
      # `name` rather than a category of its own.
      json.changed do
        json.array! result.changed do |change|
          json.id change.id
          json.name change.name
          json.fields change.fields
        end
      end
    end
  end
end
