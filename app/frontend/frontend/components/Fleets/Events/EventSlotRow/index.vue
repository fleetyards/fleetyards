<script lang="ts">
export default {
  name: "FleetEventsSlotRow",
};
</script>

<script lang="ts" setup>
import Btn from "@/shared/components/base/Btn/index.vue";
import {
  BtnSizesEnum,
  BtnVariantsEnum,
} from "@/shared/components/base/Btn/types";
import Chip from "@/shared/components/base/Chip/index.vue";
import { ChipStatesEnum } from "@/shared/components/base/Chip/types";
import FormTextarea from "@/shared/components/base/FormTextarea/index.vue";
import VehiclePicker from "@/frontend/components/Fleets/Events/VehiclePicker/index.vue";
import {
  type Fleet,
  type FleetEvent,
  type FleetEventExtended,
  type FleetEventShip,
  type FleetEventSignup,
  type FleetEventSlot,
  FleetEventSignupStatus,
  useSignupFleetEventSlot,
} from "@/services/fyApi";
import { vehicleMatchesShip } from "@/frontend/composables/useShipMatch";
import { useI18n } from "@/shared/composables/useI18n";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";
import { useComlink } from "@/shared/composables/useComlink";

type Props = {
  slotData: FleetEventSlot;
  ship?: FleetEventShip | null;
  currentUserId?: string;
  signupsLocked: boolean;
  // True when the event is in a state that accepts new signups (not draft,
  // not locked, not started, not past). Falls back to signupsLocked when
  // omitted for backwards compatibility.
  signupsOpen?: boolean;
  // Slot id where the current user is already signed up (anywhere in the event)
  ownActiveSlotId?: string | null;
  // Manager-only: needed to open the slot picker modal.
  isManager?: boolean;
  fleet?: Fleet;
  event?: FleetEvent | FleetEventExtended;
};

const props = withDefaults(defineProps<Props>(), {
  ship: null,
  currentUserId: undefined,
  signupsOpen: undefined,
  ownActiveSlotId: null,
  isManager: false,
  fleet: undefined,
  event: undefined,
});

const signupsAllowed = computed(() =>
  props.signupsOpen === undefined ? !props.signupsLocked : props.signupsOpen,
);

const { t, tExists } = useI18n();

// The API sends the enum value, so a turret seat read TURRET_GUNNER once the
// label uppercased it. Unmapped values still read as words.
const positionTypeLabel = computed(() => {
  const type = props.slotData.positionType;
  if (!type) return null;

  const key = `labels.modelPosition.types.${type}`;

  return tExists(key) ? t(key) : type.replace(/_/g, " ");
});
const { displaySuccess, displayAlert } = useAppNotifications();
const comlink = useComlink();

const signupMutation = useSignupFleetEventSlot();

// Vehicle selection is only relevant when the slot is on a filter-mode ship
// (any ship matching the filter is acceptable). Specific-model ships and
// team-level slots have no vehicle choice to make.
const showVehiclePicker = computed(() => !!props.ship && !props.ship.model?.id);

const signupVehicleFitsHere = (signup: FleetEventSignup) =>
  vehicleMatchesShip(signup.vehicle, props.ship);

const extendedEvent = computed<FleetEventExtended | null>(() => {
  const e = props.event;
  if (e && "teams" in e) return e as FleetEventExtended;
  return null;
});

const canReassign = computed(
  () => props.isManager && !!props.fleet && !!extendedEvent.value,
);

const openReassign = (signup: FleetEventSignup) => {
  if (!props.fleet || !extendedEvent.value) return;
  comlink.emit("open-modal", {
    component: () =>
      import("@/frontend/components/Fleets/Events/EventSlotPickerModal/index.vue"),
    props: {
      fleet: props.fleet,
      event: extendedEvent.value,
      signup,
      currentSlotId: props.slotData.id,
    },
  });
};

const otherSignups = computed<FleetEventSignup[]>(() => {
  return (props.slotData.signups ?? []).filter(
    (signup) => signup.user?.id !== props.currentUserId,
  );
});

// Managers see their own signup in the signup list too so they can use the
// reassign affordance on themselves. Regular members only see other members.
const visibleSignups = computed<FleetEventSignup[]>(() =>
  props.isManager
    ? (props.slotData.signups ?? []).filter((s) => s.status !== "withdrawn")
    : otherSignups.value,
);

const ownSignupHere = computed<FleetEventSignup | null>(() => {
  return (
    (props.slotData.signups ?? []).find(
      (signup) => signup.user?.id === props.currentUserId,
    ) ?? null
  );
});

const ownSignupElsewhere = computed(
  () => !!props.ownActiveSlotId && props.ownActiveSlotId !== props.slotData.id,
);

const slotTaken = computed(() => otherSignups.value.length > 0);

