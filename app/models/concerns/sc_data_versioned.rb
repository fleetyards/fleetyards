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
  end

  class_methods do
    # The build a request should actually be answered from.
    #
    # Normally the configured one. But the config names a build as soon as it is
    # parsed and pushed, while the rows for it arrive later -- `ScData::CheckJob`
    # enqueues the load at 22:00, so a bump can sit up to a day ahead of its
    # data. Read strictly, every catalogue that joins its build inner-wise
    # answers *nothing* for that whole window: 7,274 components, 4,847
    # equipment and 232 commodities, all gone until the load lands.
    #
    # So a configured build with no rows falls back to the newest one this
    # environment does have -- the previous patch, which is the last thing we
    # actually know. One patch behind reads as slightly stale; empty reads as
    # broken.
    #
    # Deliberately NOT folded into `<Build>.current`, which has to keep meaning
    # "exactly this build": `ScData::CheckJob#loaded?` asks it whether the new
    # build has landed, and a fallback there would answer yes forever and the
    # load would never be enqueued at all.
    def served_source(source = ::ScData::Source.current)
      build_class = reflect_on_association(:builds).klass
      return source if build_class.current(source).exists?

      version = build_class.for_source(source).order(created_at: :desc).limit(1).pick(:version)
      return source if version.blank?

      ::ScData::Source.new(version:, environment: source.environment)
    end
  end
end
