<script lang="ts">
export default {
  name: "HangarFilterForm",
};
</script>

<script lang="ts" setup>
import FilterGroup from "@/shared/components/FilterGroup/index.vue";
import { hasActiveFilters } from "@/shared/utils/Filters";
import RadioList from "@/shared/components/base/RadioList/index.vue";
import BaseSelect from "@/shared/components/base/Select/index.vue";
import FormInput from "@/shared/components/base/FormInput/index.vue";
import ManufacturerSelect from "@/frontend/components/base/ManufacturerSelect/index.vue";
import ProductionStatusSelect from "@/frontend/components/base/ProductionStatusSelect/index.vue";
import ClassificationSelect from "@/frontend/components/base/ModelClassificationSelect/index.vue";
import FocusSelect from "@/frontend/components/base/ModelFocusSelect/index.vue";
import SizeSelect from "@/frontend/components/base/ModelSizeSelect/index.vue";
import WillItFitSelect from "@/frontend/components/base/ModelWillItFitSelect/index.vue";
import HangarGroupsSelect from "@/frontend/components/base/HangarGroupsSelect/index.vue";
import BoughtViaSelect from "@/frontend/components/base/BoughtViaSelect/index.vue";
import FormToggle from "@/shared/components/base/FormToggle/index.vue";
import Btn from "@/shared/components/base/Btn/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import { useFilterOptions } from "@/shared/composables/useFilterOptions";
import { useHangarFilters } from "@/frontend/composables/useHangarFilters";
import { type HangarQuery } from "@/services/fyApi";
import {
  InputSizesEnum,
  InputTypesEnum,
} from "@/shared/components/base/FormInput/types";

type Props = {
  hideQuicksearch?: boolean;
};

withDefaults(defineProps<Props>(), {
  hideQuicksearch: false,
});

const { t } = useI18n();

// The largest size a hangar holds is a capital ship's S12.
const weaponSizeOptions = Array.from({ length: 12 }, (_, index) => ({
  value: index + 1,
  label: `S${index + 1}`,
}));

// A filter read back from the URL is a string, and the select matches its
// options strictly.
const weaponSize = (value: unknown) => Number(value) || undefined;

const prefillFormValues = () => {
  return {
    searchCont: filters.value.searchCont,
    nameCont: filters.value.nameCont,
    onSaleEq: filters.value.onSaleEq,
    loanerEq: filters.value.loanerEq,
    bundledEq: filters.value.bundledEq,
    hiddenByUserEq: filters.value.hiddenByUserEq,
    publicEq: filters.value.publicEq,
    boughtViaEq: filters.value.boughtViaEq,
    priceLteq: filters.value.priceLteq,
    priceGteq: filters.value.priceGteq,
    pledgePriceLteq: filters.value.pledgePriceLteq,
    pledgePriceGteq: filters.value.pledgePriceGteq,
    cargoGteq: filters.value.cargoGteq,
    cargoLteq: filters.value.cargoLteq,
    maxWeaponSizeGteq: weaponSize(filters.value.maxWeaponSizeGteq),
    maxWeaponSizeLteq: weaponSize(filters.value.maxWeaponSizeLteq),
    lengthLteq: filters.value.lengthLteq,
    lengthGteq: filters.value.lengthGteq,
    beamLteq: filters.value.beamLteq,
    beamGteq: filters.value.beamGteq,
    heightLteq: filters.value.heightLteq,
    heightGteq: filters.value.heightGteq,
    willItFit: filters.value.willItFit,
    hangarGroupsIn: filters.value.hangarGroupsIn || [],
    hangarGroupsNotIn: filters.value.hangarGroupsNotIn || [],
    manufacturerIn: filters.value.manufacturerIn || [],
    classificationIn: filters.value.classificationIn || [],
    classificationNotIn: filters.value.classificationNotIn || [],
    focusIn: filters.value.focusIn || [],
    stealthEq: filters.value.stealthEq,
    productionStatusIn: filters.value.productionStatusIn || [],
    priceIn: filters.value.priceIn || [],
    pledgePriceIn: filters.value.pledgePriceIn || [],
    sizeIn: filters.value.sizeIn || [],
    withCargo: filters.value.withCargo,
  };
};

const setupForm = () => {
  form.value = prefillFormValues();
};

const { filter, resetFilter, isFilterSelected, filters } =
  useHangarFilters(setupForm);

const handleSubmit = () => {
  filter(form.value);
};