const canSignup = computed(
  () =>
    signupsAllowed.value &&
    !ownSignupHere.value &&
    !ownSignupElsewhere.value &&
    !slotTaken.value,
);

const blockedReason = computed(() => {
  if (!signupsAllowed.value) return t("labels.fleets.events.signupsLockedHint");
  if (ownSignupElsewhere.value)
    return t("labels.fleets.events.alreadySignedUpHint");
  if (slotTaken.value) return t("labels.fleets.events.slotTakenHint");
  return "";
});

const expanded = ref(false);
const notes = ref("");
const vehicleId = ref<string | null>(null);

const startSignup = () => {
  notes.value = "";
  vehicleId.value = null;
  expanded.value = true;
};

const cancelSignup = () => {
  expanded.value = false;
};

const submitSignup = async () => {
  try {
    await signupMutation.mutateAsync({
      id: props.slotData.id,
      data: {
        status: FleetEventSignupStatus.confirmed,
        notes: notes.value.trim() || null,
        vehicleId: vehicleId.value ?? undefined,
      },
    });
    displaySuccess({ text: t("messages.fleets.eventSignup.create.success") });
    expanded.value = false;
    comlink.emit("fleet-event-signup-changed");
  } catch {
    displayAlert({ text: t("messages.fleets.eventSignup.create.failure") });
  }
};
</script>

<template>
  <div
    class="event-slot-row"
    :class="{
      'event-slot-row--mine': !!ownSignupHere,
      'event-slot-row--expanded': expanded,
    }"
    data-test="slot-row"
  >
    <header class="event-slot-row__head">
      <div class="event-slot-row__title">
        <span class="event-slot-row__name">{{ slotData.title }}</span>
        <span v-if="positionTypeLabel" class="event-slot-row__type">
          {{ positionTypeLabel }}
        </span>
      </div>
      <div class="event-slot-row__action">
        <!-- A chip, not a hand-rolled 999px pill: the state is carried by an
             icon as well as a tint, and its name reaches the a11y tree. -->
        <Chip v-if="ownSignupHere" :state="ChipStatesEnum.INCLUDED" bare>
          {{ t("labels.fleets.events.youAreHere") }}
        </Chip>
        <Btn
          v-else-if="!expanded"
          :size="BtnSizesEnum.XS"
          :disabled="!canSignup"
          :title="blockedReason"
          data-test="slot-signup"
          @click="startSignup"
        >
          <i class="fa-light fa-hand" />
          {{ t("actions.fleets.events.signup") }}
        </Btn>
      </div>
    </header>

    <p v-if="slotData.description" class="event-slot-row__description">
      {{ slotData.description }}
    </p>

    <ul v-if="visibleSignups.length" class="event-slot-row__signups">
      <li
        v-for="signup in visibleSignups"
        :key="signup.id"
        class="event-slot-row__signup"
      >
        <div class="event-slot-row__signup-line">
          <i
            class="fa-light"
            :class="
              signup.status === 'confirmed'
                ? 'fa-circle-check'
                : 'fa-circle-question'
            "
          />
          <span class="event-slot-row__signup-name">
            {{ signup.user?.username || "?" }}
          </span>
          <span class="event-slot-row__signup-status text-muted">
            {{ t(`labels.fleets.events.signupStatuses.${signup.status}`) }}
          </span>
          <span
            v-if="showVehiclePicker && signup.vehicle?.model?.name"
            class="event-slot-row__signup-vehicle text-muted"
          >
            · {{ signup.vehicle.model.name }}
          </span>
          <span
            v-if="showVehiclePicker && signupVehicleFitsHere(signup)"
            v-tooltip="t('labels.fleets.events.vehicleFitsHint')"
            class="event-slot-row__signup-fit"
          >
            <i class="fa-light fa-circle-check" />
          </span>
          <span
            v-else-if="showVehiclePicker && !signupVehicleFitsHere(signup)"
            v-tooltip="t('labels.fleets.events.vehicleMismatchHint')"
            class="event-slot-row__signup-warn"
          >
            <i class="fa-light fa-triangle-exclamation" />
          </span>
        </div>
        <p v-if="signup.notes" class="event-slot-row__signup-notes text-muted">
          <i class="fa-light fa-note-sticky" />
          <span>{{ signup.notes }}</span>
        </p>
        <div v-if="canReassign" class="event-slot-row__reassign">
          <Btn
            :size="BtnSizesEnum.XS"
            :variant="BtnVariantsEnum.BARE"
            @click="openReassign(signup)"
          >
            <i class="fa-light fa-arrow-right-arrow-left" />
            {{ t("actions.fleets.events.reassignSlot") }}
          </Btn>
        </div>
      </li>
    </ul>

    <div v-if="expanded" class="event-slot-row__form">
      <VehiclePicker
        v-if="showVehiclePicker"
        v-model="vehicleId"
        :required-ship="ship"
      />
      <FormTextarea
        v-model="notes"
        name="notes"
        :label="`${t('labels.fleets.events.notes')} (${t('labels.optional')})`"
      />
      <div class="event-slot-row__form-actions">
        <Btn :loading="signupMutation.isPending.value" @click="submitSignup">
          <i class="fa-light fa-check" />
          {{ t("actions.fleets.events.signup") }}
        </Btn>
        <Btn :variant="BtnVariantsEnum.BARE" @click="cancelSignup">
          {{ t("actions.cancel") }}
        </Btn>
      </div>
    </div>
  </div>
