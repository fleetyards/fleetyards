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
import { useVisualApiMock } from "@/frontend/composables/useVisualApiMock";
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
  // What a check finds, answered by the mocked API.
  checkFinds?: NullableFleetRsiVerificationStatusEnum;
};

const readyWith = (
  orgVerifyWrite: ExtensionStubConfig[FleetyardsSyncAction] = {
    code: 200,
    payload: { sid: SID, changed: true },
  },
): ExtensionStubConfig => ({
  ...signedInExtension("VisualOfficer"),
  [FleetyardsSyncAction.ORG_VERIFY_WRITE]: orgVerifyWrite,
  [FleetyardsSyncAction.ORG_VERIFY_REMOVE]: {
    code: 200,
    payload: { sid: SID, changed: true },
  },
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
      "Signed in to RSI. Press Verify with extension: the check finds the token and the fleet is verified.",
    verification: unverified,
    answers: readyWith(),
    checkFinds: NullableFleetRsiVerificationStatusEnum.VERIFIED,
  },
  {
    key: "token-missing",
    label: "Check finds no token",
    description:
      "Press Verify with extension: the check answers next to the button that the token is not on the org page.",
    verification: unverified,
    answers: readyWith(),
    checkFinds: NullableFleetRsiVerificationStatusEnum.TOKEN_MISSING,
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

// The verification the open card shows, as the mocked API answers it.
let current = unverified;
let checkFinds: NullableFleetRsiVerificationStatusEnum =
  NullableFleetRsiVerificationStatusEnum.TOKEN_MISSING;

const answerWith = (verification: FleetRsiVerification) => {
  current = verification;

  return current;
};

const FLEET_PATH = `/fleets/${fleet.slug}/rsi-verification`;

useVisualApiMock([
  {
    method: "POST",
    path: new RegExp(`^${FLEET_PATH}/check$`),
    respond: () =>
      answerWith({
        ...current,
        status: NullableFleetRsiVerificationStatusEnum.PENDING,
        nextCheckAt: new Date(Date.now() + 60_000).toISOString(),
      }),
  },
  {
    // The modal polls while a check is pending: the next read has its answer.
    method: "GET",
    path: new RegExp(`^${FLEET_PATH}$`),
    respond: () =>
      answerWith(
        checkFinds === NullableFleetRsiVerificationStatusEnum.VERIFIED
          ? { ...verified, verifiedAt: new Date().toISOString() }
          : { ...current, status: checkFinds },
      ),
  },
  {
    method: "POST",
    path: new RegExp(`^${FLEET_PATH}$`),
    respond: () =>
      answerWith({ ...current, token: "FLEETYARDS-DEMO2", status: null }),
  },
  {
    method: "DELETE",
    path: new RegExp(`^${FLEET_PATH}$`),
    respond: () => answerWith(unverified),
  },
]);

const previousDefaults = queryClient.getQueryDefaults(queryKey);

/*
 * The modal loads the verification itself. Seeding it as fresh for good keeps
 * the modal from asking the API, which a visual test page is not signed in to.
 */
const open = (state: State) => {
  extension.configure(state.answers);
  current = state.verification;
  checkFinds =
    state.checkFinds ?? NullableFleetRsiVerificationStatusEnum.TOKEN_MISSING;
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
  queryClient.setQueryDefaults(queryKey, previousDefaults);
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
