<script lang="ts">
export default {
  name: "FleetDisplayOptionsModal",
};
</script>

<script lang="ts" setup>
import Btn from "@/shared/components/base/Btn/index.vue";
import Modal from "@/shared/components/AppModal/Inner/index.vue";
import FormCheckbox from "@/shared/components/base/FormCheckbox/index.vue";
import FormToggle from "@/shared/components/base/FormToggle/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import { BtnSizesEnum } from "@/shared/components/base/Btn/types";
import {
  useFleetStore,
  FleetTableViewColsEnum,
  FleetTableViewImageColsEnum,
} from "@/frontend/stores/fleet";

const { t } = useI18n();

const columnOptions = computed(() => {
  return Object.values(FleetTableViewColsEnum);
});

const imageColumnOptions = computed(() => {
  return Object.values(FleetTableViewImageColsEnum);
});

const fleetStore = useFleetStore();

const tableViewCols = ref(fleetStore.tableViewCols);
const tableViewImageCols = ref(fleetStore.tableViewImageCols);

onMounted(() => {
  tableViewCols.value = fleetStore.tableViewCols;
  tableViewImageCols.value = fleetStore.tableViewImageCols;
});

watch(
  () => fleetStore.tableViewCols,
  () => {
    tableViewCols.value = fleetStore.tableViewCols;
  },
);

watch(
  () => tableViewCols.value,
  () => {
    fleetStore.setTableViewCols(tableViewCols.value);
  },
);

watch(
  () => fleetStore.tableViewImageCols,
  () => {
    tableViewImageCols.value = fleetStore.tableViewImageCols;
  },
);

watch(
  () => tableViewImageCols.value,
  () => {
    fleetStore.setTableViewImageCols(tableViewImageCols.value);
  },
);

const displayAsGrid = () => {
  fleetStore.gridView = true;
};

const displayAsList = () => {
  fleetStore.gridView = false;
};
</script>

<template>
  <Modal :title="t('headlines.modals.models.displayOptions')">
    <div class="row">
      <div class="col-6">
        <Btn
          block
          :size="BtnSizesEnum.LARGE"
          :active="fleetStore.gridView"
          @click="displayAsGrid"
        >
          <i class="fa-solid fa-th"></i>
          {{ t("actions.showGridView") }}
        </Btn>
      </div>
      <div class="col-6">
        <Btn
          block
          :size="BtnSizesEnum.LARGE"
          :active="!fleetStore.gridView"
          @click="displayAsList"
        >
          <i class="fa-duotone fa-list"></i>
          {{ t("actions.showTableView") }}
        </Btn>
      </div>
    </div>
    <hr />
    <div class="row">
      <div class="col-6">
        <FormToggle
          v-model="fleetStore.grouped"
          name="grouped"
          :label="t('actions.groupedByModel')"
        />
      </div>
      <div v-if="fleetStore.gridView" class="col-6">
        <FormToggle
          v-model="fleetStore.detailsVisible"
          name="detailsVisible"
          :label="t('actions.showDetails')"
        />
      </div>
    </div>
    <template v-if="!fleetStore.gridView">
      <hr />
      <div class="row">
        <div class="col-12">
          <fieldset>
            <legend>
              <h3>{{ t("labels.fleetTable.extraColumns") }}:</h3>
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
                  :label="t('labels.fleetTable.columns.' + option)"
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
                  :label="t('labels.fleetTable.columns.' + option)"
                />
              </div>
            </div>
          </fieldset>
        </div>
      </div>
    </template>
  </Modal>
</template>
