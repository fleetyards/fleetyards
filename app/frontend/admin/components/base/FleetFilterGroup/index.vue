<script lang="ts">
export default {
  name: "FleetFilterGroup",
};
</script>

<script lang="ts" setup>
import { useI18n } from "@/shared/composables/useI18n";
import {
  fleets as fetchFleets,
  type FleetQuery,
  type Fleets,
  type Fleet,
} from "@/services/fyAdminApi";
import FilterGroup, {
  type FilterGroupParams,
} from "@/shared/components/base/FilterGroup/index.vue";

type Props = {
  name: string;
  modelValue?: string | string[];
  multiple?: boolean;
  noLabel?: boolean;
  returnObject?: boolean;
};

const props = withDefaults(defineProps<Props>(), {
  modelValue: undefined,
  multiple: false,
  noLabel: true,
  returnObject: false,
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

const formatter = (response: Fleets) => {
  return response.items.map((fleet) => {
    return {
      label: `${fleet.name} (${fleet.fid})`,
      value: fleet.fid,
    };
  });
};

const fetch = async (params: FilterGroupParams<Fleet>) => {
  const q: FleetQuery = {};

  if (params.search) {
    q.nameCont = params.search;
  }

  if (params.missing) {
    if (props.multiple) {
      q.fidCont = Array.isArray(params.missing)
        ? (params.missing[0] as string)
        : (params.missing as string);
    } else {
      q.fidCont = params.missing as string;
    }
  }

  return fetchFleets({
    page: String(params.page || 1),
    q,
  });
};
</script>

<template>
  <FilterGroup
    v-model="internalValue"
    :label="t('labels.selectFleet')"
    :search-label="t('labels.findFleet')"
    :query-fn="fetch"
    :query-response-formatter="formatter"
    :name="name"
    :paginated="true"
    :searchable="true"
    :multiple="multiple"
    :no-label="noLabel"
  />
</template>