const form = ref<HangarQuery>(prefillFormValues());

watch(
  () => form.value,
  () => {
    filter(form.value);
  },
  { deep: true },
);

const { booleanOptions, priceOptions, pledgePriceOptions } = useFilterOptions();
const hasGroupFilters = (keys: string[]) =>
  hasActiveFilters(filters.value, keys);
</script>

<template>
  <form @submit.prevent="handleSubmit">
    <Teleport v-if="!hideQuicksearch" to="#header-left">
      <FormInput
        :size="InputSizesEnum.MEDIUM"
        v-model="form.searchCont"
        name="vehicle-search"
        translation-key="filters.vehicles.name"
        :no-label="true"
        :clearable="true"
      />
    </Teleport>
    <FilterGroup
      :label="t('filteredList.groups.ship')"
      :active="
        hasGroupFilters([
          'nameCont',
          'manufacturerIn',
          'productionStatusIn',
          'classificationIn',
          'focusIn',
          'stealthEq',
          'sizeIn',
        ])
      "
      default-open
    >
      <FormInput
        v-model="form.nameCont"
        name="vehicle-name"
        translation-key="filters.vehicles.name"
        :no-label="true"
        :clearable="true"
      />

      <ManufacturerSelect v-model="form.manufacturerIn" name="manufacturer" />

      <ProductionStatusSelect
        v-model="form.productionStatusIn"
        name="production-status"
      />

      <ClassificationSelect
        v-model="form.classificationIn"
        name="classification"
      />

      <FocusSelect v-model="form.focusIn" name="focus" />

      <RadioList
        v-model="form.stealthEq"
        :label="t('labels.filters.models.stealth')"
        :reset-label="t('labels.all')"
        :options="booleanOptions"
        name="stealth"
      />

      <SizeSelect v-model="form.sizeIn" name="size" />
    </FilterGroup>

    <FilterGroup
      :label="t('filteredList.groups.capacity')"
      :active="
        hasGroupFilters([
          'willItFit',
          'cargoGteq',
          'cargoLteq',
          'lengthGteq',
          'lengthLteq',
          'withCargo',
        ])
      "
    >
      <WillItFitSelect v-model="form.willItFit" name="will-it-fit" no-label />

      <div class="row">
        <div class="col-6">
          <FormInput
            v-model="form.cargoGteq"
            name="vehicle-cargo-gteq"
            type="number"
            :min="0"
            translation-key="filters.vehicles.cargoGt"
            :no-placeholder="true"
          />
        </div>
        <div class="col-6">
          <FormInput
            v-model="form.cargoLteq"
            name="vehicle-cargo-lteq"
            type="number"
            :min="0"
            translation-key="filters.vehicles.cargoLt"
            :no-placeholder="true"
          />
        </div>
      </div>

      <div class="row">
        <div class="col-6">
          <FormInput
            v-model="form.lengthGteq"
            name="vehicle-length-gteq"
            :type="InputTypesEnum.NUMBER"
            translation-key="filters.vehicles.lengthGt"
            :no-placeholder="true"
          />
        </div>
        <div class="col-6">
          <FormInput
            v-model="form.lengthLteq"
            name="vehicle-length-lteq"
            :type="InputTypesEnum.NUMBER"
            translation-key="filters.vehicles.lengthLt"
            :no-placeholder="true"
          />
        </div>
      </div>

      <FormToggle
        v-model="form.withCargo"
        :label="t('labels.filters.models.withCargo')"
        name="withCargo"
      />
    </FilterGroup>

    <FilterGroup
      :label="t('filteredList.groups.weapons')"
      :active="hasGroupFilters(['maxWeaponSizeGteq', 'maxWeaponSizeLteq'])"
    >
      <div class="row">
        <div class="col-6">
          <BaseSelect
            v-model="form.maxWeaponSizeGteq"
            :options="weaponSizeOptions"
            :label="t('labels.filters.vehicles.maxWeaponSizeGt')"
            name="vehicle-max-weapon-size-gteq"
            unsorted
          />
        </div>
        <div class="col-6">
          <BaseSelect
            v-model="form.maxWeaponSizeLteq"
            :options="weaponSizeOptions"
            :label="t('labels.filters.vehicles.maxWeaponSizeLt')"
            name="vehicle-max-weapon-size-lteq"
            unsorted
          />
        </div>
      </div>
    </FilterGroup>

    <FilterGroup
      :label="t('filteredList.groups.price')"
      :active="
        hasGroupFilters([
          'pledgePriceIn',
          'priceIn',
          'pledgePriceGteq',
          'pledgePriceLteq',
          'priceGteq',
          'priceLteq',
          'onSaleEq',
        ])
      "
    >
      <BaseSelect
        v-model="form.pledgePriceIn"
        :options="pledgePriceOptions"
        :label="t('labels.filters.models.pledgePrice')"
        name="pledge-price"
        :multiple="true"
        :no-label="true"
      />

      <BaseSelect
        v-model="form.priceIn"
        :options="priceOptions"
        :label="t('labels.filters.models.price')"
        name="price"
        :multiple="true"
        :no-label="true"
      />

      <div class="row">
        <div class="col-6">
          <FormInput
            v-model="form.pledgePriceGteq"
            name="vehicle-pledge-price-gteq"
            :type="InputTypesEnum.NUMBER"
            translation-key="filters.vehicles.pledgePriceGt"
            :no-placeholder="true"
          />
        </div>

        <div class="col-6">
          <FormInput
            v-model="form.pledgePriceLteq"
            name="vehicle-pledge-price-lteq"
            :type="InputTypesEnum.NUMBER"
            translation-key="filters.vehicles.pledgePriceLt"
            :no-placeholder="true"
          />
        </div>
      </div>

      <div class="row">
        <div class="col-6">
          <FormInput
            v-model="form.priceGteq"
            name="vehicle-price-gteq"
            :type="InputTypesEnum.NUMBER"
            translation-key="filters.vehicles.priceGt"
            :no-placeholder="true"
          />
        </div>
        <div class="col-6">
          <FormInput
            v-model="form.priceLteq"
            name="vehicle-price-lteq"
            :type="InputTypesEnum.NUMBER"
            translation-key="filters.vehicles.priceLt"
            :no-placeholder="true"
          />
        </div>
      </div>

      <RadioList
        v-model="form.onSaleEq"
        :label="t('labels.filters.models.onSale')"
        :reset-label="t('labels.all')"
        :options="booleanOptions"
        name="sale"
      />
    </FilterGroup>

    <FilterGroup
      :label="t('filteredList.groups.ownership')"
      :active="
        hasGroupFilters([
          'hangarGroupsIn',
          'boughtViaEq',
          'loanerEq',
          'bundledEq',
          'hiddenByUserEq',
          'publicEq',
        ])
      "
    >
      <HangarGroupsSelect v-model="form.hangarGroupsIn" name="will-it-fit" />

      <BoughtViaSelect v-model="form.boughtViaEq" name="bought-via" />

      <RadioList
        v-if="$route.name === 'hangar' || $route.name === 'hangar-wishlist'"
        v-model="form.loanerEq"
        :label="t('labels.filters.vehicles.loaner')"
        :reset-label="t('labels.hide')"
        :options="[
          {
            label: t('labels.show'),
            value: 'true',
          },
          {
            label: t('labels.only'),
            value: 'only',
          },
        ]"
        name="loaner"
      />

      <RadioList
        v-if="$route.name === 'hangar' || $route.name === 'hangar-wishlist'"
        v-model="form.bundledEq"
        :label="t('labels.filters.vehicles.bundled')"
        :reset-label="t('labels.all')"
        :options="[
          {
            label: t('labels.hide'),
            value: 'false',
          },
          {
            label: t('labels.only'),
            value: 'only',
          },
        ]"
        name="bundled"
      />

      <RadioList
        v-if="$route.name === 'hangar'"
        v-model="form.hiddenByUserEq"
        :label="t('labels.filters.vehicles.hiddenByUser')"
        :reset-label="t('labels.hide')"
        :options="[
          {
            label: t('labels.show'),
            value: 'true',
          },
          {
            label: t('labels.only'),
            value: 'only',
          },
        ]"
        name="hidden-by-user"
      />

      <RadioList
        v-if="$route.name === 'hangar' || $route.name === 'hangar-wishlist'"
        v-model="form.publicEq"
        :label="t('labels.filters.vehicles.public')"
        :reset-label="t('labels.all')"
        :options="booleanOptions"
        name="public"
      />
    </FilterGroup>
    <Btn :disabled="!isFilterSelected" :block="true" @click="resetFilter">
      <i class="fa-light fa-times" />
      {{ t("actions.resetFilter") }}
    </Btn>
  </form>
</template>
