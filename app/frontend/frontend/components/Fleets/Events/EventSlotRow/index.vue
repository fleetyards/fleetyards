<script lang="ts">
export default {
  name: "FleetEventsSlotRow",
};
</script>

<script lang="ts" setup>
import Btn from "@/shared/components/base/Btn/index.vue";
import { BtnSizesEnum } from "@/shared/components/base/Btn/types";
import FormTextarea from "@/shared/components/base/FormTextarea/index.vue";
import FilterGroup from "@/shared/components/base/FilterGroup/index.vue";
import {
  type FleetEventSignup,
  type FleetEventSlot,
  type FilterOption,
  FleetEventSignupStatus,
  useSignupFleetEventSlot,
} from "@/services/fyApi";
import { useI18n } from "@/shared/composables/useI18n";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";
import { useComlink } from "@/shared/composables/useComlink";

type Props = {
  slotData: FleetEventSlot;
  currentUserId?: string;
  signupsLocked: boolean;
  // Slot id where the current user is already signed up (anywhere in the event)
  ownActiveSlotId?: string | null;
};

const props = defineProps<Props>();

const { t } = useI18n();
const { displaySuccess, displayAlert } = useAppNotifications();
const comlink = useComlink();

const signupMutation = useSignupFleetEventSlot();

const otherSignups = computed<FleetEventSignup[]>(() => {
  return (props.slotData.signups ?? []).filter(
    (signup) => signup.user?.id !== props.currentUserId,
  );
});

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
    !props.signupsLocked &&
    !ownSignupHere.value &&
    !ownSignupElsewhere.value &&
    !slotTaken.value,
);

const blockedReason = computed(() => {
  if (props.signupsLocked) return t("labels.fleets.events.signupsLockedHint");
  if (ownSignupElsewhere.value)
    return t("labels.fleets.events.alreadySignedUpHint");
  if (slotTaken.value) return t("labels.fleets.events.slotTakenHint");
  return "";
});

const expanded = ref(false);
const status = ref<FleetEventSignupStatus>(FleetEventSignupStatus.confirmed);
const notes = ref("");

const statusOptions = computed<FilterOption[]>(() =>
  [FleetEventSignupStatus.confirmed, FleetEventSignupStatus.tentative].map(
    (value) => ({
      value,
      label: t(`labels.fleets.events.signupStatuses.${value}`),
    }),
  ),
);

const startSignup = () => {
  status.value = FleetEventSignupStatus.confirmed;
  notes.value = "";
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
        status: status.value,
        notes: notes.value.trim() || undefined,
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
  >
    <header class="event-slot-row__head">
      <div class="event-slot-row__title">
        <strong>{{ slotData.title }}</strong>
        <span v-if="slotData.positionType" class="event-slot-row__type">
          {{ slotData.positionType }}
        </span>
      </div>
      <div class="event-slot-row__action">
        <span v-if="ownSignupHere" class="event-slot-row__here-badge">
          <i class="fa-light fa-check" />
          {{ t("labels.fleets.events.youAreHere") }}
        </span>
        <Btn
          v-else-if="!expanded"
          :size="BtnSizesEnum.SMALL"
          inline
          :disabled="!canSignup"
          :title="blockedReason"
          @click="startSignup"
        >
          <i class="fa-light fa-hand" />
          {{ t("actions.fleets.events.signup") }}
        </Btn>
      </div>
    </header>

    <p
      v-if="slotData.description"
      class="event-slot-row__description text-muted"
    >
      <i class="fa-light fa-circle-info" />
      <span>{{ slotData.description }}</span>
    </p>

    <ul v-if="otherSignups.length" class="event-slot-row__signups">
      <li
        v-for="signup in otherSignups"
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
        </div>
        <p
          v-if="signup.notes"
          class="event-slot-row__signup-notes text-muted"
        >
          <i class="fa-light fa-note-sticky" />
          <span>{{ signup.notes }}</span>
        </p>
      </li>
    </ul>

    <div v-if="expanded" class="event-slot-row__form">
      <FilterGroup
        v-model="status"
        :options="statusOptions"
        :label="t('labels.fleets.events.attendance')"
        name="signup-status"
        :searchable="false"
      />
      <FormTextarea
        v-model="notes"
        name="notes"
        :label="`${t('labels.fleets.events.notes')} (${t('labels.optional')})`"
      />
      <div class="event-slot-row__form-actions">
        <Btn
          :size="BtnSizesEnum.SMALL"
          inline
          :loading="signupMutation.isPending.value"
          @click="submitSignup"
        >
          <i class="fa-light fa-check" />
          {{ t("actions.fleets.events.signup") }}
        </Btn>
        <Btn :size="BtnSizesEnum.SMALL" inline variant="link" @click="cancelSignup">
          {{ t("actions.cancel") }}
        </Btn>
      </div>
    </div>
  </div>
</template>

<style lang="scss" scoped>
.event-slot-row {
  background: rgba(255, 255, 255, 0.03);
  border-radius: 4px;
  padding: 0.55rem 0.75rem;
  border: 1px solid rgba(255, 255, 255, 0.05);
  transition: border-color 0.15s;
}
.event-slot-row--mine {
  border-color: var(--accent, #4aa);
  box-shadow: inset 0 0 0 1px var(--accent, #4aa);
}
.event-slot-row--expanded {
  border-color: rgba(255, 255, 255, 0.18);
}
.event-slot-row__head {
  display: flex;
  justify-content: space-between;
  align-items: center;
  gap: 0.6rem;
}
.event-slot-row__title {
  display: flex;
  flex-direction: column;
  gap: 0.1rem;
  min-width: 0;
  flex: 1;
}
.event-slot-row__type {
  font-size: 0.7rem;
  text-transform: uppercase;
  letter-spacing: 0.05em;
  color: var(--text-muted);
}
.event-slot-row__here-badge {
  display: inline-flex;
  align-items: center;
  gap: 0.3rem;
  font-size: 0.78rem;
  padding: 0.2rem 0.5rem;
  border-radius: 999px;
  background: rgba(74, 170, 170, 0.18);
  color: var(--accent, #4aa);
  white-space: nowrap;
}
.event-slot-row__description {
  display: flex;
  gap: 0.4rem;
  font-size: 0.82rem;
  margin: 0.35rem 0 0;
  white-space: pre-wrap;

  i {
    margin-top: 0.2rem;
  }
}
.event-slot-row__signups {
  list-style: none;
  padding: 0;
  margin: 0.4rem 0 0;
  display: flex;
  flex-direction: column;
  gap: 0.35rem;
}
.event-slot-row__signup {
  display: flex;
  flex-direction: column;
  gap: 0.15rem;
}
.event-slot-row__signup-line {
  display: inline-flex;
  align-items: center;
  gap: 0.4rem;
  font-size: 0.85rem;

  i {
    color: var(--text-muted);
  }
}
.event-slot-row__signup-name {
  font-weight: 500;
}
.event-slot-row__signup-status {
  font-size: 0.72rem;
}
.event-slot-row__signup-notes {
  display: flex;
  gap: 0.4rem;
  margin: 0;
  padding-left: 1.4rem;
  font-size: 0.8rem;
  white-space: pre-wrap;

  i {
    margin-top: 0.2rem;
    color: var(--text-muted);
  }
}
.event-slot-row__form {
  margin-top: 0.6rem;
  padding-top: 0.6rem;
  border-top: 1px dashed rgba(255, 255, 255, 0.1);
}
.event-slot-row__form-actions {
  display: flex;
  gap: 0.4rem;
}
</style>
