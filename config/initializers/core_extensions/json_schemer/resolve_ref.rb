# frozen_string_literal: true

require "json_schemer"

# json_schemer 2.5.0 strips the fragment from the URI it is given, and `$ref`
# keywords pass in the URI they memoize. Two Puma threads validating against
# the shared OpenAPI meta-schema for the first time can then resolve the same
# `$ref` one after the other: the second sees "#/$defs/..." already removed and
# gets the document root back. The OpenAPI schema's root carries such a `$ref`,
# so the root then refers to itself and validation ends in a SystemStackError.
#
# A newer release may change resolve_ref's signature or stop mutating its
# argument, so it has to be checked against this before the patch is kept.
unless JSONSchemer::VERSION == "2.5.0"
  raise "json_schemer #{JSONSchemer::VERSION} is not the version #{__FILE__} guards resolve_ref for"
end

module CoreExtensions
  module JSONSchemer
    module ResolveRef
      def resolve_ref(uri)
        super(uri.dup)
      end
    end
  end
end

JSONSchemer::Schema.prepend(CoreExtensions::JSONSchemer::ResolveRef)
