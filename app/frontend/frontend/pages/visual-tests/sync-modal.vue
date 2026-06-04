<script lang="ts">
export default {
  name: "VisualTestsSyncModalPage",
};
</script>

<script lang="ts" setup>
import Btn from "@/shared/components/base/Btn/index.vue";
import { BtnSizesEnum } from "@/shared/components/base/Btn/types";
import { HeadingLevelEnum } from "@/shared/components/base/Heading/types";
import type { SyncProcessStep } from "@/frontend/components/Hangar/SyncBtn/Result/types";
import type { HangarSyncResult, RsiHangarItemInput } from "@/services/fyApi";
import { useComlink } from "@/shared/composables/useComlink";

type State = {
  key: string;
  label: string;
  description: string;
  processSteps: SyncProcessStep[];
  currentPage: number;
  pledges: RsiHangarItemInput[];
  result?: HangarSyncResult;
  finished: boolean;
  finishedWithErrors: boolean;
};

const samplePledges = [
  { id: "1", type: "ship", name: "Aurora MR" },
  { id: "2", type: "ship", name: "300i" },
  { id: "3", type: "component", name: "Power Plant" },
  { id: "4", type: "upgrade", name: "Aurora MR > 300i" },
] as unknown as RsiHangarItemInput[];

const successResult = {
  importedVehicles: ["v-1", "v-2", "v-3"],
  foundVehicles: ["v-4", "v-5"],
  movedVehiclesToWanted: [],
  missingModels: [],
  importedComponents: ["c-1"],
  foundComponents: [],
  missingComponents: [],
  missingComponentVehicles: [],
  importedUpgrades: ["u-1"],
  foundUpgrades: [],
  missingUpgrades: [],
  missingUpgradeVehicles: [],
} as unknown as HangarSyncResult;

const partialResult = {
  importedVehicles: ["v-1"],
  foundVehicles: ["v-2"],
  movedVehiclesToWanted: ["v-3"],
  missingModels: ["Mystery Ship", "Unknown Variant"],
  importedComponents: [],
  foundComponents: [],
  missingComponents: ["Strange Module"],
  missingComponentVehicles: ["v-4"],
  importedUpgrades: [],
  foundUpgrades: [],
  missingUpgrades: ["Upgrade X"],
  missingUpgradeVehicles: ["v-5"],
} as unknown as HangarSyncResult;

const states: State[] = [
  {
    key: "idle",
    label: "Idle",
    description: "Both steps still pending.",
    processSteps: [
      { name: "fetchHangar", status: "pending" },
      { name: "submitData", status: "pending" },
    ],
    currentPage: 1,
    pledges: [],
    finished: false,
    finishedWithErrors: false,
  },
  {
    key: "fetching",
    label: "Fetching",
    description: "fetchHangar in progress with pledge counts.",
    processSteps: [
      { name: "fetchHangar", status: "processing" },
      { name: "submitData", status: "pending" },
    ],
    currentPage: 3,
    pledges: samplePledges,
    finished: false,
    finishedWithErrors: false,
  },
  {
    key: "submitting",
    label: "Submitting",
    description: "fetchHangar done, submitData running.",
    processSteps: [
      { name: "fetchHangar", status: "success" },
      { name: "submitData", status: "processing" },
    ],
    currentPage: 5,
    pledges: samplePledges,
    finished: false,
    finishedWithErrors: false,
  },
  {
    key: "finished-clean",
    label: "Finished — clean",
    description: "Everything imported, no missing items, support hint visible.",
    processSteps: [
      { name: "fetchHangar", status: "success" },
      { name: "submitData", status: "success" },
    ],
    currentPage: 5,
    pledges: samplePledges,
    result: successResult,
    finished: true,
    finishedWithErrors: false,
  },
  {
    key: "finished-missing",
    label: "Finished — with missing items",
    description: "Successful sync with unknown ships, components, upgrades.",
    processSteps: [
      { name: "fetchHangar", status: "success" },
      { name: "submitData", status: "success" },
    ],
    currentPage: 5,
    pledges: samplePledges,
    result: partialResult,
    finished: true,
    finishedWithErrors: false,
  },
  {
    key: "failed",
    label: "Failed",
    description: "submitData failed on the backend.",
    processSteps: [
      { name: "fetchHangar", status: "success" },
      { name: "submitData", status: "failure" },
    ],
    currentPage: 5,
    pledges: samplePledges,
    finished: false,
    finishedWithErrors: true,
  },
];

const comlink = useComlink();

const openState = (state: State) => {
  comlink.emit("open-modal", {
    component: () =>
      import("@/frontend/pages/visual-tests/sync-modal/StatePreview.vue"),
    props: {
      title: `Hangar Sync — ${state.label}`,
      processSteps: state.processSteps,
      currentPage: state.currentPage,
      pledges: state.pledges,
      result: state.result,
      finished: state.finished,
      finishedWithErrors: state.finishedWithErrors,
    },
  });
};
</script>

<template>
  <Heading :level="HeadingLevelEnum.H2">Sync modal states</Heading>
  <p>
    Each button opens the real <code>SyncResultPanel</code> wrapped in an
    <code>AppModal</code> with mocked input — same layout as production.
  </p>
  <div class="row">
    <div
      v-for="state in states"
      :key="state.key"
      class="col-12 col-md-6 col-lg-4 sync-state-card"
    >
      <h4>{{ state.label }}</h4>
      <p class="text-muted">{{ state.description }}</p>
      <Btn
        :size="BtnSizesEnum.SMALL"
        :data-test="`open-sync-modal-${state.key}`"
        @click="openState(state)"
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
