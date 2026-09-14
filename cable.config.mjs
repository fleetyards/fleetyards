// Typed AnyCable clients for the cable channels, generated from the AsyncAPI
// documents the Ruby side writes -- the cable counterpart of orval.config.ts.
// `channels/` and `models/` are what the app consumes; bin/generate-cable-client
// drops the generated runtime and its per-channel composables, which subscribe
// unconditionally against a cable that is always there. See useSubscription.
//
// `enumType: "union"` because a cable message is the same component the REST
// schema documents: an enum member is nominal and would not be assignable to
// the literal union orval writes for the very same values, so every payload
// reaching fyApi-typed code would need a cast.
export default {
  cable: {
    input: "asyncapi/cable/v1/schema.yaml",
    output: {
      target: "app/frontend/services/fyCable",
      enumType: "union",
    },
  },
  cableAdmin: {
    input: "asyncapi/cable/admin/v1/schema.yaml",
    output: {
      target: "app/frontend/services/fyCableAdmin",
      enumType: "union",
    },
  },
};
