<script lang="ts">
export default {
  name: "FleetEventsShipMatchWarning",
};
</script>

<script lang="ts" setup>
import type {
  FleetEventShip,
  FleetEventSlot,
  FleetEventSignup,
} from "@/services/fyApi";
import { useI18n } from "@/shared/composables/useI18n";
import { vehicleMatchesShip } from "@/frontend/composables/useShipMatch";

type Props = {
  ship: FleetEventShip;
};

const props = defineProps<Props>();
const { t } = useI18n();

const slots = computed<FleetEventSlot[]>(
  () => (props.ship.slots ?? []) as FleetEventSlot[],
);

const activeSignups = computed<FleetEventSignup[]>(() => {
  const out: FleetEventSignup[] = [];
  for (const slot of slots.value) {
    for (const signup of slot.signups ?? []) {
      if (signup.status !== "withdrawn") out.push(signup);
    }
  }
  return out;
});

const hasMatchingSignup = computed(() =>
  activeSignups.value.some((s) => vehicleMatchesShip(s.vehicle, props.ship)),
);

// Surfaces whenever no active signup brings a matching vehicle — including
// when slots are still open, so the fleet sees that this ship still needs
// someone with the right vehicle.
const showWarning = computed(() => !hasMatchingSignup.value);

const message = computed(() =>
  activeSignups.value.length
    ? t("labels.fleets.events.noMatchingVehicle")
    : t("labels.fleets.events.shipNotCrewedYet"),
);
</script>

<template>
  <div v-if="showWarning" class="ship-match-warning">
    <i class="fa-light fa-triangle-exclamation" />
    <span>{{ message }}</span>
  </div>
</template>

<style lang="scss" scoped>
.ship-match-warning {
  display: flex;
  align-items: center;
  gap: 8px;
  margin: 6px 0 10px;
  padding: 6px 11px;
  font-size: 13px;
  font-weight: 500;
  color: var(--color-warning, #fa6800);
  background: rgba(255, 152, 0, 0.1);
  border: 1px solid rgba(255, 152, 0, 0.4);
  border-radius: var(--radius-control-bare, 6px);

  i {
    color: inherit;
  }
}
</style>
