<script lang="ts">
export default {
  name: "HangarDisplayOptionsModal",
};
</script>

<script lang="ts" setup>
import Btn from "@/shared/components/base/Btn/index.vue";
import Modal from "@/shared/components/AppModal/Inner/index.vue";
import FormCheckbox from "@/shared/components/base/FormCheckbox/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import { BtnSizesEnum } from "@/shared/components/base/Btn/types";
import {
  useHangarStore,
  HangarTableViewColsEnum,
} from "@/frontend/stores/hangar";

const { t } = useI18n();

const columnOptions = computed(() => {
  return Object.values(HangarTableViewColsEnum);
});

onMounted(() => {
  tableViewCols.value = hangarStore.tableViewCols;
});

const hangarStore = useHangarStore();

const tableViewCols = ref(hangarStore.tableViewCols);

watch(
  () => hangarStore.tableViewCols,
  () => {
    tableViewCols.value = hangarStore.tableViewCols;
  },
);

watch(
  () => tableViewCols.value,
  () => {
    hangarStore.setTableViewCols(tableViewCols.value);
  },
);

const displayAsGrid = () => {
  hangarStore.gridView = true;
};

const displayAsList = () => {
  hangarStore.gridView = false;
};
</script>

<template>
  <Modal :title="t('headlines.modals.models.displayOptions')">
    <div class="row">
      <div class="col-6">
        <Btn
          block
          :size="BtnSizesEnum.LARGE"
          :active="hangarStore.gridView"
          @click="displayAsGrid"
        >
          <i class="fas fa-th"></i>
          {{ t("actions.showGridView") }}
        </Btn>
      </div>
      <div class="col-6">
        <Btn
          block
          :size="BtnSizesEnum.LARGE"
          :active="!hangarStore.gridView"
          @click="displayAsList"
        >
          <i class="fad fa-list"></i>
          {{ t("actions.showTableView") }}
        </Btn>
      </div>
    </div>
    <hr />
    <div v-if="hangarStore.gridView" class="row">
      <div class="col-12">
        <FormCheckbox
          v-model="hangarStore.detailsVisible"
          name="detailsVisible"
          :label="t('actions.showDetails')"
        />
      </div>
    </div>
    <div v-else class="row">
      <div class="col-12">
        <fieldset>
          <legend>
            <h3>{{ t("labels.models.extraColumns") }}:</h3>
          </legend>
          <div class="row">
            <div
              v-for="option in columnOptions"
              :key="option"
              class="col-12 col-md-6"
            >
              <FormCheckbox
                v-model="tableViewCols"
                :checkbox-value="option"
                :name="option"
                :label="t('labels.hangarTable.columns.' + option)"
              />
            </div>
          </div>
        </fieldset>
      </div>
    </div>
  </Modal>
</template>
