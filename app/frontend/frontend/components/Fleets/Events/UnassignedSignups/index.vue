<script lang="ts">
export default {
  name: "FleetEventsUnassignedSignups",
};
</script>

<script lang="ts" setup>
import Btn from "@/shared/components/base/Btn/index.vue";
import { BtnSizesEnum } from "@/shared/components/base/Btn/types";
import {
  type Fleet,
  type FleetEventExtended,
  type FleetEventSignup,
  useDestroyFleetEventSignup,
} from "@/services/fyApi";
import { useI18n } from "@/shared/composables/useI18n";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";
import { useComlink } from "@/shared/composables/useComlink";

type Props = {
  fleet: Fleet;
  event: FleetEventExtended;
  signups: FleetEventSignup[];
};

const props = defineProps<Props>();

const { t } = useI18n();
const { displaySuccess, displayAlert, displayConfirm } = useAppNotifications();
const comlink = useComlink();

const destroyMutation = useDestroyFleetEventSignup();

const openAssign = (signup: FleetEventSignup) => {
  comlink.emit("open-modal", {
    component: () =>
      import("@/frontend/components/Fleets/Events/EventSlotPickerModal/index.vue"),
    props: {
      fleet: props.fleet,
      event: props.event,
      signup,
    },
  });
};

const remove = (signup: FleetEventSignup) => {
  displayConfirm({
    text: t("messages.fleets.eventSignup.kick.confirm"),
    confirmText: t("actions.fleets.events.kick"),
    onConfirm: async () => {
      try {
        await destroyMutation.mutateAsync({ id: signup.id });
        displaySuccess({ text: t("messages.fleets.eventSignup.kick.success") });
        comlink.emit("fleet-event-signup-changed");
      } catch {
        displayAlert({
          text: t("messages.fleets.eventSignup.kick.failure"),
        });
      }
    },
  });
};
</script>

<template>
  <section v-if="signups.length" class="unassigned-signups">
    <header class="unassigned-signups__head">
      <i class="fa-light fa-people-arrows" />
      <span>{{ t("headlines.fleets.events.unassignedSignups") }}</span>
      <span class="unassigned-signups__count">{{ signups.length }}</span>
    </header>
    <p class="text-muted small">
      {{ t("labels.fleets.events.unassignedSignupsHint") }}
    </p>

    <ul class="unassigned-signups__list">
      <li
        v-for="signup in signups"
        :key="signup.id"
        class="unassigned-signups__item"
      >
        <div class="unassigned-signups__person">
          <i
            class="fa-light"
            :class="
              signup.status === 'confirmed'
                ? 'fa-circle-check'
                : signup.status === 'pending'
                  ? 'fa-hourglass-half'
                  : signup.status === 'tentative'
                    ? 'fa-circle-question'
                    : 'fa-eye'
            "
          />
          <strong>{{ signup.user?.username || "?" }}</strong>
          <span class="text-muted small">
            {{ t(`labels.fleets.events.signupStatuses.${signup.status}`) }}
          </span>
        </div>
        <p v-if="signup.notes" class="unassigned-signups__notes text-muted">
          <i class="fa-light fa-note-sticky" />
          {{ signup.notes }}
        </p>
        <div class="unassigned-signups__actions">
          <Btn :size="BtnSizesEnum.SMALL" inline @click="openAssign(signup)">
            <i class="fa-light fa-arrow-right-arrow-left" />
            {{ t("actions.fleets.events.assignSlot") }}
          </Btn>
          <Btn
            :size="BtnSizesEnum.SMALL"
            inline
            variant="danger"
            @click="remove(signup)"
          >
            <i class="fa-light fa-xmark" />
            {{ t("actions.fleets.events.kick") }}
          </Btn>
        </div>
      </li>
    </ul>
  </section>
</template>

<style lang="scss" scoped>
.unassigned-signups {
  background: rgba(255, 152, 0, 0.06);
  border: 1px solid rgba(255, 152, 0, 0.35);
  border-radius: 6px;
  padding: 0.85rem 1rem;
  display: flex;
  flex-direction: column;
  gap: 0.6rem;
}
.unassigned-signups__head {
  display: inline-flex;
  align-items: center;
  gap: 0.5rem;
  font-weight: 600;
  text-transform: uppercase;
  letter-spacing: 0.04em;

  i {
    color: var(--warning, #ff9800);
  }
}
.unassigned-signups__count {
  font-size: 0.7rem;
  padding: 0.1rem 0.45rem;
  border-radius: 999px;
  background: var(--warning, #ff9800);
  color: #000;
}
.unassigned-signups__list {
  list-style: none;
  margin: 0;
  padding: 0;
  display: flex;
  flex-direction: column;
  gap: 0.5rem;
}
.unassigned-signups__item {
  display: flex;
  flex-direction: column;
  gap: 0.3rem;
  padding: 0.55rem 0.75rem;
  background: rgba(255, 255, 255, 0.03);
  border-radius: 4px;
}
.unassigned-signups__person {
  display: flex;
  align-items: center;
  gap: 0.45rem;
  font-size: 0.92rem;
  flex-wrap: wrap;

  i {
    color: var(--text-muted);
  }
}
.unassigned-signups__notes {
  display: flex;
  gap: 0.4rem;
  margin: 0;
  font-size: 0.82rem;
  white-space: pre-wrap;

  i {
    margin-top: 0.2rem;
  }
}
.unassigned-signups__actions {
  display: flex;
  flex-wrap: wrap;
  gap: 0.4rem;
  align-items: center;
}
.small {
  font-size: 0.78rem;
}
</style>
