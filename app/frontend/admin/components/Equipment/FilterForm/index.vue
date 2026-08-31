<script lang="ts">
export default {
  name: "EquipmentFilterForm",
};
</script>

<script lang="ts" setup>
import {
  InputSizesEnum,
  InputTypesEnum,
} from "@/shared/components/base/FormInput/types";
import FormInput from "@/shared/components/base/FormInput/index.vue";
import Btn from "@/shared/components/base/Btn/index.vue";
import RadioList from "@/shared/components/base/RadioList/index.vue";
import ManufacturerSelect from "@/admin/components/base/ManufacturerSelect/index.vue";
import EquipmentSlotSelect from "@/admin/components/base/EquipmentSlotSelect/index.vue";
import EquipmentTypeSelect from "@/admin/components/base/EquipmentTypeSelect/index.vue";
import EquipmentItemTypeSelect from "@/admin/components/base/EquipmentItemTypeSelect/index.vue";
import EquipmentWeaponClassSelect from "@/admin/components/base/EquipmentWeaponClassSelect/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import { useFilterOptions } from "@/shared/composables/useFilterOptions";
import { type EquipmentQuery } from "@/services/fyAdminApi";
import { useEquipmentFilters } from "@/admin/composables/useEquipmentFilters";

const { t } = useI18n();

const { booleanOptions } = useFilterOptions();

const prefillFormValues = () => {
  return {
    nameCont: filters.value.nameCont,
    equipmentTypeIn: filters.value.equipmentTypeIn || [],
    itemTypeIn: filters.value.itemTypeIn || [],
    weaponClassIn: filters.value.weaponClassIn || [],
    slotIn: filters.value.slotIn || [],
    storeImageBlank: filters.value.storeImageBlank,
    manufacturerIdIn: filters.value.manufacturerIdIn || [],
    buyPriceGteq: filters.value.buyPriceGteq,
    buyPriceLteq: filters.value.buyPriceLteq,
    sellPriceGteq: filters.value.sellPriceGteq,
    sellPriceLteq: filters.value.sellPriceLteq,
  };
};

const setupForm = () => {
  form.value = prefillFormValues();
};

const { filter, resetFilter, isFilterSelected, filters } =
  useEquipmentFilters(setupForm);

const handleSubmit = () => {
  filter(form.value);
};

const form = ref<EquipmentQuery>(prefillFormValues());

watch(
  () => form.value,
  () => {
    filter(form.value);
  },
  { deep: true },
);
</script>

<template>
  <form @submit.prevent="handleSubmit">
    <Teleport to="#header-left">
      <FormInput
        :size="InputSizesEnum.MEDIUM"
        v-model="form.nameCont"
        name="search"
        translation-key="filters.equipment.name"
        :no-label="true"
        :clearable="true"
        inline
      />
    </Teleport>

    <ManufacturerSelect
      v-model="form.manufacturerIdIn"
      value-attr="id"
      name="manufacturer"
    />

    <EquipmentTypeSelect v-model="form.equipmentTypeIn" name="equipment-type" />

    <EquipmentItemTypeSelect v-model="form.itemTypeIn" name="item-type" />

    <EquipmentWeaponClassSelect
      v-model="form.weaponClassIn"
      name="weapon-class"
    />

    <EquipmentSlotSelect v-model="form.slotIn" name="slot" />

    <RadioList
      v-model="form.storeImageBlank"
      :label="t('labels.filters.equipment.storeImageBlank')"
      :reset-label="t('labels.all')"
      :options="booleanOptions"
      name="storeImageBlank"
    />

    <div class="row">
      <div class="col-6">
        <FormInput
          v-model="form.buyPriceGteq"
          name="equipment-buy-price-gteq"
          :type="InputTypesEnum.NUMBER"
          translation-key="filters.equipment.buyPriceGt"
          :no-placeholder="true"
        />
      </div>
      <div class="col-6">
        <FormInput
          v-model="form.buyPriceLteq"
          name="equipment-buy-price-lteq"
          :type="InputTypesEnum.NUMBER"
          translation-key="filters.equipment.buyPriceLt"
          :no-placeholder="true"
        />
      </div>
    </div>

    <div class="row">
      <div class="col-6">
        <FormInput
          v-model="form.sellPriceGteq"
          name="equipment-sell-price-gteq"
          :type="InputTypesEnum.NUMBER"
          translation-key="filters.equipment.sellPriceGt"
          :no-placeholder="true"
        />
      </div>
      <div class="col-6">
        <FormInput
          v-model="form.sellPriceLteq"
          name="equipment-sell-price-lteq"
          :type="InputTypesEnum.NUMBER"
          translation-key="filters.equipment.sellPriceLt"
          :no-placeholder="true"
        />
      </div>
    </div>

    <br />
    <Btn :disabled="!isFilterSelected" :block="true" @click="resetFilter">
      <i class="fa-light fa-times" />
      {{ t("actions.resetFilter") }}
    </Btn>
  </form>
</template>
