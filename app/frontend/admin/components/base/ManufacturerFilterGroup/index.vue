<template>
  <FilterGroup
    v-model="internalValue"
    :label="t('labels.filters.manufacturer')"
    :query-fn="fetch"
    :query-response-formatter="formatter"
    :name="name"
    :paginated="true"
    :searchable="true"
    :multiple="multiple"
    :no-label="noLabel"
  />
</template>

<script lang="ts" setup>
import { useApiClient } from "@/admin/composables/useApiClient";
import { useI18n } from "@/shared/composables/useI18n";
import {
  type ManufacturerQuery,
  type Manufacturers,
} from "@/services/fyAdminApi";
import FilterGroup, {
  type FilterGroupParams,
} from "@/shared/components/base/FilterGroup/index.vue";

type Props = {
  name: string;
  modelValue?: string | string[];
  multiple?: boolean;
  noLabel?: boolean;
};

const props = withDefaults(defineProps<Props>(), {
  modelValue: undefined,
  multiple: true,
  noLabel: true,
});

const { t } = useI18n();

const internalValue = ref<string | string[] | undefined>(props.modelValue);

onMounted(() => {
  internalValue.value = props.modelValue;
});

watch(
  () => props.modelValue,
  () => {
    internalValue.value = props.modelValue;
  },
);

const emit = defineEmits(["update:modelValue"]);

watch(
  () => internalValue.value,
  () => {
    emit("update:modelValue", internalValue.value);
  },
);

const formatter = (response: Manufacturers) => {
  return response.items.map((manufacturer) => {
    return {
      icon: manufacturer.logo,
      label: manufacturer.name,
      value: manufacturer.slug,
    };
  });
};

const { manufacturers: manufacturersService } = useApiClient();

const fetch = async (params: FilterGroupParams) => {
  const q: ManufacturerQuery = {
    withModels: true,
  };

  if (params.search) {
    q.nameCont = params.search;
  }

  if (params.missing) {
    q.slugEq = params.missing as string;
  }

  return manufacturersService.manufacturers({
    page: String(params.page || 1),
    q,
  });
};
</script>

<script lang="ts">
export default {
  name: "ManufacturerFilterGroup",
};
</script>
