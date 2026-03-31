<script lang="ts">
export default {
  name: "FleetMemberFilterGroup",
};
</script>

<script lang="ts" setup>
import { useI18n } from "@/shared/composables/useI18n";
import FilterGroup, {
  type FilterGroupParams,
} from "@/shared/components/base/FilterGroup/index.vue";
import {
  fleetMembers as fetchFleetMembers,
  type FleetMember,
  type FleetMembersList,
  type FleetMemberQuery,
} from "@/services/fyApi";

type Props = {
  name: string;
  fleetSlug: string;
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

const formatter = (response: FleetMembersList) => {
  return response.items.map((member) => {
    return {
      icon: member.avatar?.smallUrl,
      label: member.username,
      value: member.username,
    };
  });
};

const fetch = async (params: FilterGroupParams<FleetMember>) => {
  const q: FleetMemberQuery = {
    stateIn: ["accepted"],
  };

  if (params.search) {
    q.usernameCont = params.search;
  }

  if (params.missing) {
    q.usernameCont = Array.isArray(params.missing)
      ? (params.missing as string[])[0]
      : (params.missing as string);
  }

  return fetchFleetMembers(props.fleetSlug, {
    page: String(params.page || 1),
    q,
  });
};
</script>

<template>
  <FilterGroup
    v-model="internalValue"
    :label="t('labels.filters.fleets.member')"
    :query-fn="fetch"
    :query-response-formatter="formatter"
    :name="name"
    :paginated="true"
    :searchable="true"
    :multiple="multiple"
    :no-label="noLabel"
  />
</template>
