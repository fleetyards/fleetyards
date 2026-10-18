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
import { useBuybackSync } from "@/frontend/composables/useBuybackSync";
import { useBuybackDetailsSync } from "@/frontend/composables/useBuybackDetailsSync";
import type { RsiBuybackItemInput } from "@/services/fyApi";
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

type RunState = {
  key: string;
  label: string;
  description: string;
  apply: () => void;
};

const buybackSync = useBuybackSync();
const details = useBuybackDetailsSync();

const samplePledges = (count: number) =>
  Array.from({ length: count }, (_, index) => ({
    id: String(1000001 + index),
    name: `Standalone Ship - Pledge ${index + 1}`,
    page: Math.floor(index / 10) + 1,
  })) as unknown as RsiBuybackItemInput[];

// The run's state is shared and outlives the modal, so a preview sets it and
// opens the real modal on it, as one opened on a run going in the background.
const setRun = ({
  status,
  page = 1,
  found = 0,
  result,
  pricesDone,
  pricesTotal,
  pricesRunning = false,
}: {
  status: "fetching" | "submitting" | "finished" | "failed";
  page?: number;
  found?: number;
  result?: { added: number; removed: number };
  pricesDone?: number;
  pricesTotal?: number;
  pricesRunning?: boolean;
}) => {
  buybackSync.status.value = status;
  buybackSync.currentPage.value = page;
  buybackSync.buybacks.value = samplePledges(found);
  buybackSync.result.value = result
    ? { total: found, ...result, detailsPending: [] }
    : undefined;
  buybackSync.detailsStarted.value = pricesTotal !== undefined;
  details.total.value = pricesTotal ?? 0;
  details.done.value = pricesDone ?? 0;
  details.status.value = pricesRunning
    ? "running"
    : pricesTotal !== undefined
      ? "finished"
      : "idle";
};

const runStates: RunState[] = [
  {
    key: "reading",
    label: "Reading the list",
    description: "Page 4 of the buy-back list, 24 pledges so far.",
    apply: () => setRun({ status: "fetching", page: 4, found: 24 }),
  },
  {
    key: "saving",
    label: "Saving",
    description: "The whole list is read and being submitted.",
    apply: () => setRun({ status: "submitting", page: 4, found: 37 }),
  },
  {
    key: "prices",
    label: "Reading prices",
    description: "The list is saved; 12 of 37 prices are read.",
    apply: () =>
      setRun({
        status: "finished",
        page: 4,
        found: 37,
        result: { added: 3, removed: 1 },
        pricesDone: 12,
        pricesTotal: 37,
        pricesRunning: true,
      }),
  },
  {
    key: "finished",
    label: "Finished",
    description: "List and prices are in.",
    apply: () =>
      setRun({
        status: "finished",
        page: 4,
        found: 37,
        result: { added: 3, removed: 1 },
        pricesDone: 37,
        pricesTotal: 37,
      }),
  },
  {
    key: "failed",
    label: "Failed",
    description: "A run that failed before this modal opened on it.",
    apply: () => setRun({ status: "failed", page: 2, found: 10 }),
  },
];

const extension = useVisualExtensionStub();

const comlink = useComlink();

const openRun = (state: RunState) => {
  extension.configure(startScreens[0].answers);
  state.apply();

  comlink.emit("open-modal", {
    component: () =>
      import("@/frontend/components/Hangar/BuybackSyncBtn/Modal/index.vue"),
  });
};

// A run preview opened before leaves its state running, which a plain reset
// keeps.
const open = (screen: StartScreen) => {
  buybackSync.reset(true);
  details.status.value = "idle";
  extension.configure(screen.answers);

  comlink.emit("open-modal", {
    component: () =>
      import("@/frontend/components/Hangar/BuybackSyncBtn/Modal/index.vue"),
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
  <Heading :level="HeadingLevelEnum.H3">A run</Heading>
  <div class="row">
    <div
      v-for="state in runStates"
      :key="state.key"
      class="col-12 col-md-6 col-lg-4 sync-state-card"
    >
      <h4>{{ state.label }}</h4>
      <p class="text-muted">{{ state.description }}</p>
      <Btn
        :data-test="`open-buyback-sync-modal-${state.key}`"
        @click="openRun(state)"
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
