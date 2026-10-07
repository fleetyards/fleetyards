<script lang="ts">
export default {
  name: "VisualTestsBuybackSyncModalPage",
};
</script>

<script lang="ts" setup>
import Btn from "@/shared/components/base/Btn/index.vue";
import Alert from "@/shared/components/base/Alert/index.vue";
import { AlertVariantsEnum } from "@/shared/components/base/Alert/types";
import { HeadingLevelEnum } from "@/shared/components/base/Heading/types";
import { useComlink } from "@/shared/composables/useComlink";
import { FleetyardsSyncAction } from "@/frontend/lib/FleetyardsSyncHandler";
import {
  type ExtensionStubConfig,
  signedInExtension,
  signedOutExtension,
  useVisualExtensionStub,
} from "@/frontend/composables/useVisualExtensionStub";

type StartScreen = {
  key: string;
  label: string;
  description: string;
  answers: ExtensionStubConfig;
};

/*
 * The real modal, opened against a stubbed extension. The stub never answers
 * `syncBuyback`, so Start cannot reach the real endpoint: it waits, then times
 * out.
 */
const startScreens: StartScreen[] = [
  {
    key: "start",
    label: "Before start",
    description: "A current extension, signed in to RSI: ready to sync.",
    answers: signedInExtension("VisualTester"),
  },
  {
    key: "signed-out",
    label: "Not signed in to RSI",
    description: "The extension finds no RSI session.",
    answers: signedOutExtension(),
  },
  {
    key: "outdated",
    label: "Extension too old",
    description:
      "A released version from before buy-backs: its health check has no payload.",
    answers: { [FleetyardsSyncAction.HEALTH]: { code: 200 } },
  },
  {
    key: "no-extension",
    label: "Without the extension",
    description: "Nothing answers the health check: the install links.",
    answers: {},
  },
];

const extension = useVisualExtensionStub();

const comlink = useComlink();

const open = (screen: StartScreen) => {
  extension.configure(screen.answers);

  comlink.emit("open-modal", {
    component: () =>
      import("@/frontend/components/Hangar/BuybackSyncBtn/Modal/index.vue"),
    fixed: true,
  });
};
</script>

<template>
  <Heading :level="HeadingLevelEnum.H2">Buy-back sync modal states</Heading>
  <Alert
    v-if="extension.realExtension.value"
    :variant="AlertVariantsEnum.WARNING"
    data-test="visual-real-extension"
  >
    A FleetYards Sync extension is installed in this browser and answers next to
    the stub, so the cards below show its answers. Disable it to see the stubbed
    states.
  </Alert>
  <div class="row">
    <div
      v-for="screen in startScreens"
      :key="screen.key"
      class="col-12 col-md-6 col-lg-4 sync-state-card"
    >
      <h4>{{ screen.label }}</h4>
      <p class="text-muted">{{ screen.description }}</p>
      <Btn
        :data-test="`open-buyback-sync-modal-${screen.key}`"
        @click="open(screen)"
      >
        Open
      </Btn>
    </div>
  </div>
</template>

<style lang="scss" scoped>
.sync-state-card {
  margin-bottom: 1.5rem;
}
</style>
