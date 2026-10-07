<script lang="ts">
export default {
  name: "VisualTestsFleetRsiVerificationModalPage",
};
</script>

<script lang="ts" setup>
import { useQueryClient } from "@tanstack/vue-query";
import Btn from "@/shared/components/base/Btn/index.vue";
import { HeadingLevelEnum } from "@/shared/components/base/Heading/types";
import { useComlink } from "@/shared/composables/useComlink";
import { FleetyardsSyncAction } from "@/frontend/lib/FleetyardsSyncHandler";
import {
  type ExtensionStubConfig,
  signedInExtension,
  signedOutExtension,
  useVisualExtensionStub,
} from "@/frontend/composables/useVisualExtensionStub";
import {
  type Fleet,
  type FleetRsiVerification,
  NullableFleetRsiVerificationStatusEnum,
  getFleetRsiVerificationQueryKey,
} from "@/services/fyApi";

const SID = "VISUAL";

const fleet = {
  slug: "visual-fleet",
  fid: SID,
  rsiSid: SID,
  rsiVerified: false,
} as Fleet;

const unverified: FleetRsiVerification = {
  sid: SID,
  // Not a token the extension accepts, should a request ever reach one.
  token: "FLEETYARDS-DEMO",
  status: null,
  verified: false,
  verifiedAt: null,
  checkedAt: null,
};

const verified: FleetRsiVerification = {
  ...unverified,
  status: NullableFleetRsiVerificationStatusEnum.VERIFIED,
  verified: true,
  verifiedAt: "2026-10-01T12:00:00Z",
};

type State = {
  key: string;
  label: string;
  description: string;
  verification: FleetRsiVerification;
  answers: ExtensionStubConfig;
};

const readyWith = (
  orgVerifyWrite: ExtensionStubConfig[FleetyardsSyncAction],
): ExtensionStubConfig => ({
  ...signedInExtension("VisualOfficer"),
  [FleetyardsSyncAction.ORG_VERIFY_WRITE]: orgVerifyWrite,
});

const states: State[] = [
  {
    key: "no-extension",
    label: "Without the extension",
    description: "The store links above the manual steps.",
    verification: unverified,
    answers: {},
  },
  {
    key: "outdated",
    label: "Extension too old",
    description: "An extension from before org verification.",
    verification: unverified,
    answers: {
      [FleetyardsSyncAction.HEALTH]: {
        code: 200,
        payload: {
          version: "1.3.0",
          actions: ["health", "identify", "verify-write"],
        },
      },
    },
  },
  {
    key: "detecting",
    label: "Looking for the extension",
    description:
      "The extension answers its health check but not yet who is signed in. Holds for 30 seconds.",
    verification: unverified,
    answers: {
      [FleetyardsSyncAction.HEALTH]:
        signedInExtension("VisualOfficer")[FleetyardsSyncAction.HEALTH],
    },
  },
  {
    key: "ready",
    label: "Ready",
    description:
      "Signed in to RSI. Verifying sends a real check, so the button is better left alone here.",
    verification: unverified,
    answers: signedInExtension("VisualOfficer"),
  },
  {
    key: "signed-out",
    label: "Not signed in to RSI",
    description: "The extension finds no RSI session.",
    verification: unverified,
    answers: signedOutExtension(),
  },
  {
    key: "no-rights",
    label: "No rights on the org",
    description:
      "Press Verify with extension: the account cannot edit the org.",
    verification: unverified,
    answers: readyWith({ code: 403, payload: { sid: SID } }),
  },
  {
    key: "pending-changes",
    label: "Unpublished changes",
    description:
      "Press Verify with extension: another edit waits in the org's draft.",
    verification: unverified,
    answers: readyWith({ code: 409, payload: { sid: SID } }),
  },
  {
    key: "unreadable",
    label: "Org page unreadable",
    description:
      "Press Verify with extension: the org pages could not be read.",
    verification: unverified,
    answers: readyWith({ code: 422, payload: { sid: SID } }),
  },
  {
    key: "verified",
    label: "Verified",
    description: "A verified fleet.",
    verification: verified,
    answers: {},
  },
];

const extension = useVisualExtensionStub();

const comlink = useComlink();

const queryClient = useQueryClient();

const queryKey = getFleetRsiVerificationQueryKey(fleet.slug);

/*
 * The modal loads the verification itself. Seeding it as fresh for good keeps
 * the modal from asking the API, which a visual test page is not signed in to.
 */
const open = (state: State) => {
  extension.configure(state.answers);
  queryClient.setQueryDefaults(queryKey, { staleTime: Infinity });
  queryClient.setQueryData(queryKey, state.verification);

  comlink.emit("open-modal", {
    component: () =>
      import("@/frontend/components/Fleets/RsiVerificationModal/index.vue"),
    props: { fleet },
  });
};

onBeforeUnmount(() => {
  queryClient.removeQueries({ queryKey });
  queryClient.setQueryDefaults(queryKey, {});
});
</script>

<template>
  <Heading :level="HeadingLevelEnum.H2">
    Fleet RSI verification modal states
  </Heading>
  <div class="row">
    <div
      v-for="state in states"
      :key="state.key"
      class="col-12 col-md-6 col-lg-4 verification-state-card"
    >
      <h4>{{ state.label }}</h4>
      <p class="text-muted">{{ state.description }}</p>
      <Btn
        :data-test="`open-fleet-rsi-verification-modal-${state.key}`"
        @click="open(state)"
      >
        Open
      </Btn>
    </div>
  </div>
</template>

<style lang="scss" scoped>
.verification-state-card {
  margin-bottom: 1.5rem;
}
</style>
