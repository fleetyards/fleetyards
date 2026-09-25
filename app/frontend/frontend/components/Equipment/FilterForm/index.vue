<script lang="ts">
export default {
  name: "EquipmentFilterForm",
};
</script>

<script lang="ts" setup>
import BaseSelect from "@/shared/components/base/Select/index.vue";
import FormInput from "@/shared/components/base/FormInput/index.vue";
import Btn from "@/shared/components/base/Btn/index.vue";
import { InputSizesEnum } from "@/shared/components/base/FormInput/types";
import { useI18n } from "@/shared/composables/useI18n";
import ManufacturerSelect from "@/frontend/components/base/ManufacturerSelect/index.vue";
import { useEquipmentFilters } from "@/frontend/composables/useEquipmentFilters";
import {
  type EquipmentQuery,
  useEquipmentItemTypesFilters,
  useEquipmentSlotsFilters,
  useEquipmentSubTypesFilters,
  useEquipmentTypesFilters,
  useEquipmentWeaponClassesFilters,
} from "@/services/fyApi";

type Props = {
  hideQuicksearch?: boolean;
};

withDefaults(defineProps<Props>(), {
  hideQuicksearch: false,
});

const { t } = useI18n();

// A single value in the URL comes back from `route.query` as a string, not an
// array, so a multi-select handed one straight through gets a string where it
// expects a list. Every click-to-filter link in a row lands on exactly that.
const asList = <T extends string>(value: unknown): T[] => {
  if (Array.isArray(value)) return value as T[];

  return value ? [value as T] : [];
};

const prefillFormValues = (): EquipmentQuery => ({
  nameOrSlugCont: filters.value.nameOrSlugCont,
  manufacturerSlugIn: asList(filters.value.manufacturerSlugIn),
  equipmentTypeIn: asList(filters.value.equipmentTypeIn),
  itemTypeIn: asList(filters.value.itemTypeIn),
  subTypeIn: asList(filters.value.subTypeIn),
  weaponClassIn: asList(filters.value.weaponClassIn),
  slotIn: asList(filters.value.slotIn),
});

const setupForm = () => {
  form.value = prefillFormValues();
};

const { filter, resetFilter, isFilterSelected, filters } =
  useEquipmentFilters(setupForm);

const form = ref<EquipmentQuery>(prefillFormValues());

watch(
  () => form.value,
  () => filter(form.value),
  { deep: true },
);

const handleSubmit = () => {
  filter(form.value);
};

const { data: types } = useEquipmentTypesFilters();

// Narrowed by the chosen types: unnarrowed the list is over a hundred item
// types, most of them clothing, which buries the dozen a weapon search wants.
const itemTypeParams = computed(() => {
  const chosen = form.value.equipmentTypeIn || [];

  return chosen.length ? { q: { equipmentTypeIn: chosen } } : {};
});

const { data: itemTypes } = useEquipmentItemTypesFilters(itemTypeParams);

// An item type the control cannot show is one the reader cannot remove, so a
// type dropped from the selection takes its item types with it. Only once
// options have arrived: pruning before the answer would clear a selection
// restored from the URL. An answer that is empty still prunes -- a type with
// no item types leaves nothing selectable.
watch(itemTypes, (options) => {
  if (!options) return;

  const available = new Set(options.map((option) => option.value));
  const chosen = form.value.itemTypeIn || [];
  const kept = chosen.filter((value) => available.has(value));

  if (kept.length !== chosen.length) {
    form.value = { ...form.value, itemTypeIn: kept };
  }
});

const { data: subTypes } = useEquipmentSubTypesFilters();
const { data: weaponClasses } = useEquipmentWeaponClassesFilters();
const { data: slots } = useEquipmentSlotsFilters();
</script>

<template>
  <form @submit.prevent="handleSubmit">
    <Teleport v-if="!hideQuicksearch" to="#header-left">
      <FormInput
        v-model="form.nameOrSlugCont"
        :size="InputSizesEnum.MEDIUM"
        name="search"
        translation-key="filters.equipment.name"
        :no-label="true"
        :clearable="true"
      />
    </Teleport>

    <ManufacturerSelect v-model="form.manufacturerSlugIn" name="manufacturer" />

    <BaseSelect
      v-model="form.equipmentTypeIn"
      name="equipmentType"
      :options="types ?? []"
      :label="t('labels.filters.equipment.equipmentType')"
      :no-label="true"
      multiple
    />

    <BaseSelect
      v-model="form.itemTypeIn"
      name="itemType"
      :options="itemTypes ?? []"
      :label="t('labels.filters.equipment.itemType')"
      :no-label="true"
      multiple
    />

    <BaseSelect
      v-model="form.subTypeIn"
      name="subType"
      :options="subTypes ?? []"
      :label="t('labels.filters.equipment.subType')"
      :no-label="true"
      multiple
    />

    <BaseSelect
      v-model="form.slotIn"
      name="slot"
      :options="slots ?? []"
      :label="t('labels.filters.equipment.slot')"
      :no-label="true"
      multiple
    />

    <BaseSelect
      v-model="form.weaponClassIn"
      name="weaponClass"
      :options="weaponClasses ?? []"
      :label="t('labels.filters.equipment.weaponClass')"
      :no-label="true"
      multiple
    />

    <br />
    <Btn :disabled="!isFilterSelected" :block="true" @click="resetFilter">
      <i class="fa-light fa-times" />
      {{ t("actions.resetFilter") }}
    </Btn>
  </form>
</template>
