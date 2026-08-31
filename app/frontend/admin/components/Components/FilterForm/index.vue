<script lang="ts">
export default {
  name: "ComponentsFilterForm",
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
import ComponentClassSelect from "@/admin/components/base/ComponentClassSelect/index.vue";
import ComponentItemTypeSelect from "@/admin/components/base/ComponentItemTypeSelect/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import { useFilterOptions } from "@/shared/composables/useFilterOptions";
import { type ComponentQuery } from "@/services/fyAdminApi";
import { useComponentFilters } from "@/admin/composables/useComponentFilters";

const { t } = useI18n();

const { booleanOptions } = useFilterOptions();

const prefillFormValues = () => {
  return {
    nameCont: filters.value.nameCont,
    itemTypeIn: filters.value.itemTypeIn || [],
    storeImageBlank: filters.value.storeImageBlank,
    componentClassIn: filters.value.componentClassIn || [],
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
  useComponentFilters(setupForm);

const handleSubmit = () => {
  filter(form.value);
};

const form = ref<ComponentQuery>(prefillFormValues());

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
        translation-key="filters.components.name"
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

    <ComponentClassSelect
      v-model="form.componentClassIn"
      name="component-class"
    />

    <ComponentItemTypeSelect v-model="form.itemTypeIn" name="item-type" />

    <RadioList
      v-model="form.storeImageBlank"
      :label="t('labels.filters.components.storeImageBlank')"
      :reset-label="t('labels.all')"
      :options="booleanOptions"
      name="storeImageBlank"
    />

    <div class="row">
      <div class="col-6">
        <FormInput
          v-model="form.buyPriceGteq"
          name="component-buy-price-gteq"
          :type="InputTypesEnum.NUMBER"
          translation-key="filters.components.buyPriceGt"
          :no-placeholder="true"
        />
      </div>
      <div class="col-6">
        <FormInput
          v-model="form.buyPriceLteq"
          name="component-buy-price-lteq"
          :type="InputTypesEnum.NUMBER"
          translation-key="filters.components.buyPriceLt"
          :no-placeholder="true"
        />
      </div>
    </div>

    <div class="row">
      <div class="col-6">
        <FormInput
          v-model="form.sellPriceGteq"
          name="component-sell-price-gteq"
          :type="InputTypesEnum.NUMBER"
          translation-key="filters.components.sellPriceGt"
          :no-placeholder="true"
        />
      </div>
      <div class="col-6">
        <FormInput
          v-model="form.sellPriceLteq"
          name="component-sell-price-lteq"
          :type="InputTypesEnum.NUMBER"
          translation-key="filters.components.sellPriceLt"
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
