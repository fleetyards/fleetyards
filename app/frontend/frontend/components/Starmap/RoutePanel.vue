<script lang="ts">
export default {
  name: "StarmapRoutePanel",
};
</script>

<script lang="ts" setup>
import BaseSelect from "@/shared/components/base/Select/index.vue";
import Alert from "@/shared/components/base/Alert/index.vue";
import { AlertVariantsEnum } from "@/shared/components/base/Alert/types";
import ModelPickerSelect from "@/frontend/components/Models/PickerSelect/index.vue";
import KindIcon from "@/frontend/components/Locations/KindIcon/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import { toTime } from "@/shared/utils/Time";
import type { RouteLoadoutOption } from "@/frontend/composables/useRouteDrive";
import type { QuantumRoute } from "@/frontend/utils/quantumRoute";
import type { FilterOption } from "@/services/fyApi";
import type { RoutePlaceOption } from "./route";

type Props = {
  options: RoutePlaceOption[];
  from: string | null;
  to: string | null;
  ship: string | null;
  loadout: string | null;
  loadoutOptions: RouteLoadoutOption[];
  // The loadout in the address is not one of the viewer's.
  missingLoadout: boolean;
  route: QuantumRoute | null;
  // A ship is picked and its drive is known.
  hasDrive: boolean;
  loading: boolean;
  tankSize: number | null;
  // The place the map is on, offered as either end.
  focused: { slug: string; name: string } | null;
};

const props = defineProps<Props>();

const emit = defineEmits<{
  "update:from": [slug: string | null];
  "update:to": [slug: string | null];
  "update:ship": [slug: string | null];
  "update:loadout": [id: string | null];
}>();

const { t, toNumber, currentLocale } = useI18n();

const STOCK = "stock";

const placeOptions = computed<FilterOption[]>(() =>
  props.options.map((option) => ({
    label: option.place.name || option.place.slug,
    value: option.place.slug,
    category: option.systemName,
  })),
);

const driveOptions = computed<FilterOption[]>(() => [
  { label: t("starmap.route.stockDrive"), value: STOCK },
  ...props.loadoutOptions.map((option) => ({
    label: option.name,
    value: option.id,
  })),
]);

const originValue = computed({
  get: () => props.from ?? undefined,
  set: (value) => emit("update:from", value || null),
});

const destinationValue = computed({
  get: () => props.to ?? undefined,
  set: (value) => emit("update:to", value || null),
});

const shipValue = computed({
  get: () => props.ship ?? undefined,
  set: (value) => emit("update:ship", value || null),
});

const driveValue = computed({
  get: () => (props.loadout && !props.missingLoadout ? props.loadout : STOCK),
  set: (value) =>
    emit("update:loadout", !value || value === STOCK ? null : String(value)),
});

const swap = () => {
  const { from, to } = props;
  emit("update:from", to);
  emit("update:to", from);
};

const formatLength = (metres: number) =>
  metres >= 1e9
    ? t("starmap.units.gm", { value: toNumber(metres / 1e9) })
    : t("starmap.units.km", { value: toNumber(metres / 1e3) });

// A leg burns a few hundredths of an SCU: the default single decimal would
// read every one of them as zero.
const formatFuel = (scu: number) =>
  t("starmap.route.scu", {
    value: new Intl.NumberFormat(currentLocale(), {
      maximumFractionDigits: 3,
    }).format(scu),
  });

const status = computed(() => {
  if (!props.ship) return t("starmap.route.pickShip");
  if (props.loading) return t("starmap.route.loading");
  if (!props.hasDrive) return t("starmap.route.noDrive");
  if (!props.from || !props.to) return t("starmap.route.pickEnds");
  if (!props.route) return t("starmap.route.noRoute");

  return null;
});
</script>

