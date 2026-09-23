<script lang="ts">
export default {
  name: "FleetSquadronSelect",
};
</script>

<script lang="ts" setup>
import BaseSelect from "@/shared/components/base/Select/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import { useFeatures } from "@/frontend/composables/useFeatures";
import {
  FeatureFlagName,
  useFleetSquadrons,
  type Fleet,
  type FilterOption,
} from "@/services/fyApi";

type Props = {
  fleet: Fleet;
  modelValue?: string[];
  name?: string;
};

const props = withDefaults(defineProps<Props>(), {
  modelValue: () => [],
  name: "fleetSquadronIds",
});

const emit = defineEmits<{ "update:modelValue": [value: string[]] }>();

const { t } = useI18n();

const { isFleetFeatureEnabled } = useFeatures();

// Same gate the filter uses: no feature, no request and nothing drawn.
const enabled = computed(() =>
  isFleetFeatureEnabled(props.fleet, FeatureFlagName.FLEET_SQUADRONS),
);

const { data: squadrons } = useFleetSquadrons(
  computed(() => props.fleet.slug),
  {},
  { query: { enabled } },
);

/*
 * Squadrons before teams, the fleet's own order within each -- the same order
 * every other list of them uses, so the one somebody is looking for is where
 * they last saw it.
 */
const options = computed<FilterOption[]>(() =>
  (squadrons.value?.items ?? []).map((squadron) => ({
    value: squadron.id,
    label: squadron.name,
  })),
);

const selected = computed({
  get: () => props.modelValue,
  set: (value: string[]) => emit("update:modelValue", value ?? []),
});
</script>

<template>
  <BaseSelect
    v-model="selected"
    :options="options"
    :name="props.name"
    :label="t('labels.fleet.squadrons.index')"
    :info="t('labels.fleet.squadrons.restrictedToHint')"
    multiple
    :nullable="false"
    searchable
  />
</template>
