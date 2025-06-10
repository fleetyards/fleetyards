<script lang="ts">
export default {
  name: "ModelsDisplayOptionsModal",
};
</script>

<script lang="ts" setup>
import Btn from "@/shared/components/base/Btn/index.vue";
import Modal from "@/shared/components/AppModal/Inner/index.vue";
import FormCheckbox from "@/shared/components/base/FormCheckbox/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import { BtnSizesEnum } from "@/shared/components/base/Btn/types";
import {
  useModelsStore,
  ModelTableViewColsEnum,
  ModelTableViewImageColsEnum,
} from "@/frontend/stores/models";

const { t } = useI18n();

const modelsStore = useModelsStore();

onMounted(() => {
  tableViewCols.value = modelsStore.tableViewCols;
  tableViewImageCols.value = modelsStore.tableViewImageCols;
});

const tableViewCols = ref(modelsStore.tableViewCols);
const tableViewImageCols = ref(modelsStore.tableViewImageCols);

const columnOptions = computed(() => {
  return Object.values(ModelTableViewColsEnum);
});

const imageColumnOptions = computed(() => {
  return Object.values(ModelTableViewImageColsEnum);
});

watch(
  () => modelsStore.tableViewCols,
  () => {
    tableViewCols.value = modelsStore.tableViewCols;
  },
);

watch(
  () => tableViewCols.value,
  () => {
    modelsStore.setTableViewCols(tableViewCols.value);
  },
);

watch(
  () => modelsStore.tableViewImageCols,
  () => {
    tableViewImageCols.value = modelsStore.tableViewImageCols;
  },
);

watch(
  () => tableViewImageCols.value,
  () => {
    modelsStore.setTableViewImageCols(tableViewImageCols.value);
  },
);

const displayAsGrid = () => {
  modelsStore.gridView = true;
};

const displayAsList = () => {
  modelsStore.gridView = false;
};
</script>

<template>
  <Modal :title="t('headlines.modals.models.displayOptions')">
    <div class="row">
      <div class="col-6">
        <Btn
          block
          :size="BtnSizesEnum.LARGE"
          :active="modelsStore.gridView"
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
          :active="!modelsStore.gridView"
          @click="displayAsList"
        >
          <i class="fad fa-list"></i>
          {{ t("actions.showTableView") }}
        </Btn>
      </div>
    </div>
    <hr />
    <div v-if="modelsStore.gridView" class="row">
      <div class="col-12">
        <FormCheckbox
          v-model="modelsStore.detailsVisible"
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
              v-for="option in imageColumnOptions"
              :key="option"
              class="col-12 col-md-6"
            >
              <FormCheckbox
                v-model="tableViewImageCols"
                :checkbox-value="option"
                :name="option"
                :label="t('labels.models.table.columns.' + option)"
              />
            </div>
            <div
              v-for="option in columnOptions"
              :key="option"
              class="col-12 col-md-6"
            >
              <FormCheckbox
                v-model="tableViewCols"
                :checkbox-value="option"
                :name="option"
                :label="t('labels.models.table.columns.' + option)"
              />
            </div>
          </div>
        </fieldset>
      </div>
    </div>
  </Modal>
</template>
