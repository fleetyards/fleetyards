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
          <Btn :size="BtnSizesEnum.SM" @click="openAssign(signup)">
            <i class="fa-light fa-arrow-right-arrow-left" />
            {{ t("actions.fleets.events.assignSlot") }}
          </Btn>
          <Btn :size="BtnSizesEnum.SM" tone="danger" @click="remove(signup)">
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
  border-radius: var(--radius-control-bare, 6px);
  padding: 14px 16px;
  display: flex;
  flex-direction: column;
  gap: 10px;
}
.unassigned-signups__head {
  display: inline-flex;
  align-items: center;
  gap: 8px;
  font-weight: 600;
  text-transform: uppercase;
  letter-spacing: 0.04em;

  i {
    color: var(--color-warning, #fa6800);
  }
}
.unassigned-signups__count {
  font-size: 11px;
  padding: 2px 7px;
  border-radius: var(--radius-control-bare, 6px);
  background: var(--color-warning, #fa6800);
  color: #000;
}
.unassigned-signups__list {
  list-style: none;
  margin: 0;
  padding: 0;
  display: flex;
  flex-direction: column;
  gap: 8px;
}
.unassigned-signups__item {
  display: flex;
  flex-direction: column;
  gap: 4px;
  padding: 9px 12px;
  background: rgba(255, 255, 255, 0.03);
  border-radius: var(--radius-control-bare, 6px);
}
.unassigned-signups__person {
  display: flex;
  align-items: center;
  gap: 7px;
  font-size: 14px;
  flex-wrap: wrap;

  i {
    color: var(--color-muted, #7a8288);
  }
}
.unassigned-signups__notes {
  display: flex;
  gap: 6px;
  margin: 0;
  font-size: 13px;
  white-space: pre-wrap;

  i {
    margin-top: 4px;
  }
}
.unassigned-signups__actions {
  display: flex;
  flex-wrap: wrap;
  gap: 6px;
  align-items: center;
}
.small {
  font-size: 12px;
}
</style>
