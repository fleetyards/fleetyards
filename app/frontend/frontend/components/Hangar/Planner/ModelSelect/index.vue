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
  // Narrows what a search offers; the current value always resolves.
  query?: ModelQuery;
  noLabel?: boolean;
};

const props = withDefaults(defineProps<Props>(), {
  modelValue: null,
  query: undefined,
  noLabel: false,
});

const emit = defineEmits<{
  "update:modelValue": [value: string | null];
  // The picked ship's name, for a caller that shows the choice elsewhere.
  pick: [name: string | undefined];
}>();

const names = new Map<string, string>();

// By id rather than slug: a plan stores the ship it means, and a slug can be
// renamed under it.
const internalValue = computed({
  get: () => props.modelValue ?? undefined,
  set: (value) => {
    emit("update:modelValue", (value as string) || null);
    emit("pick", value ? names.get(value as string) : undefined);
  },
});

const formatter = (response: ModelOptions) =>
  response.items.map((model) => {
    names.set(model.id, model.name);

    return {
      icon: model.media?.storeImage?.smallUrl,
      label: model.name,
      value: model.id,
    };
  });

const fetch = (params: BaseSelectParams<ModelOption>) => {
  if (params.missing) {
    return fetchModelOptions({
      page: String(params.page || 1),
      q: { idIn: [params.missing as string] },
    });
  }

  const q: ModelQuery = { ...props.query };

  if (params.search) {
    q.nameCont = params.search;
  }

  return fetchModelOptions({ page: String(params.page || 1), q });
};
</script>

<template>
  <BaseSelect
    v-model="internalValue"
    :label="label"
    :no-label="noLabel"
    :query-fn="fetch"
    :query-response-formatter="formatter"
    :name="name"
    paginated
    searchable
  />
</template>
