# frozen_string_literal: true

require "test_helper"
require "asyncapi_cable/minitest"

# AssertHelpers.components_for reads _component_scopes to pick the components a
# payload validates against, but those scopes are only assigned once the
# openapi-ruby Loader has run — so the first assertion in a process would
# otherwise compute an empty scope set, get an empty component set and die on
# JSONSchemer::InvalidRefPointer. Which assertion hits it depends on the seed.
OpenapiRuby::Components::Loader.new.load!

# The DSL is scoped to this base class rather than mixed into
# ActiveSupport::TestCase: every subclass gets `_asyncapi_contexts`, and a
# channel declared anywhere would otherwise be in scope for the whole suite.
class AsyncapiTestCase < ActiveSupport::TestCase
  include AsyncapiCable::Adapters::Minitest::DSL
end
