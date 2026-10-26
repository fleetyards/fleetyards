<script lang="ts">
export default {
  name: "AdminModelsDisplayOptionsModal",
};
</script>

<script lang="ts" setup>
import Modal from "@/shared/components/AppModal/Inner/index.vue";
import FormCheckbox from "@/shared/components/base/FormCheckbox/index.vue";
import SortFieldsFieldset from "@/frontend/components/SortFieldsFieldset/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import {
  useModelsStore,
  AdminModelTableViewColsEnum,
  AdminModelTableViewImageColsEnum,
  AdminModelSortFieldsEnum,
} from "@/admin/stores/models";
import { useAdminModelSortFields } from "@/admin/composables/useAdminModelSortFields";

const { t } = useI18n();

const modelsStore = useModelsStore();

const allSortFields = useAdminModelSortFields({ all: true });

const sortFields = computed({
  get: () => modelsStore.sortFields,
  set: (fields) =>
    modelsStore.setSortFields(fields as AdminModelSortFieldsEnum[]),
});

onMounted(() => {
  tableViewCols.value = modelsStore.tableViewCols;
  tableViewImageCols.value = modelsStore.tableViewImageCols;
});

const tableViewCols = ref(modelsStore.tableViewCols);
const tableViewImageCols = ref(modelsStore.tableViewImageCols);

const columnOptions = computed(() => {
  return Object.values(AdminModelTableViewColsEnum);
});

const imageColumnOptions = computed(() => {
  return Object.values(AdminModelTableViewImageColsEnum);
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
</script>

<template>
  <Modal :title="t('headlines.modals.models.displayOptions')">
    <div class="row">
      <div class="col-12">
        <SortFieldsFieldset v-model="sortFields" :fields="allSortFields" />
      </div>
    </div>
    <hr />
    <div class="row">
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
