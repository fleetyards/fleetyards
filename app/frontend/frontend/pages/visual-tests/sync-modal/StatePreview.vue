<script lang="ts">
export default {
  name: "VisualTestsSyncModalStatePreview",
};
</script>

<script lang="ts" setup>
import Btn from "@/shared/components/base/Btn/index.vue";
import { BtnSizesEnum } from "@/shared/components/base/Btn/types";
import Modal from "@/shared/components/AppModal/Inner/index.vue";
import SyncResultPanel from "@/frontend/components/Hangar/SyncBtn/Result/index.vue";
import type { SyncProcessStep } from "@/frontend/components/Hangar/SyncBtn/Result/types";
import type { HangarSyncResult, RsiHangarItemInput } from "@/services/fyApi";
import { useComlink } from "@/shared/composables/useComlink";

type Props = {
  title?: string;
  processSteps: SyncProcessStep[];
  currentPage: number;
  pledges: RsiHangarItemInput[];
  result?: HangarSyncResult;
  finished: boolean;
  finishedWithErrors: boolean;
};

withDefaults(defineProps<Props>(), {
  title: "Hangar Sync",
  result: undefined,
});

const comlink = useComlink();

const hintDismissed = ref(false);

const close = () => {
  comlink.emit("close-modal", true);
};
</script>

<template>
  <Modal :title="title">
    <SyncResultPanel
      :process-steps="processSteps"
      :current-page="currentPage"
      :pledges="pledges"
      :result="result"
      :finished="finished"
      :finished-with-errors="finishedWithErrors"
      :show-support-hint="finished && !finishedWithErrors && !hintDismissed"
      @support-hint-dismiss="hintDismissed = true"
    />
    <template #footer>
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
    </template>
  </Modal>
</template>
