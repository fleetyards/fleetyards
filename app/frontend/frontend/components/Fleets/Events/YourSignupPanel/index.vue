<script lang="ts">
export default {
  name: "FleetEventsYourSignupPanel",
};
</script>

<script lang="ts" setup>
import Btn from "@/shared/components/base/Btn/index.vue";
import { BtnSizesEnum } from "@/shared/components/base/Btn/types";
import FormTextarea from "@/shared/components/base/FormTextarea/index.vue";
import FilterGroup from "@/shared/components/base/FilterGroup/index.vue";
import VehiclePicker from "@/frontend/components/Fleets/Events/VehiclePicker/index.vue";
import {
  type FilterOption,
  type FleetEventShip,
  type FleetEventSignup,
  FleetEventSignupStatus,
  useUpdateFleetEventSignup,
  useWithdrawFleetEventSignup,
  useDestroyFleetEventSignup,
  signupFleetEvent,
} from "@/services/fyApi";
import { useI18n } from "@/shared/composables/useI18n";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";
import { useComlink } from "@/shared/composables/useComlink";

type Props = {
  signup: FleetEventSignup;
  slotTitle: string;
  contextLabel?: string;
  ship?: FleetEventShip | null;
  fleetSlug: string;
  eventSlug: string;
};

const props = withDefaults(defineProps<Props>(), {
  contextLabel: undefined,
  ship: null,
});

const { t } = useI18n();
const { displaySuccess, displayAlert, displayConfirm } = useAppNotifications();
const comlink = useComlink();

const updateMutation = useUpdateFleetEventSignup();
const withdrawMutation = useWithdrawFleetEventSignup();
const destroyMutation = useDestroyFleetEventSignup();

const slotId = computed(() => props.signup.fleetEventSlotId ?? null);
const canEdit = computed(() => true);
const isEventLevel = computed(() => !slotId.value);
// Picker is relevant for event-level signups (no slot) and slots on
// filter-mode ships. Specific-model ships and team-level slots fix the
// vehicle implicitly.
const showVehiclePicker = computed(
  () => isEventLevel.value || (!!props.ship && !props.ship.model?.id),
);

const editing = ref(false);
const saving = ref(false);

const notes = ref(props.signup.notes ?? "");
const vehicleId = ref<string | null>(props.signup.vehicle?.id ?? null);
const status = ref<FleetEventSignupStatus>(
  (props.signup.status as FleetEventSignupStatus) ??
    FleetEventSignupStatus.interested,
);

const eventLevelStatusOptions = computed<FilterOption[]>(() =>
  [
    FleetEventSignupStatus.confirmed,
    FleetEventSignupStatus.tentative,
    FleetEventSignupStatus.interested,
  ].map((value) => ({
    value,
    label: t(`labels.fleets.events.signupStatuses.${value}`),
  })),
);

const startEdit = () => {
  notes.value = props.signup.notes ?? "";
  vehicleId.value = props.signup.vehicle?.id ?? null;
  status.value =
    (props.signup.status as FleetEventSignupStatus) ??
    FleetEventSignupStatus.interested;
  editing.value = true;
};

const cancelEdit = () => {
  editing.value = false;
};

const save = async () => {
  saving.value = true;
  try {
    if (slotId.value) {
      await updateMutation.mutateAsync({
        id: slotId.value,
        data: {
          status: FleetEventSignupStatus.confirmed,
          notes: notes.value || undefined,
          vehicleId: vehicleId.value ?? undefined,
        },
      });
    } else {
      await signupFleetEvent(props.fleetSlug, props.eventSlug, {
        status: status.value,
        notes: notes.value || undefined,
        vehicleId: vehicleId.value ?? undefined,
      });
    }
    displaySuccess({ text: t("messages.fleets.eventSignup.update.success") });
    editing.value = false;
    comlink.emit("fleet-event-signup-changed");
  } catch {
    displayAlert({ text: t("messages.fleets.eventSignup.update.failure") });
  } finally {
    saving.value = false;
  }
};

const withdraw = () => {
  displayConfirm({
    text: t("messages.fleets.eventSignup.withdraw.confirm"),
    confirmText: t("actions.fleets.events.withdraw"),
    onConfirm: async () => {
      try {
        if (slotId.value) {
          await withdrawMutation.mutateAsync({ id: slotId.value });
        } else {
          await destroyMutation.mutateAsync({ id: props.signup.id });
        }
        displaySuccess({
          text: t("messages.fleets.eventSignup.withdraw.success"),
        });
        comlink.emit("fleet-event-signup-changed");
      } catch {
        displayAlert({
          text: t("messages.fleets.eventSignup.withdraw.failure"),
        });
      }
    },
  });
};

