<script lang="ts">
export default {
  name: "VisualTestsSupportHintSyncModalPreview",
};
</script>

<script lang="ts" setup>
import Btn from "@/shared/components/base/Btn/index.vue";
import { BtnSizesEnum } from "@/shared/components/base/Btn/types";
import Modal from "@/shared/components/AppModal/Inner/index.vue";
import SupportHint from "@/shared/components/SupportHint/index.vue";
import { useComlink } from "@/shared/composables/useComlink";

const comlink = useComlink();

const hintDismissed = ref(false);

const close = () => {
  comlink.emit("close-modal", true);
};
</script>

<template>
  <Modal title="Hangar Sync">
    <div class="sync-preview-body">
      <ul class="list-unstyled">
        <li><i class="fa-light fa-check text-success" /> Fetch Hangar</li>
        <li><i class="fa-light fa-check text-success" /> Submit Data</li>
      </ul>
      <dl class="row">
        <dt class="col-sm-7">Imported Vehicles:</dt>
        <dd class="col-sm-5 text-right">12</dd>
        <dt class="col-sm-7">Found Vehicles:</dt>
        <dd class="col-sm-5 text-right">8</dd>
      </dl>
      <transition name="fade">
        <SupportHint
          v-if="!hintDismissed"
          inline
          context="hangarSync"
          :meta="{ count: 12 }"
          @dismiss="hintDismissed = true"
        />
      </transition>
    </div>
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

<style lang="scss" scoped>
.sync-preview-body {
  padding: 0 1rem;
}
</style>
