# frozen_string_literal: true

# The place a record's free text names, where it is one of ours, under `key`:
# null where the text names nothing the starmap carries.
location = local_assigns[:location]

if location
  json.set! key do
    json.partial! "api/v1/locations/link", location:
  end
else
  json.set! key, nil
end
