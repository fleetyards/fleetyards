<script lang="ts">
export default {
  name: "HangarPlannerModelSelect",
};
</script>

<script lang="ts" setup>
import {
  modelOptions as fetchModelOptions,
  type ModelOption,
  type ModelOptions,
  type ModelQuery,
} from "@/services/fyApi";
import BaseSelect, {
  type BaseSelectParams,
} from "@/shared/components/base/Select/index.vue";

type Props = {
  name: string;
  label: string;
  modelValue?: string | null;
};

const props = withDefaults(defineProps<Props>(), {
  modelValue: null,
});

const emit = defineEmits<{
  "update:modelValue": [value: string | null];
}>();

// By id rather than slug: a plan stores the ship it means, and a slug can be
// renamed under it.
const internalValue = computed({
  get: () => props.modelValue ?? undefined,
  set: (value) => emit("update:modelValue", (value as string) || null),
});

const formatter = (response: ModelOptions) =>
  response.items.map((model) => ({
    icon: model.media?.storeImage?.smallUrl,
    label: model.name,
    value: model.id,
  }));

const fetch = (params: BaseSelectParams<ModelOption>) => {
  const q: ModelQuery = {};

  if (params.search) {
    q.nameCont = params.search;
  }

  if (params.missing) {
    q.idIn = [params.missing as string];
  }

  return fetchModelOptions({ page: String(params.page || 1), q });
};
</script>

<template>
  <BaseSelect
    v-model="internalValue"
    :label="label"
    :query-fn="fetch"
    :query-response-formatter="formatter"
    :name="name"
    paginated
    searchable
  />
</template>
