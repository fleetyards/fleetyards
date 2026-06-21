<script lang="ts">
export default {
  name: "FleetEventsAdminsModal",
};
</script>

<script lang="ts" setup>
import Modal from "@/shared/components/AppModal/Inner/index.vue";
import Btn from "@/shared/components/base/Btn/index.vue";
import { BtnSizesEnum } from "@/shared/components/base/Btn/types";
import FilterGroup from "@/shared/components/base/FilterGroup/index.vue";
import {
  type Fleet,
  type FleetEvent,
  type FleetEventAdmin,
  type FleetMember,
  type FilterOption,
  FleetEventAdminCreateInputRole,
  useFleetEventAdmins,
  useCreateFleetEventAdmin,
  useDestroyFleetEventAdmin,
  useFleetMembers,
} from "@/services/fyApi";
import { useI18n } from "@/shared/composables/useI18n";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";
import { useComlink } from "@/shared/composables/useComlink";

type Props = {
  fleet: Fleet;
  event: FleetEvent;
};

const props = defineProps<Props>();

const { t } = useI18n();
const { displaySuccess, displayAlert, displayConfirm } = useAppNotifications();
const comlink = useComlink();

const fleetSlug = computed(() => props.fleet.slug);
const eventSlug = computed(() => props.event.slug);

const { data: admins, refetch } = useFleetEventAdmins(fleetSlug, eventSlug);
const adminsList = computed<FleetEventAdmin[]>(() => admins.value ?? []);

const { data: membersData } = useFleetMembers(fleetSlug, ref({}));

const memberOptions = computed<FilterOption[]>(() => {
  const items =
    (membersData.value as { items?: FleetMember[] } | undefined)?.items ?? [];
  const granted = new Set(adminsList.value.map((a) => a.user.id));
  return items
    .filter((m) => !!m.userId && !granted.has(m.userId))
    .map((m) => ({ value: m.userId as string, label: m.username }));
});

const selectedUserId = ref<string | null>(null);
const selectedRole = ref<FleetEventAdminCreateInputRole>(
  FleetEventAdminCreateInputRole.admin,
);

const roleOptions = computed<FilterOption[]>(() =>
  Object.values(FleetEventAdminCreateInputRole).map((value) => ({
    value,
    label: t(`labels.fleets.events.eventRoles.${value}`),
  })),
);

const createMutation = useCreateFleetEventAdmin();
const destroyMutation = useDestroyFleetEventAdmin();

const grant = async () => {
  if (!selectedUserId.value) return;
  try {
    await createMutation.mutateAsync({
      fleetSlug: props.fleet.slug,
      slug: props.event.slug,
      data: {
        userId: selectedUserId.value,
        role: selectedRole.value,
      },
    });
    displaySuccess({ text: t("messages.fleets.eventAdmin.create.success") });
    selectedUserId.value = null;
    void refetch();
    comlink.emit("fleet-event-updated");
  } catch {
    displayAlert({ text: t("messages.fleets.eventAdmin.create.failure") });
  }
};

const revoke = (admin: FleetEventAdmin) => {
  displayConfirm({
    text: t("messages.fleets.eventAdmin.destroy.confirm", {
      username: admin.user.username,
    }),
    confirmText: t("actions.fleets.events.revokeRole"),
    onConfirm: async () => {
      try {
        await destroyMutation.mutateAsync({
          fleetSlug: props.fleet.slug,
          slug: props.event.slug,
          id: admin.id,
        });
        displaySuccess({
          text: t("messages.fleets.eventAdmin.destroy.success"),
        });
        void refetch();
        comlink.emit("fleet-event-updated");
      } catch {
        displayAlert({
          text: t("messages.fleets.eventAdmin.destroy.failure"),
        });
      }
    },
  });
};
</script>

