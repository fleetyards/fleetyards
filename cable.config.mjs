// Message types for the cable channels, generated from the AsyncAPI documents
// the Ruby side writes. Only `models/` is consumed: the generated channel
// classes and runtime target @anycable/core, and the app subscribes through
// @rails/actioncable via useSubscription. bin/generate-cable-client drops the
// rest so nothing unused reaches the compile graph.
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
