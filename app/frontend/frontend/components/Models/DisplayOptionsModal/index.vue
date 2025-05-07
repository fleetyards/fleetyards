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
} from "@/frontend/stores/models";

const { t } = useI18n();

type Form = {
  columns: ModelTableViewColsEnum[];
};

const form = ref<Form>({
  columns: [],
});

const columnOptions = computed(() => {
  return Object.values(ModelTableViewColsEnum);
});

onMounted(() => {
  setupForm();
});

const modelsStore = useModelsStore();

const setupForm = () => {
  form.value = {
    columns: modelsStore.tableViewCols,
  };
};

watch(
  () => modelsStore.tableViewCols,
  () => {
    setupForm();
  },
);

watch(
  () => form.value.columns,
  () => {
    modelsStore.setTableViewCols(form.value.columns);
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
  <Modal v-if="form" :title="t('headlines.modals.models.displayOptions')">
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
              v-for="option in columnOptions"
              :key="option"
              class="col-12 col-md-6"
            >
              <FormCheckbox
                v-model="form.columns"
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
