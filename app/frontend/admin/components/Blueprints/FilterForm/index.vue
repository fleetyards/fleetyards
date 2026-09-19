<script lang="ts">
export default {
  name: "BlueprintsFilterForm",
};
</script>

<script lang="ts" setup>
import { InputSizesEnum } from "@/shared/components/base/FormInput/types";
import FormInput from "@/shared/components/base/FormInput/index.vue";
import Btn from "@/shared/components/base/Btn/index.vue";
import RadioList from "@/shared/components/base/RadioList/index.vue";
import BlueprintCraftableTypeSelect from "@/admin/components/base/BlueprintCraftableTypeSelect/index.vue";
import BlueprintMaterialSelect from "@/admin/components/base/BlueprintMaterialSelect/index.vue";
import BlueprintOrgSelect from "@/admin/components/base/BlueprintOrgSelect/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import { useFilterOptions } from "@/shared/composables/useFilterOptions";
import {
  type BlueprintQuery,
  type BlueprintCraftableTypeEnum,
} from "@/services/fyAdminApi";
import { useBlueprintFilters } from "@/admin/composables/useBlueprintFilters";

const { t } = useI18n();

const { booleanOptions } = useFilterOptions();

const prefillFormValues = (): BlueprintQuery => {
  return {
    nameCont: filters.value.nameCont,
    scKeyCont: filters.value.scKeyCont,
    craftableTypeIn: filters.value.craftableTypeIn || [],
    consumingCommodity: filters.value.consumingCommodity,
    fromOrg: filters.value.fromOrg,
    withKnownSource: filters.value.withKnownSource,
    withCraftable: filters.value.withCraftable,
    currentVersion: filters.value.currentVersion,
  };
};

const setupForm = () => {
  form.value = prefillFormValues();
};

const { filter, resetFilter, isFilterSelected, filters } =
  useBlueprintFilters(setupForm);

const handleSubmit = () => {
  filter(form.value);
};

const form = ref<BlueprintQuery>(prefillFormValues());

// `craftableTypeIn` is typed as the enum, and the select hands back the plain
// strings a query string carries.
const craftableTypes = computed({
  get: () => (form.value.craftableTypeIn as string[]) || [],
  set: (value: string[]) => {
    form.value.craftableTypeIn = value as BlueprintCraftableTypeEnum[];
  },
});

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
        translation-key="filters.blueprints.name"
        :no-label="true"
        :clearable="true"
        inline
      />
    </Teleport>

    <BlueprintCraftableTypeSelect
      v-model="craftableTypes"
      name="craftable-type"
    />

    <BlueprintMaterialSelect
      v-model="form.consumingCommodity"
      name="material"
    />

    <BlueprintOrgSelect v-model="form.fromOrg" name="org" />

    <FormInput
      v-model="form.scKeyCont"
      name="blueprint-sc-key"
      translation-key="filters.blueprints.scKey"
      :no-placeholder="true"
    />

    <!--
      The two questions the section exists to answer, and both are asked with
      "no": which recipes nothing hands out, and which make something no
      catalogue carries.
    -->
    <RadioList
      v-model="form.withKnownSource"
      :label="t('labels.filters.blueprints.withKnownSource')"
      :reset-label="t('labels.all')"
      :options="booleanOptions"
      name="withKnownSource"
    />

    <RadioList
      v-model="form.withCraftable"
      :label="t('labels.filters.blueprints.withCraftable')"
      :reset-label="t('labels.all')"
      :options="booleanOptions"
      name="withCraftable"
    />

    <RadioList
      v-model="form.currentVersion"
      :label="t('labels.filters.blueprints.currentVersion')"
      :reset-label="t('labels.all')"
      :options="booleanOptions"
      name="currentVersion"
    />

    <br />
    <Btn :disabled="!isFilterSelected" :block="true" @click="resetFilter">
      <i class="fa-light fa-times" />
      {{ t("actions.resetFilter") }}
    </Btn>
  </form>
</template>
