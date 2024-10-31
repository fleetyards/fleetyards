<script lang="ts">
export default {
  name: "ModelsTableConfigurationModal",
};
</script>

<script lang="ts" setup>
import Btn from "@/shared/components/base/Btn/index.vue";
import Modal from "@/shared/components/AppModal/Inner/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import { BtnSizesEnum, BtnTypesEnum } from "@/shared/components/base/Btn/types";
import { TableViewColsEnum } from "@/frontend/types";
import { useModelsStore } from "@/frontend/stores/models";

const { t } = useI18n();

type Form = {
  columns: TableViewColsEnum[];
};

const form = ref<Form>({
  columns: [],
});

const columnOptions = computed(() => {
  return Object.values(TableViewColsEnum);
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
</script>

<template>
  <Modal
    v-if="form"
    :title="t('headlines.modals.models.tableConfigurationModal')"
  >
    <form id="models-table-configuration" @submit.prevent="save">
      <div class="row">
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
                <Checkbox
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
    </form>
  </Modal>
</template>