</template>

<style lang="scss" scoped>
/*
 * A list row, not a card. Six slots on a ship used to stack six bordered boxes
 * inside a bordered card inside a panel; one hairline per row is what the rest
 * of the app uses for a repeated record, and it is the "one box" principle both
 * the panel and button redesigns are built on.
 */
.event-slot-row {
  position: relative;
  padding: 9px 0 9px 12px;
  border-bottom: 1px solid var(--color-edge-faint, rgb(122 130 136 / 0.16));
  transition: background-color 150ms ease;
}

.event-slot-row:last-child {
  border-bottom: 0;
}

/*
 * "This one is yours" borrows metrics-card__tile--primary's rail rather than
 * recolouring a border, which is the pattern the redesign retired. It reads at
 * row scale and it is already in the codebase.
 */
.event-slot-row--mine::before {
  content: "";
  position: absolute;
  left: 0;
  top: 8px;
  bottom: 8px;
  width: 3px;
  border-radius: 2px;
  background: linear-gradient(
    var(--color-primary, #428bca),
    rgb(66 139 202 / 0.15)
  );
}

.event-slot-row--expanded {
  background-color: rgb(0 0 0 / 0.2);
}

.event-slot-row__head {
  display: flex;
  justify-content: space-between;
  align-items: center;
  gap: 12px;
  flex-wrap: wrap;
}

.event-slot-row__title {
  display: flex;
  align-items: baseline;
  gap: 10px;
  min-width: 0;
  flex: 1;
}

.event-slot-row__name {
  font-size: 14.5px;
  font-weight: 600;
  color: var(--color-lifted, #eee);
}

.event-slot-row__type {
  /* Never at the name's expense: as a flex sibling it used to take its share and
     break a seat called "Turret Side Back Left" over four lines. */
  flex: none;
  white-space: nowrap;
  font-family: "Orbitron", tahoma, sans-serif;
  font-size: 10px;
  letter-spacing: 0.16em;
  text-transform: uppercase;
  color: var(--color-gray-light, #7a8288);
}

.event-slot-row__action {
  flex: none;
}

.event-slot-row__description {
  margin: 6px 0 0;
  font-size: 13px;
  white-space: pre-wrap;
  color: var(--color-muted, #7a8288);
}

.event-slot-row__signups {
  list-style: none;
  padding: 0;
  margin: 8px 0 0;
  display: flex;
  flex-direction: column;
  gap: 6px;
}

.event-slot-row__signup-line {
  display: flex;
  align-items: center;
  gap: 7px;
  font-size: 13.5px;
  flex-wrap: wrap;

  i {
    color: var(--color-muted, #7a8288);
  }
}

.event-slot-row__signup-name {
  min-width: 0;
  overflow-wrap: anywhere;
  font-weight: 600;
  color: var(--color-lifted, #eee);
}

.event-slot-row__signup-status,
.event-slot-row__signup-vehicle {
  font-size: 13px;
  color: var(--color-muted, #7a8288);
}

.event-slot-row__signup-notes {
  display: flex;
  gap: 7px;
  margin: 2px 0 0;
  padding-left: 20px;
  font-size: 13px;
  white-space: pre-wrap;
  color: var(--color-muted, #7a8288);

  i {
    margin-top: 3px;
  }
}

.event-slot-row__signup-fit {
  color: var(--color-success, #5cb85c);
}

.event-slot-row__signup-warn {
  color: var(--color-warning, #fa6800);
}

.event-slot-row__reassign {
  margin-top: 4px;
}

/* Solid, not dashed - a dashed rule appears nowhere else in the app. */
.event-slot-row__form {
  margin-top: 10px;
  padding-top: 10px;
  border-top: 1px solid var(--color-edge-faint, rgb(122 130 136 / 0.16));
}

.event-slot-row__form-actions {
  display: flex;
  flex-wrap: wrap;
  gap: 10px;
  margin-top: 12px;
}

@media (prefers-reduced-motion: reduce) {
  .event-slot-row {
    transition-duration: 1ms;
  }
}
</style>
