<script lang="ts">
export default {
  name: "FleetContractsDisplayOptionsModal",
};
</script>

<script lang="ts" setup>
import Modal from "@/shared/components/AppModal/Inner/index.vue";
import Btn from "@/shared/components/base/Btn/index.vue";
import { BtnSizesEnum } from "@/shared/components/base/Btn/types";
import { useI18n } from "@/shared/composables/useI18n";
import { useContractsStore } from "@/frontend/stores/contracts";

const { t } = useI18n();
const contractsStore = useContractsStore();
</script>

<template>
  <Modal :title="t('headlines.modals.models.displayOptions')">
    <div class="row">
      <div class="col-6">
        <Btn
          block
          :active="contractsStore.gridView"
          :size="BtnSizesEnum.LG"
          data-test="contracts-grid-view"
          @click="contractsStore.gridView = true"
        >
          <i class="fa-solid fa-th" />
          {{ t("actions.showGridView") }}
        </Btn>
      </div>
      <div class="col-6">
        <Btn
          block
          :active="!contractsStore.gridView"
          :size="BtnSizesEnum.LG"
          data-test="contracts-list-view"
          @click="contractsStore.gridView = false"
        >
          <i class="fa-duotone fa-list" />
          {{ t("actions.showTableView") }}
        </Btn>
      </div>
    </div>
  </Modal>
</template>
