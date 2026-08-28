# frozen_string_literal: true

# Which build of the game data this request reads.
#
# `source=ptu` puts that source in force for the whole action, so every model,
# scope and ransacker underneath answers from it without being told -- which is
# what `ScData::Source.current` being a per-request value buys.
#
# Only a source that is **available** is accepted: one the config declares *and*
# a catalogue carries builds for. An environment nothing has loaded would answer
# every question with nothing, and serving an empty catalogue under a familiar
# label is worse than refusing the parameter.
module ScDataSource
  extend ActiveSupport::Concern

  included do
    around_action :with_sc_data_source
  end

  private def with_sc_data_source(&)
    source = requested_sc_data_source

    return yield if source.nil?

    ::ScData::Source.with(source, &)
  end

  # Nil rather than an error for a source that is not available: a client asking
  # for one gets the default rather than a failure, because the alternative is
  # a bookmarked link breaking the day an environment is retired.
  private def requested_sc_data_source
    requested = params[:source].presence

    return if requested.blank?

    ::ScData::Source.available.find { |source| source.environment == requested.to_s }
  end
end
