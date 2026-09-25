<script lang="ts">
export default {
  name: "HangarDisplayOptionsModal",
};
</script>

<script lang="ts" setup>
import Btn from "@/shared/components/base/Btn/index.vue";
import Modal from "@/shared/components/AppModal/Inner/index.vue";
import FormCheckbox from "@/shared/components/base/FormCheckbox/index.vue";
import FormToggle from "@/shared/components/base/FormToggle/index.vue";
import BaseSelect from "@/shared/components/base/Select/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import { useComlink } from "@/shared/composables/useComlink";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";
import { useHangarDefaultSortOptions } from "@/frontend/composables/useHangarDefaultSortOptions";
import { useSessionStore } from "@/frontend/stores/session";
import {
  useUpdateProfile,
  type NullableVehicleSortEnum,
} from "@/services/fyApi";
import { BtnSizesEnum } from "@/shared/components/base/Btn/types";
import {
  useHangarStore,
  HangarTableViewColsEnum,
  HangarTableViewImageColsEnum,
} from "@/frontend/stores/hangar";
import { useHangarSortFields } from "@/frontend/composables/useHangarSortFields";

const { t } = useI18n();

const columnOptions = computed(() => {
  return Object.values(HangarTableViewColsEnum);
});

const imageColumnOptions = computed(() => {
  return Object.values(HangarTableViewImageColsEnum);
});

onMounted(() => {
  tableViewCols.value = hangarStore.tableViewCols;
  tableViewImageCols.value = hangarStore.tableViewImageCols;
});

const hangarStore = useHangarStore();

const tableViewCols = ref(hangarStore.tableViewCols);

const allSortFields = useHangarSortFields({ all: true });

// Written straight to the store: unlike the column lists this one has no
// second place that sets it, so there is nothing to mirror back.
const sortFields = computed({
  get: () => hangarStore.sortFields,
  set: (fields) => hangarStore.setSortFields(fields),
});
const tableViewImageCols = ref(hangarStore.tableViewImageCols);

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

watch(
  () => hangarStore.tableViewImageCols,
  () => {
    tableViewImageCols.value = hangarStore.tableViewImageCols;
  },
);

watch(
  () => tableViewImageCols.value,
  () => {
    hangarStore.setTableViewImageCols(tableViewImageCols.value);
  },
);

const sessionStore = useSessionStore();

const comlink = useComlink();

const { displayAlert } = useAppNotifications();

const defaultSortOptions = useHangarDefaultSortOptions();

// Held here as well as on the user, so the select shows the new choice while
// the save is in flight rather than the old one until the user is re-read.
const defaultSort = ref<NullableVehicleSortEnum | null>(
  sessionStore.currentUser?.hangarDefaultSort ?? null,
);

watch(
  () => sessionStore.currentUser?.hangarDefaultSort,
  (value) => {
    defaultSort.value = value ?? null;
  },
);

const updateProfile = useUpdateProfile();

// Every other option here is this browser's alone and applies as it is
// changed. This one is stored on the account -- the public hangar opens in it
// too -- but it applies on change the same way, so the modal needs no save.
const updateDefaultSort = (value: NullableVehicleSortEnum | null) => {
  const previous = defaultSort.value;

  defaultSort.value = value;

  updateProfile
    .mutateAsync({ data: { hangarDefaultSort: value } })
    .then(() => {
      comlink.emit("user-update");
      comlink.emit("hangar-change");
    })
    .catch(() => {
      defaultSort.value = previous;

      displayAlert({ text: t("messages.updateHangar.failure") });
    });
};

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
          :active="hangarStore.gridView"
          @click="displayAsGrid"
          :size="BtnSizesEnum.LG"
        >
          <i class="fa-solid fa-th"></i>
          {{ t("actions.showGridView") }}
        </Btn>
      </div>
      <div class="col-6">
        <Btn
          block
          :active="!hangarStore.gridView"
          @click="displayAsList"
          :size="BtnSizesEnum.LG"
        >
          <i class="fa-duotone fa-list"></i>
          {{ t("actions.showTableView") }}
        </Btn>
      </div>
    </div>
    <hr />
    <div class="row">
      <div class="col-12">
        <BaseSelect
          :model-value="defaultSort"
          :options="defaultSortOptions"
          :label="t('labels.user.hangarDefaultSort')"
          :info="t('labels.user.hangarDefaultSortInfo')"
          name="hangarDefaultSort"
          :searchable="false"
          :nullable="false"
          unsorted
          @update:model-value="updateDefaultSort"
        />
      </div>
    </div>
    <div class="row">
      <div class="col-12">
        <fieldset>
          <legend>
            <h3>{{ t("labels.hangarTable.sortOptions") }}:</h3>
          </legend>
          <div class="row">
            <div
              v-for="field in allSortFields"
              :key="field.name"
              class="col-12 col-md-6"
            >
              <FormCheckbox
                v-model="sortFields"
                :checkbox-value="field.name"
                :name="`sort-${field.name}`"
                :label="field.label"
              />
            </div>
          </div>
        </fieldset>
      </div>
    </div>
    <hr />
    <div v-if="hangarStore.gridView" class="row">
      <div class="col-12">
        <FormToggle
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
              v-for="option in imageColumnOptions"
              :key="option"
              class="col-12 col-md-6"
            >
              <FormCheckbox
                v-model="tableViewImageCols"
                :checkbox-value="option"
                :name="option"
                :label="t('labels.hangarTable.columns.' + option)"
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
                :label="t('labels.hangarTable.columns.' + option)"
              />
            </div>
          </div>
        </fieldset>
      </div>
    </div>
  </Modal>
</template>
