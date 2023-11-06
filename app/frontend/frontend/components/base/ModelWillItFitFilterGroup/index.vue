<template>
  <FilterGroup
    v-model="internalValue"
    :label="t('labels.filters.models.willItFit')"
    :query-fn="fetch"
    :query-response-formatter="formatter"
    :name="name"
    :searchable="searchable"
    :multiple="multiple"
    :no-label="noLabel"
  />
</template>

<script lang="ts" setup>
import { useApiClient } from "@/frontend/composables/useApiClient";
import { type ModelQuery, type Models } from "@/services/fyApi";
import { useI18n } from "@/frontend/composables/useI18n";
import FilterGroup, {
  type FilterGroupParams,
} from "@/shared/components/base/FilterGroup/index.vue";

type Props = {
  name: string;
  modelValue?: string | string[];
  searchable?: boolean;
  multiple?: boolean;
  noLabel?: boolean;
};

const props = withDefaults(defineProps<Props>(), {
  modelValue: undefined,
  searchable: true,
  multiple: true,
  noLabel: false,
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

const formatter = (response: Models) => {
  return response.items.map((model) => {
    return {
      label: model.name,
      value: model.slug,
    };
  });
};

const { models: modelsService } = useApiClient();

const fetch = async (params: FilterGroupParams) => {
  const q: ModelQuery = {};

  if (params.search) {
    q.nameCont = params.search;
  }

  if (params.missing) {
    q.slugEq = params.missing as string;
  }

  return modelsService.modelsWithDocks({
    page: String(params.page || 1),
    q,
  });
};
</script>

<script lang="ts">
export default {
  name: "ModelWillItFitFilterGroup",
};
</script>
