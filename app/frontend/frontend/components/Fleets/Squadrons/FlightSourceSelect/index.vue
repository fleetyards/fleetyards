<script lang="ts">
export default {
  name: "FleetSquadronFlightSourceSelect",
};
</script>

<script lang="ts" setup>
import BaseSelect from "@/shared/components/base/Select/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import { useFeatures } from "@/frontend/composables/useFeatures";
import {
  useFleetSquadrons,
  useFleetSquadronFlights,
  type Fleet,
  type FilterOption,
  type FleetSquadronFlight,
} from "@/services/fyApi";

type Props = {
  fleet: Fleet;
  squadronId?: string | null;
  modelValue?: string | null;
  name?: string;
};

const props = withDefaults(defineProps<Props>(), {
  squadronId: null,
  modelValue: null,
  name: "sourceFlightId",
});

const emit = defineEmits<{
  "update:modelValue": [value: string | null];
  pick: [
    flight: FleetSquadronFlight,
    previous: FleetSquadronFlight | undefined,
  ];
}>();

const { t } = useI18n();

const { isFleetSquadronFlightsEnabled } = useFeatures();

const enabled = computed(() => isFleetSquadronFlightsEnabled(props.fleet));

// The same list the squadron picker beside this one loads, so it is cached.
const { data: squadrons } = useFleetSquadrons(
  computed(() => props.fleet.slug),
  { perPage: "all" },
  { query: { enabled } },
);

// Only a squadron that has its flights switched on offers them.
const squadronSlug = computed(() => {
  const squadron = squadrons.value?.items?.find(
    (item) => item.id === props.squadronId,
  );

  return squadron?.flightsEnabled ? squadron.slug : "";
});

const { data: flights } = useFleetSquadronFlights(
  computed(() => props.fleet.slug),
  squadronSlug,
  { query: { enabled: computed(() => enabled.value && !!squadronSlug.value) } },
);

const items = computed(() =>
  enabled.value && squadronSlug.value ? (flights.value ?? []) : [],
);

const options = computed<FilterOption[]>(() =>
  items.value.map((flight) => ({ value: flight.id, label: flight.name })),
);

// A flight belongs to one squadron, so switching squadrons drops the pick.
watch(
  () => props.squadronId,
  () => {
    if (props.modelValue) emit("update:modelValue", null);
  },
);

const selected = computed({
  get: () => props.modelValue,
  set: (value: string | null) => {
    const previous = items.value.find((item) => item.id === props.modelValue);

    emit("update:modelValue", value ?? null);

    const flight = items.value.find((item) => item.id === value);
    if (flight) emit("pick", flight, previous);
  },
});
</script>

<template>
  <BaseSelect
    v-if="options.length"
    v-model="selected"
    :options="options"
    :name="props.name"
    :label="t('labels.fleet.squadrons.flights.teamSource')"
    :info="t('labels.fleet.squadrons.flights.teamSourceHint')"
    nullable
    unsorted
  />
</template>