<template>
  <div class="starmap-route" data-test="starmap-route">
    <ModelPickerSelect
      v-model="shipValue"
      name="starmap-route-ship"
      :label="t('starmap.route.ship')"
    />

    <BaseSelect
      v-if="ship && loadoutOptions.length"
      v-model="driveValue"
      name="starmap-route-drive"
      :label="t('starmap.route.drive')"
      :options="driveOptions"
      unsorted
    />

    <Alert
      v-if="ship && missingLoadout"
      :variant="AlertVariantsEnum.NEUTRAL"
      data-test="starmap-route-missing-loadout"
    >
      {{ t("starmap.route.missingLoadout") }}
    </Alert>

    <div class="starmap-route__ends">
      <div class="starmap-route__end">
        <BaseSelect
          v-model="originValue"
          name="starmap-route-from"
          :label="t('starmap.route.from')"
          :options="placeOptions"
          searchable
          nullable
        />
        <button
          v-if="focused && focused.slug !== from"
          type="button"
          class="starmap-route__use"
          data-test="starmap-route-from-focused"
          @click="emit('update:from', focused.slug)"
        >
          {{ t("starmap.route.useFocused", { name: focused.name }) }}
        </button>
      </div>

      <button
        type="button"
        class="starmap-route__swap"
        :aria-label="t('starmap.route.swap')"
        :disabled="!from && !to"
        @click="swap"
      >
        <i class="fa-light fa-arrow-down-arrow-up" aria-hidden="true" />
      </button>

      <div class="starmap-route__end">
        <BaseSelect
          v-model="destinationValue"
          name="starmap-route-to"
          :label="t('starmap.route.to')"
          :options="placeOptions"
          searchable
          nullable
        />
        <button
          v-if="focused && focused.slug !== to"
          type="button"
          class="starmap-route__use"
          data-test="starmap-route-to-focused"
          @click="emit('update:to', focused.slug)"
        >
          {{ t("starmap.route.useFocused", { name: focused.name }) }}
        </button>
      </div>
    </div>

    <p
      v-if="status"
      class="starmap-route__status"
      data-test="starmap-route-status"
    >
      {{ status }}
    </p>

    <template v-else-if="route">
      <dl class="starmap-route__totals" data-test="starmap-route-totals">
        <div>
          <dt>{{ t("starmap.route.distance") }}</dt>
          <dd>{{ formatLength(route.distance) }}</dd>
        </div>
        <div>
          <dt>{{ t("starmap.route.time") }}</dt>
          <dd>{{ toTime(route.time) }}</dd>
        </div>
        <div>
          <dt>{{ t("starmap.route.fuel") }}</dt>
          <dd>{{ formatFuel(route.fuel) }}</dd>
        </div>
      </dl>

      <Alert
        v-if="route.exceedsTank && tankSize !== null"
        :variant="AlertVariantsEnum.WARNING"
        data-test="starmap-route-fuel-warning"
      >
        {{
          t("starmap.route.exceedsTank", {
            needed: formatFuel(route.fuel),
            tank: formatFuel(tankSize),
          })
        }}
      </Alert>

      <ol class="starmap-route__legs" data-test="starmap-route-legs">
        <li
          v-for="(leg, index) in route.legs"
          :key="`${index}-${leg.to.id}`"
          class="starmap-route__leg"
        >
          <KindIcon class="starmap-route__glyph" :kind="leg.to.kind" />
          <span class="starmap-route__name">
            {{ leg.to.name || leg.to.slug }}
          </span>
          <span v-if="leg.kind === 'quantum'" class="starmap-route__meta">
            {{ formatLength(leg.distance) }} ·
            {{ toTime(leg.spool + leg.travel) }} ·
            {{ formatFuel(leg.fuel) }}
          </span>
          <span v-else class="starmap-route__meta">
            {{ t("starmap.route.tunnel") }}
          </span>
        </li>
      </ol>

      <p class="starmap-route__note">{{ t("starmap.route.note") }}</p>
    </template>
  </div>
</template>

<style lang="scss" scoped>
.starmap-route {
  display: flex;
  flex: 1;
  flex-direction: column;
  gap: 12px;
  min-height: 0;
  overflow-y: auto;

  &__ends {
    display: flex;
    flex-direction: column;
    gap: 4px;
  }

  &__end {
    display: flex;
    flex-direction: column;
    gap: 4px;
  }

  &__use {
    align-self: flex-start;
    padding: 0;
    border: 0;
    background: none;
    color: var(--color-primary);
    font-size: 0.78125rem;
    cursor: pointer;

    &:hover {
      text-decoration: underline;
    }
  }

  &__swap {
    align-self: center;
    display: grid;
    place-items: center;
    width: 36px;
    height: 36px;
    border: 1px solid var(--color-edge);
    border-radius: var(--radius-control);
    background: var(--color-field);
    color: var(--color-text);
    cursor: pointer;

    &:hover:not(:disabled) {
      background: var(--color-control-hover);
      color: var(--color-lifted);
    }

    &:disabled {
      opacity: 0.5;
      cursor: default;
    }
  }

  &__status,
  &__note {
    margin: 0;
    color: var(--color-text-dim);
    font-size: 0.84375rem;
  }

  &__note {
    font-size: 0.75rem;
  }

  &__totals {
    display: grid;
    grid-template-columns: repeat(3, minmax(0, 1fr));
    gap: 8px;
    margin: 0;

    div {
      display: flex;
      flex-direction: column;
      gap: 2px;
    }

    dt {
      font-family: Orbitron, sans-serif;
      font-size: 10px;
      letter-spacing: 0.16em;
      text-transform: uppercase;
      color: var(--color-text-dim);
    }

    dd {
      margin: 0;
      color: var(--color-lifted);
      font-size: 0.9375rem;
    }
  }

  &__legs {
    display: flex;
    flex-direction: column;
    gap: 2px;
    margin: 0;
    padding: 0;
    list-style: none;
  }

  &__leg {
    display: grid;
    grid-template-columns: auto minmax(0, 1fr);
    column-gap: 10px;
    align-items: center;
    padding: 6px 10px;
    color: var(--color-text);
    font-size: 0.84375rem;
  }

  &__glyph {
    grid-row: span 2;
    color: var(--color-text-dim);
  }

  &__name {
    overflow: hidden;
    color: var(--color-lifted);
    text-overflow: ellipsis;
    white-space: nowrap;
  }

  &__meta {
    color: var(--color-text-dim);
    font-size: 0.75rem;
  }
}
</style>
