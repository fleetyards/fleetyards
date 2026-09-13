// Typed AnyCable clients for the cable channels, generated from the AsyncAPI
// documents the Ruby side writes -- the cable counterpart of orval.config.ts.
// `channels/` and `models/` are what the app consumes; bin/generate-cable-client
// drops the generated runtime and its per-channel composables, which subscribe
// unconditionally against a cable that is always there. See useSubscription.
export default {
  cable: {
    input: "asyncapi/cable/v1/schema.yaml",
    output: {
      target: "app/frontend/services/fyCable",
    },
  },
  cableAdmin: {
    input: "asyncapi/cable/admin/v1/schema.yaml",
    output: {
      target: "app/frontend/services/fyCableAdmin",
    },
  },
};
