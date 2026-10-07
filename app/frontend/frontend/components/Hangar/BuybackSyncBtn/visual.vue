<script lang="ts">
export default {
  name: "VisualTestsBuybackSyncModalPage",
};
</script>

<script lang="ts" setup>
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

type StartScreen = {
  key: string;
  label: string;
  description: string;
  answers: ExtensionStubConfig;
};

/*
 * The real modal, opened against a stubbed extension and a mocked API, so
 * nothing reaches the extension, RSI or the API: Start reads one page of
 * buy-backs, then RSI's end row, and the submission answers with a result.
 */
const BUYBACK_PAGE = `<div class="content-wrapper pledges buy-back"><section class="available-pledges"><ul class="pledges">${[
  ["1000001", "Standalone Ship - Cutlass Black"],
  ["1000002", "Package - Mustang Alpha Starter Pack"],
]
  .map(
    ([id, title]) =>
      `<li><article class="pledge"><h1 title="${title}">${title}</h1><a class="holosmallbtn" href="/pledge/buyback/${id}">Buy Back</a></article></li>`,
  )
  .join("")}</ul></section></div>`;

const END_PAGE =
  '<div class="content-wrapper pledges buy-back"><section class="available-pledges"><ul class="pledges"><li class="no-buy-backs">No pledges available</li></ul></section></div>';

useVisualApiMock([
  {
    method: "PUT",
    path: /^\/hangar\/sync-rsi-buybacks$/,
    respond: () => ({ total: 2, added: 2, removed: 0, detailsPending: [] }),
  },
]);
const startScreens: StartScreen[] = [
  {
    key: "start",
    label: "Before start",
    description:
      "A current extension, signed in to RSI. Start runs a demo sync against stubbed buy-back pages.",
    answers: {
      ...signedInExtension("VisualTester"),
      [FleetyardsSyncAction.SYNC_BUYBACK]: ({ page }) => ({
        code: 200,
        payload: page === 1 ? BUYBACK_PAGE : END_PAGE,
      }),
    },
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
