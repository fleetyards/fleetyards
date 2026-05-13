<script lang="ts">
export default {
  name: "FleetEventsVehiclePicker",
};
</script>

<script lang="ts" setup>
import FilterGroup from "@/shared/components/base/FilterGroup/index.vue";
import {
  type FilterOption,
  type FleetEventShip,
  type Vehicle,
  useHangar,
} from "@/services/fyApi";
import { useI18n } from "@/shared/composables/useI18n";
import { vehicleMatchesShip } from "@/frontend/composables/useShipMatch";

type Props = {
  modelValue: string | null;
  // The parent ship slot is on, if any. Used to flag vehicles that don't
  // satisfy the slot's required model / filter constraints.
  requiredShip?: FleetEventShip | null;
  // Allow vehicles even if they don't match (with a warning)
  allowAny?: boolean;
};

const props = withDefaults(defineProps<Props>(), {
  requiredShip: null,
  allowAny: true,
});

const emit = defineEmits<{
  "update:modelValue": [value: string | null];
  match: [matches: boolean];
}>();

const { t } = useI18n();

const SIZE_ORDER = [
  "snub",
  "small",
  "medium",
  "large",
  "extra_large",
  "capital",
];

// Restrict the picker to ships that are actually playable today (Hangar Ready
// and Flight Ready) and pre-filter on the slot's classification / focus / size
// so members don't have to scroll past dozens of irrelevant vehicles.
const hangarParams = computed(() => {
  const f = props.requiredShip?.filters;
  const q: Record<string, unknown> = {
    productionStatusIn: ["flight-ready", "ready"],
  };
  if (f?.classification) q.classificationIn = [f.classification];
  if (f?.focus) q.focusIn = [f.focus];
  if (f?.minSize || f?.maxSize) {
    const sizes = SIZE_ORDER.filter(
      (s) =>
        (!f.minSize ||
          SIZE_ORDER.indexOf(s) >= SIZE_ORDER.indexOf(f.minSize)) &&
        (!f.maxSize || SIZE_ORDER.indexOf(s) <= SIZE_ORDER.indexOf(f.maxSize)),
    );
    if (sizes.length) q.sizeIn = sizes;
  }
  return { perPage: "200", q };
});

const { data: hangarData, isLoading } = useHangar(hangarParams);

const vehicles = computed<Vehicle[]>(() => hangarData.value?.items ?? []);

const matches = (vehicle: Vehicle): boolean =>
  vehicleMatchesShip(vehicle, props.requiredShip);

const matching = computed(() => vehicles.value.filter(matches));
const nonMatching = computed(() => vehicles.value.filter((v) => !matches(v)));

const options = computed<FilterOption[]>(() => {
  const list: FilterOption[] = [];
  for (const v of matching.value) {
    list.push({
      value: v.id,
      label: vehicleLabel(v),
    });
  }
  if (props.allowAny) {
    for (const v of nonMatching.value) {
      list.push({
        value: v.id,
        label: `${vehicleLabel(v)} ⚠️`,
      });
    }
  }
  return list;
});

const vehicleLabel = (v: Vehicle) => {
  const name = v.name?.trim();
  const modelName = v.model?.name ?? "";
  return name && name !== modelName ? `${name} (${modelName})` : modelName;
};

const selected = computed(() =>
  vehicles.value.find((v) => v.id === props.modelValue),
);

const selectedMatches = computed(() => {
  if (!selected.value) return true;
  return matches(selected.value);
});

// When the slot has filters but the member's hangar has nothing matching,
// surface that explicitly so the dropdown isn't just mysteriously empty.
const noMatchingInHangar = computed(
  () => !!props.requiredShip && !isLoading.value && matching.value.length === 0,
);

watch(selectedMatches, (value) => emit("match", value), { immediate: true });
</script>

<template>
  <div class="vehicle-picker">
    <FilterGroup
      :model-value="modelValue"
      :options="options"
      :label="t('labels.fleets.events.myVehicle')"
      :placeholder="t('labels.fleets.events.selectVehicle')"
      name="vehiclePicker"
      :searchable="true"
      :nullable="true"
      :disabled="isLoading"
      @update:model-value="(v) => emit('update:modelValue', v as string | null)"
    />
    <p
      v-if="noMatchingInHangar"
      class="vehicle-picker__warning text-muted small"
    >
      <i class="fa-light fa-circle-info" />
      {{ t("labels.fleets.events.noFittingInHangar") }}
    </p>
    <p
      v-else-if="selected && !selectedMatches"
      class="vehicle-picker__warning text-muted small"
    >
      <i class="fa-light fa-triangle-exclamation" />
      {{ t("labels.fleets.events.vehicleMismatchHint") }}
    </p>
  </div>
</template>

<style lang="scss" scoped>
.vehicle-picker {
  display: flex;
  flex-direction: column;
  gap: 0.25rem;
}
.vehicle-picker__warning {
  display: flex;
  align-items: center;
  gap: 0.4rem;
  margin: 0;
  color: var(--warning, #ff9800);

  i {
    color: inherit;
  }
}
.small {
  font-size: 0.8rem;
}
</style>
