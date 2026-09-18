# frozen_string_literal: true

# A catalogue whose rows carry the build they were last seen in.
#
# Rows of past patches stay in the table -- a ledger entry or a loadout made
# against one still has to resolve -- so anything meant for a picker narrows to
# the version the game currently ships. `ScData::Loader::BaseLoader#retire_absent`
# is the other half: it clears the version off a row the export stopped naming.
#
# Note that this only supplies the scope. `ransackable_scopes` is left to each
# model, because only Component exposes it through ransack -- the commodity and
# equipment controllers take the parameter off the query and pass it to the scope
# themselves.
module ScDataVersioned
  extend ActiveSupport::Concern

  included do
    # The flag arrives from a query parameter, so it is cast rather than
    # trusted: what reaches here is the string "false", which is truthy.
    scope :current_version, ->(flag = true) {
      if ActiveModel::Type::Boolean.new.cast(flag)
        where(version: ScData::Source.version)
      else
        all
      end
    }

    # One definition rather than four, because three of the four had drifted:
    # `current_version` had already fallen back to the previous patch while the
    # join still targeted the configured build, so the scope selected rows the
    # inner join then threw away -- an empty catalogue, which is the exact
    # failure the fallback exists to prevent. Here a catalogue cannot have one
    # without the other, and a fifth cannot be added without both.
    #
    # `current_facts_join` and `all_facts_join` stay per model: each names its
    # own build table and foreign key.
    scope :with_facts, ->(current_only = true, source = ::ScData::Source.current) {
      resolved = served_source(source)

      joins(
        ActiveModel::Type::Boolean.new.cast(current_only) ? current_facts_join(resolved) : all_facts_join(resolved)
      )
    }
  end

  class_methods do
    # The build a request should actually be answered from -- the configured
    # one, or the patch behind it while its load has not run. `ScData::Source`
    # owns that resolution; the source switch reads it too, so the catalogue
    # and the label over it cannot disagree.
    #
    # Deliberately NOT folded into `<Build>.current`, which has to keep meaning
    # "exactly this build": `ScData::CheckJob#loaded?` asks it whether the new
    # build has landed, and a fallback there would answer yes for ever and the
    # load would never be enqueued at all.
    def served_source(source = ::ScData::Source.current)
      source.served
    end
  end
end
