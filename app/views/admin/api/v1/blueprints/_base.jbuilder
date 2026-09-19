# frozen_string_literal: true

# Everything the public catalogue shows, plus the two things only an admin
# asks: whether the recipe's output resolved to anything at all, and which
# build the facts above were read from.
json.partial! "api/v1/blueprints/base", blueprint: blueprint

# 5 of the 1607 recipes in 4.10.1 name an output nothing in the catalogues
# matches. The public payload leaves `craftable` null and says no more; here it
# is stated, because those five rows are the point of the section.
json.craftable_missing blueprint.craftable_missing?

# Which build answered. `retired` above says whether it was the build we are on;
# this says which one it actually was, because a ptu load is a separate row and
# a recipe the current build dropped is read off the last one that described it.
if blueprint.facts.present?
  json.build do
    json.version blueprint.facts.version
    json.environment blueprint.facts.environment
  end
else
  json.build nil
end
