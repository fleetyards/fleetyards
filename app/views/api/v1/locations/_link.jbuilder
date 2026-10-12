# frozen_string_literal: true

json.id location.id
json.name location.name
json.slug location.slug
json.kind location.kind

# What tells apart the places that share a name -- there are two Outpost 54s
# on Aberdeen. Off the parent's own column rather than its build: a label does
# not need the build loaded for every link on a page.
#
# Merged rather than set: `Jbuilder.ignore_nil` would drop a system's null
# and leave the required key missing.
json.merge!(parent_name: location.parent&.[](:name)) # standard:disable Performance/RedundantMerge -- a Jbuilder, not a Hash: `[]=` would drop the nil