const statusLabel = computed(() =>
  t(`labels.fleets.events.signupStatuses.${props.signup.status}`),
);
</script>

<template>
  <section class="your-signup">
    <header class="your-signup__head">
      <div class="your-signup__title">
        <i class="fa-light fa-user-check" />
        <span>{{ t("headlines.fleets.events.yourSignup") }}</span>
      </div>
      <span
        class="your-signup__status"
        :class="`your-signup__status--${signup.status}`"
      >
        {{ statusLabel }}
      </span>
    </header>

    <div class="your-signup__location">
      <i class="fa-light fa-location-pin" />
      <strong>{{ slotTitle }}</strong>
      <span v-if="contextLabel" class="text-muted">— {{ contextLabel }}</span>
    </div>

    <p v-if="!editing && signup.notes" class="your-signup__notes">
      <i class="fa-light fa-note-sticky" />
      {{ signup.notes }}
    </p>

    <template v-if="editing">
      <FilterGroup
        v-if="isEventLevel"
        v-model="status"
        :options="eventLevelStatusOptions"
        :label="t('labels.fleets.events.attendance')"
        name="signup-status"
        :searchable="false"
      />
      <VehiclePicker
        v-if="showVehiclePicker"
        v-model="vehicleId"
        :required-ship="ship"
      />
      <FormTextarea
        v-model="notes"
        name="notes"
        :label="t('labels.fleets.events.notes')"
      />
    </template>

    <div class="your-signup__actions">
      <template v-if="editing">
        <Btn :size="BtnSizesEnum.SMALL" inline :loading="saving" @click="save">
          <i class="fa-light fa-floppy-disk" />
          {{ t("actions.save") }}
        </Btn>
        <Btn
          :size="BtnSizesEnum.SMALL"
          inline
          variant="link"
          @click="cancelEdit"
        >
          {{ t("actions.cancel") }}
        </Btn>
      </template>
      <template v-else>
        <Btn
          v-if="canEdit"
          :size="BtnSizesEnum.SMALL"
          inline
          @click="startEdit"
        >
          <i class="fa-light fa-pen" />
          {{ t("actions.edit") }}
        </Btn>
        <Btn
          :size="BtnSizesEnum.SMALL"
          inline
          variant="danger"
          :loading="withdrawMutation.isPending.value"
          @click="withdraw"
        >
          <i class="fa-light fa-arrow-right-from-bracket" />
          {{ t("actions.fleets.events.withdraw") }}
        </Btn>
      </template>
    </div>
  </section>
</template>

<style lang="scss" scoped>
.your-signup {
  display: flex;
  flex-direction: column;
  gap: 0.5rem;
  padding: 0.85rem 1rem;
  border-radius: 6px;
  background: rgba(74, 170, 170, 0.1);
  border: 1px solid var(--accent, #4aa);
}
.your-signup__head {
  display: flex;
  justify-content: space-between;
  align-items: center;
  gap: 0.6rem;
}
.your-signup__title {
  display: inline-flex;
  align-items: center;
  gap: 0.5rem;
  font-weight: 600;
  font-size: 0.95rem;
  text-transform: uppercase;
  letter-spacing: 0.04em;

  i {
    color: var(--accent, #4aa);
  }
}
.your-signup__status {
  font-size: 0.7rem;
  text-transform: uppercase;
  letter-spacing: 0.04em;
  padding: 0.15rem 0.5rem;
  border-radius: 999px;
  border: 1px solid currentColor;
}
.your-signup__status--confirmed {
  color: var(--success, #4caf50);
}
.your-signup__status--tentative {
  color: var(--warning, #ff9800);
}
.your-signup__location {
  display: inline-flex;
  align-items: center;
  gap: 0.4rem;

  i {
    color: var(--text-muted);
  }
}
.your-signup__notes {
  display: flex;
  gap: 0.5rem;
  margin: 0;
  font-size: 0.9rem;
  white-space: pre-wrap;

  i {
    color: var(--text-muted);
    margin-top: 0.25rem;
  }
}
.your-signup__actions {
  display: flex;
  gap: 0.4rem;
  flex-wrap: wrap;
}
</style>
