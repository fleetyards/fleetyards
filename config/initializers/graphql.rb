# frozen_string_literal: true

GraphQL::ObjectType.accepts_definitions resolves_to_class_names: GraphQL::Define.assign_metadata_key(:resolves_to_class_names)
GraphQL::Field.accepts_definitions needs_authentication: GraphQL::Define.assign_metadata_key(:needs_authentication)
