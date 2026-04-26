<script lang="ts">
export default {
  name: "InventoryItemFilterForm",
};
</script>

<script lang="ts" setup>
import FilterGroup from "@/shared/components/base/FilterGroup/index.vue";
import FormInput from "@/shared/components/base/FormInput/index.vue";
import { InputTypesEnum } from "@/shared/components/base/FormInput/types";
import Btn from "@/shared/components/base/Btn/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import { type FilterOption } from "@/services/fyApi";
import {
  useInventoryItemFilters,
  type InventoryItemQuery,
} from "@/frontend/composables/useInventoryItemFilters";

type Props = {
  hideQuicksearch?: boolean;
  updateCallback?: () => Promise<void>;
};

const props = withDefaults(defineProps<Props>(), {
  hideQuicksearch: false,
  updateCallback: undefined,
});

const { t } = useI18n();

const { filter, resetFilter, isFilterSelected, filters } =
  useInventoryItemFilters(props.updateCallback);

const prefillFormValues = (): InventoryItemQuery => {
  return {
    nameCont: filters.value.nameCont,
    categoryEq: filters.value.categoryEq,
    qualityGteq: filters.value.qualityGteq,
    qualityLteq: filters.value.qualityLteq,
  };
};

const form = ref<InventoryItemQuery>(prefillFormValues());

watch(
  () => form.value,
  () => {
    filter(form.value);
  },
  { deep: true },
);

const handleSubmit = () => {
  filter(form.value);
};

const categoryOptions: FilterOption[] = [
  {
    value: "commodity",
    label: t("labels.fleets.logistics.categories.commodity"),
  },
  {
    value: "component",
    label: t("labels.fleets.logistics.categories.component"),
  },
  {
    value: "weapon",
    label: t("labels.fleets.logistics.categories.weapon"),
  },
  {
    value: "equipment",
    label: t("labels.fleets.logistics.categories.equipment"),
  },
  {
    value: "ammunition",
    label: t("labels.fleets.logistics.categories.ammunition"),
  },
  {
    value: "consumable",
    label: t("labels.fleets.logistics.categories.consumable"),
  },
  { value: "other", label: t("labels.fleets.logistics.categories.other") },
];

defineExpose({ isFilterSelected });
</script>

<template>
  <form @submit.prevent="handleSubmit">
    <Teleport v-if="!hideQuicksearch" to="#header-left">
      <FormInput
        v-model="form.nameCont"
        name="search"
        :placeholder="t('labels.fleets.logistics.searchItems')"
        :no-label="true"
        :clearable="true"
      />
    </Teleport>

    <FormInput
      v-if="hideQuicksearch"
      v-model="form.nameCont"
      name="item-name"
      :placeholder="t('labels.fleets.logistics.searchItems')"
      :no-label="true"
      :clearable="true"
    />

    <FilterGroup
      v-model="form.categoryEq"
      :options="categoryOptions"
      :label="t('labels.fleets.logistics.category')"
      name="category"
      :nullable="true"
    />

    <div class="row">
      <div class="col-6">
        <FormInput
          v-model="form.qualityGteq"
          name="quality-gteq"
          :type="InputTypesEnum.NUMBER"
          :label="t('labels.fleets.logistics.qualityMin')"
          :no-placeholder="true"
          :min="0"
          :max="1000"
        />
      </div>
      <div class="col-6">
        <FormInput
          v-model="form.qualityLteq"
          name="quality-lteq"
          :type="InputTypesEnum.NUMBER"
          :label="t('labels.fleets.logistics.qualityMax')"
          :no-placeholder="true"
          :min="0"
          :max="1000"
        />
      </div>
    </div>

    <Btn :disabled="!isFilterSelected" :inline="true" @click="resetFilter">
      {{ t("actions.resetFilter") }}
    </Btn>
  </form>
</template>
