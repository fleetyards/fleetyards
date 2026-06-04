<script lang="ts">
export default {
  name: "VisualTestsSupportHintSyncModalPreview",
};
</script>

<script lang="ts" setup>
import Btn from "@/shared/components/base/Btn/index.vue";
import { BtnSizesEnum } from "@/shared/components/base/Btn/types";
import Modal from "@/shared/components/AppModal/Inner/index.vue";
import SyncResultPanel from "@/frontend/components/Hangar/SyncBtn/Result/index.vue";
import type { SyncProcessStep } from "@/frontend/components/Hangar/SyncBtn/Result/types";
import type { HangarSyncResult } from "@/services/fyApi";
import { useComlink } from "@/shared/composables/useComlink";

const comlink = useComlink();

const hintDismissed = ref(false);

const processSteps: SyncProcessStep[] = [
  { name: "fetchHangar", status: "success" },
  { name: "submitData", status: "success" },
];

const result = {
  importedVehicles: ["vehicle-1", "vehicle-2", "vehicle-3"],
  foundVehicles: ["vehicle-4", "vehicle-5"],
  movedVehiclesToWanted: [],
  missingModels: ["Mystery Ship"],
  importedComponents: [],
  foundComponents: [],
  missingComponents: [],
  missingComponentVehicles: [],
  importedUpgrades: [],
  foundUpgrades: [],
  missingUpgrades: [],
  missingUpgradeVehicles: [],
} as unknown as HangarSyncResult;

const close = () => {
  comlink.emit("close-modal", true);
};
</script>

<template>
  <Modal title="Hangar Sync">
    <SyncResultPanel
      :process-steps="processSteps"
      :current-page="1"
      :pledges="[]"
      :result="result"
      :finished="true"
      :finished-with-errors="false"
      :show-support-hint="!hintDismissed"
      @support-hint-dismiss="hintDismissed = true"
    />
    <div class="page-actions page-actions-block">
      <Btn
        v-if="hintDismissed"
        :size="BtnSizesEnum.SMALL"
        :inline="true"
        data-test="sync-modal-preview-reset"
        @click="hintDismissed = false"
      >
        Reset hint
      </Btn>
      <Btn :size="BtnSizesEnum.SMALL" :inline="true" @click="close">
        Close
      </Btn>
    </div>
  </Modal>
</template>
