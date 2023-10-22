<template>
  <FilterGroup
    v-model="internalValue"
    :label="t('labels.filters.manufacturer')"
    :query-fn="fetchManufacturers"
    :query-response-formatter="manufacturersFormatter"
    :name="name"
    :paginated="true"
    :searchable="true"
    :multiple="multiple"
    :no-label="true"
  />
</template>

<script lang="ts" setup>
import { useApiClient } from "@/frontend/composables/useApiClient";
import { useI18n } from "@/frontend/composables/useI18n";
import { type ManufacturerQuery, type Manufacturers } from "@/services/fyApi";
import FilterGroup, {
  type FilterGroupParams,
} from "@/shared/components/base/FilterGroup/index.vue";

type Props = {
  name: string;
  modelValue?: string | string[];
  multiple?: boolean;
};

const props = withDefaults(defineProps<Props>(), {
  modelValue: undefined,
  multiple: true,
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

const manufacturersFormatter = (response: Manufacturers) => {
  return response.items.map((manufacturer) => {
    return {
      label: manufacturer.name,
      value: manufacturer.slug,
    };
  });
};

const { manufacturers: manufacturersService } = useApiClient();

const fetchManufacturers = async (params: FilterGroupParams) => {
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