<template>
  <Modal :title="t('headlines.fleets.events.eventTeam')">
    <p class="text-muted">{{ t("labels.fleets.events.eventTeamHint") }}</p>

    <section class="event-admins">
      <header class="event-admins__head">
        <strong>{{ t("labels.fleets.events.creator") }}</strong>
      </header>
      <div class="event-admins__creator">
        <i class="fa-light fa-crown" />
        <span>{{
          (event as { createdBy?: { username?: string } | null })?.createdBy
            ?.username || "—"
        }}</span>
      </div>
    </section>

    <section class="event-admins">
      <header class="event-admins__head">
        <strong>{{ t("labels.fleets.events.grantedRoles") }}</strong>
      </header>
      <ul v-if="adminsList.length" class="event-admins__list">
        <li
          v-for="entry in adminsList"
          :key="entry.id"
          class="event-admins__entry"
        >
          <i
            class="fa-light"
            :class="
              entry.role === 'admin' ? 'fa-shield-halved' : 'fa-user-shield'
            "
          />
          <strong>{{ entry.user.username }}</strong>
          <span class="event-admins__role">
            {{ t(`labels.fleets.events.eventRoles.${entry.role}`) }}
          </span>
          <Btn
            :size="BtnSizesEnum.SMALL"
            inline
            variant="link"
            @click="revoke(entry)"
          >
            <i class="fa-light fa-xmark" />
            {{ t("actions.fleets.events.revokeRole") }}
          </Btn>
        </li>
      </ul>
      <p v-else class="text-muted small">
        {{ t("labels.fleets.events.noEventAdminsYet") }}
      </p>
    </section>

    <section class="event-admins event-admins--grant">
      <header class="event-admins__head">
        <strong>{{ t("headlines.fleets.events.grantRole") }}</strong>
      </header>
      <div class="event-admins__form">
        <FilterGroup
          v-model="selectedUserId"
          :options="memberOptions"
          :label="t('labels.fleets.events.memberPicker')"
          inline
          name="memberPicker"
          :searchable="true"
          :nullable="true"
        />
        <FilterGroup
          v-model="selectedRole"
          :options="roleOptions"
          :label="t('labels.fleets.events.eventRole')"
          name="rolePicker"
          :searchable="false"
          inline
        />
        <Btn
          :size="BtnSizesEnum.SMALL"
          inline
          :disabled="!selectedUserId"
          :loading="createMutation.isPending.value"
          @click="grant"
        >
          <i class="fa-light fa-plus" />
          {{ t("actions.fleets.events.grantRole") }}
        </Btn>
      </div>
    </section>

    <template #footer>
      <div class="float-sm-right">
        <Btn
          :size="BtnSizesEnum.LARGE"
          inline
          variant="link"
          @click="comlink.emit('close-modal')"
        >
          {{ t("actions.close") }}
        </Btn>
      </div>
    </template>
  </Modal>
</template>

<style lang="scss" scoped>
.event-admins {
  display: flex;
  flex-direction: column;
  gap: 0.4rem;
  margin-top: 0.85rem;
}
.event-admins__head {
  font-size: 0.78rem;
  text-transform: uppercase;
  letter-spacing: 0.05em;
  color: var(--text-muted);
}
.event-admins__creator {
  display: inline-flex;
  align-items: center;
  gap: 0.4rem;

  i {
    color: var(--gold, #f5c542);
  }
}
.event-admins__list {
  list-style: none;
  margin: 0;
  padding: 0;
  display: flex;
  flex-direction: column;
  gap: 0.3rem;
}
.event-admins__entry {
  display: inline-flex;
  align-items: center;
  gap: 0.45rem;
  padding: 0.4rem 0.55rem;
  background: rgba(255, 255, 255, 0.03);
  border-radius: 4px;

  i {
    color: var(--text-muted);
  }
}
.event-admins__role {
  font-size: 0.7rem;
  text-transform: uppercase;
  letter-spacing: 0.05em;
  padding: 0.1rem 0.4rem;
  border-radius: 999px;
  background: rgba(74, 170, 170, 0.18);
  color: var(--accent, #4aa);
  margin-right: auto;
}
.event-admins__form {
  display: grid;
  grid-template-columns: 1fr 1fr auto;
  gap: 0.4rem;
  align-items: end;
}
@media (max-width: 480px) {
  .event-admins__form {
    grid-template-columns: 1fr;
  }
}
.small {
  font-size: 0.78rem;
}
</style>
