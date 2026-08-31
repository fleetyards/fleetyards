<script lang="ts">
export default {
  name: "InventoryItemFilterForm",
};
</script>

<script lang="ts" setup>
import BaseSelect from "@/shared/components/base/Select/index.vue";
import FormInput from "@/shared/components/base/FormInput/index.vue";
import {
  InputSizesEnum,
  InputTypesEnum,
} from "@/shared/components/base/FormInput/types";
import Btn from "@/shared/components/base/Btn/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import {
  useInventoryItemFilters,
  type InventoryItemQuery,
} from "@/frontend/composables/useInventoryItemFilters";
import { useInventoryOptions } from "@/frontend/composables/useInventoryOptions";

type Props = {
  hideQuicksearch?: boolean;
  updateCallback?: () => Promise<void>;
};

const props = withDefaults(defineProps<Props>(), {
  hideQuicksearch: false,
  updateCallback: undefined,
});

const { t } = useI18n();

const { categoryOptions } = useInventoryOptions();

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

defineExpose({ isFilterSelected });
</script>

<template>
  <form @submit.prevent="handleSubmit">
    <Teleport v-if="!hideQuicksearch" to="#header-left">
      <FormInput
        :size="InputSizesEnum.MEDIUM"
        v-model="form.nameCont"
        name="search"
        :placeholder="t('labels.logistics.searchItems')"
        :no-label="true"
        :clearable="true"
      />
    </Teleport>

    <FormInput
      v-if="hideQuicksearch"
      v-model="form.nameCont"
      name="item-name"
      :placeholder="t('labels.logistics.searchItems')"
      :no-label="true"
      :clearable="true"
    />

    <BaseSelect
      v-model="form.categoryEq"
      :options="categoryOptions"
      :label="t('labels.logistics.category')"
      name="category"
      :nullable="true"
    />

    <div class="row">
      <div class="col-6">
        <FormInput
          v-model="form.qualityGteq"
          name="quality-gteq"
          :type="InputTypesEnum.NUMBER"
          :label="t('labels.logistics.qualityMin')"
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
          :label="t('labels.logistics.qualityMax')"
          :no-placeholder="true"
          :min="0"
          :max="1000"
        />
      </div>
    </div>

    <Btn :disabled="!isFilterSelected" @click="resetFilter">
      {{ t("actions.resetFilter") }}
    </Btn>
  </form>
</template>
