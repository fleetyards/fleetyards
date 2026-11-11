<script lang="ts">
export default {
  name: "FleetSquadronSourceSelect",
};
</script>

<script lang="ts" setup>
import BaseSelect from "@/shared/components/base/Select/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import { useFeatures } from "@/frontend/composables/useFeatures";
import {
  useFleetSquadrons,
  type Fleet,
  type FilterOption,
  type FleetSquadron,
} from "@/services/fyApi";

type Props = {
  fleet: Fleet;
  modelValue?: string | null;
  name?: string;
};

const props = withDefaults(defineProps<Props>(), {
  modelValue: null,
  name: "fleetSquadronId",
});

const emit = defineEmits<{
  "update:modelValue": [value: string | null];
  pick: [squadron: FleetSquadron, previous: FleetSquadron | undefined];
}>();

const { t } = useI18n();

const { isFleetSquadronsEnabled } = useFeatures();

const enabled = computed(() => isFleetSquadronsEnabled(props.fleet));

const { data: squadrons } = useFleetSquadrons(
  computed(() => props.fleet.slug),
  { perPage: "all" },
  { query: { enabled } },
);

const items = computed(() => squadrons.value?.items ?? []);

// Squadrons before teams, each in the fleet's own order.
const options = computed<FilterOption[]>(() =>
  [...items.value]
    .sort((a, b) => Number(a.team) - Number(b.team))
    .map((squadron) => ({
      value: squadron.id,
      label: squadron.name,
      category: squadron.team
        ? t("labels.fleets.missions.teams")
        : t("labels.fleet.squadrons.index"),
    })),
);

const selected = computed({
  get: () => props.modelValue,
  set: (value: string | null) => {
    const previous = items.value.find((item) => item.id === props.modelValue);

    emit("update:modelValue", value ?? null);

    const squadron = items.value.find((item) => item.id === value);
    if (squadron) emit("pick", squadron, previous);
  },
});
</script>

<template>
  <BaseSelect
    v-if="enabled && options.length"
    v-model="selected"
    :options="options"
    :name="props.name"
    :label="t('labels.fleet.squadrons.teamSource')"
    :info="t('labels.fleet.squadrons.teamSourceHint')"
    searchable
    unsorted
  />
</template>
