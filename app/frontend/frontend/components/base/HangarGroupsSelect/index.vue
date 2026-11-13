<script lang="ts">
export default {
  name: "HangarGroupsSelect",
};
</script>

<script lang="ts" setup>
import { useI18n } from "@/shared/composables/useI18n";
import BaseSelect, {
  type BaseSelectParams,
} from "@/shared/components/base/Select/index.vue";
import {
  hangarGroups as fetchHangarGroups,
  type FilterOption,
  type HangarGroup,
} from "@/services/fyApi";

type Props = {
  name: string;
  multiple?: boolean;
  noLabel?: boolean;
  info?: string;
  // The filter label is what a group picker means almost everywhere; the sync
  // modal asks the same question about two different sets of ships and has to
  // say which is which.
  label?: string;
  autosaved?: boolean;
};

withDefaults(defineProps<Props>(), {
  multiple: true,
  noLabel: true,
  info: undefined,
  label: undefined,
  autosaved: false,
});

const { t } = useI18n();

const internalValue = defineModel<string | string[] | undefined>();

const fetch = (_params: BaseSelectParams<FilterOption>) => {
  return fetchHangarGroups();
};

const formatter = (groups: HangarGroup[]) => {
  return groups.map((group) => ({
    label: group.name,
    value: group.id,
  }));
};
</script>

<template>
  <BaseSelect
    v-model="internalValue"
    :label="label || t('labels.filters.vehicles.group')"
    :query-fn="fetch"
    :query-response-formatter="formatter"
    :name="name"
    :paginated="false"
    :searchable="false"
    :multiple="multiple"
    :no-label="noLabel"
    :info="info"
    :autosaved="autosaved"
  />
</template>
