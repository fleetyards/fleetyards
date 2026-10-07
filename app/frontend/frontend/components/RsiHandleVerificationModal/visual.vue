<script lang="ts">
export default {
  name: "VisualTestsRsiVerificationModalPage",
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
  NullableRsiHandleVerifiedViaEnum,
  NullableUserRsiVerificationStatusEnum,
  type UserRsiVerification,
  getMyRsiVerificationQueryKey,
} from "@/services/fyApi";

const HANDLE = "VisualTester";

const unverified: UserRsiVerification = {
  handle: HANDLE,
  // Not a token the extension accepts, should a request ever reach one.
  token: "FLEETYARDS-DEMO",
  status: null,
  verified: false,
  verifiedVia: null,
  verifiedAt: null,
  checkedAt: null,
};

const verified: UserRsiVerification = {
  ...unverified,
  status: NullableUserRsiVerificationStatusEnum.VERIFIED,
  verified: true,
  verifiedVia: NullableRsiHandleVerifiedViaEnum.RSI_PROFILE,
  verifiedAt: "2026-10-01T12:00:00Z",
};

type State = {
  key: string;
  label: string;
  description: string;
  verification: UserRsiVerification;
  answers: ExtensionStubConfig;
};

const readyWith = (
  verifyWrite: ExtensionStubConfig[FleetyardsSyncAction],
): ExtensionStubConfig => ({
  ...signedInExtension(HANDLE),
  [FleetyardsSyncAction.VERIFY_WRITE]: verifyWrite,
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
    description:
      "An extension from before verification: it answers, but does not list verify-write.",
    verification: unverified,
    answers: {
      [FleetyardsSyncAction.HEALTH]: {
        code: 200,
        payload: { version: "1.2.6", actions: ["health", "identify", "sync"] },
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
        signedInExtension(HANDLE)[FleetyardsSyncAction.HEALTH],
    },
  },
  {
    key: "ready",
    label: "Ready",
    description:
      "Signed in to RSI as the handle being verified. Verifying sends a real check, so the button is better left alone here.",
    verification: unverified,
    answers: signedInExtension(HANDLE),
  },
  {
    key: "mismatch",
    label: "Signed in as someone else",
    description: "The browser's RSI account is not the handle being verified.",
    verification: unverified,
    answers: signedInExtension("SomeoneElse"),
  },
  {
    key: "signed-out",
    label: "Not signed in to RSI",
    description: "The extension finds no RSI session.",
    verification: unverified,
    answers: signedOutExtension(),
  },
  {
    key: "bio-too-long",
    label: "Bio too long",
    description: "Press Verify with extension: the token does not fit the bio.",
    verification: unverified,
    answers: readyWith({ code: 413 }),
  },
  {
    key: "bio-unreadable",
    label: "Bio unreadable",
    description:
      "Press Verify with extension: the bio has formatting the extension cannot keep.",
    verification: unverified,
    answers: readyWith({ code: 422 }),
  },
  {
    key: "verified",
    label: "Verified",
    description: "Verified through the RSI profile.",
    verification: verified,
    answers: {},
  },
];

const extension = useVisualExtensionStub();

const comlink = useComlink();

const queryClient = useQueryClient();

const queryKey = getMyRsiVerificationQueryKey();

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
      import("@/frontend/components/RsiHandleVerificationModal/index.vue"),
  });
};

// Not left behind for a signed-in session that opens the real modal next.
onBeforeUnmount(() => {
  queryClient.removeQueries({ queryKey });
  queryClient.setQueryDefaults(queryKey, {});
});
</script>

<template>
  <Heading :level="HeadingLevelEnum.H2">RSI verification modal states</Heading>
  <div class="row">
    <div
      v-for="state in states"
      :key="state.key"
      class="col-12 col-md-6 col-lg-4 verification-state-card"
    >
      <h4>{{ state.label }}</h4>
      <p class="text-muted">{{ state.description }}</p>
      <Btn
        :data-test="`open-rsi-verification-modal-${state.key}`"
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
