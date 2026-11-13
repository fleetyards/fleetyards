<script lang="ts">
export default {
  name: "FleetSelect",
};
</script>

<script lang="ts" setup>
import { useI18n } from "@/shared/composables/useI18n";
import {
  fleetOptions as fetchFleetOptions,
  type FleetQuery,
  type FleetOptions,
  type FleetOption,
} from "@/services/fyAdminApi";
import BaseSelect, {
  type BaseSelectParams,
} from "@/shared/components/base/Select/index.vue";

type Props = {
  name: string;
  multiple?: boolean;
  noLabel?: boolean;
  inline?: boolean;
};

const props = withDefaults(defineProps<Props>(), {
  multiple: false,
  noLabel: true,
  inline: false,
});

const { t } = useI18n();

const internalValue = defineModel<string | string[] | undefined>();

// The option row is a single label, so the SID and roster size travel in it.
// Fleet names are not unique; the SID is what tells them apart.
const formatter = (response: FleetOptions) => {
  return response.items.map((fleet) => {
    const parts = [`${fleet.name} (${fleet.fid})`];

    if (fleet.memberCount !== undefined) {
      parts.push(
        t("labels.features.memberCount", { count: fleet.memberCount }),
      );
    }

    return {
      label: parts.join(" · "),
      value: fleet.fid,
    };
  });
};

const fetch = async (params: BaseSelectParams<FleetOption>) => {
  const q: FleetQuery = {};

  if (params.search) {
    q.search = params.search.trim();
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

  return fetchFleetOptions({
    page: String(params.page || 1),
    q,
  });
};
</script>

<template>
  <BaseSelect
    v-model="internalValue"
    :label="t('labels.selectFleet')"
    :search-label="t('labels.findFleet')"
    :query-fn="fetch"
    :query-response-formatter="formatter"
    :name="name"
    :paginated="true"
    :searchable="true"
    :unsorted="true"
    :multiple="multiple"
    :no-label="noLabel"
    :inline="inline"
  />
</template>
