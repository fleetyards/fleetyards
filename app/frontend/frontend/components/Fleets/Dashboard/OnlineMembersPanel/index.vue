<script lang="ts">
export default {
  name: "FleetDashboardOnlineMembersPanel",
};
</script>

<script lang="ts" setup>
import DashboardPanel from "@/frontend/components/Fleets/Dashboard/DashboardPanel/index.vue";
import Avatar from "@/shared/components/Avatar/index.vue";
import { liveQuery } from "@/frontend/components/Fleets/Dashboard/liveQuery";
import { useI18n } from "@/shared/composables/useI18n";
import { useFleetOnlineMembers, type Fleet } from "@/services/fyApi";

type Props = {
  fleet: Fleet;
};

const props = defineProps<Props>();

const { t } = useI18n();

// Presence moves by the minute, and nobody reloads a dashboard to see it.
const REFRESH_MS = 60_000;

const { data } = useFleetOnlineMembers(
  computed(() => props.fleet.slug),
  {
    query: { ...liveQuery, refetchInterval: REFRESH_MS },
  },
);

const members = computed(() => data.value?.items ?? []);

const more = computed(
  () => (data.value?.totalCount ?? 0) - members.value.length,
);
</script>

<template>
  <DashboardPanel
    v-if="members.length"
    :title="t('fleetDashboard.online.title', { count: data?.totalCount ?? 0 })"
    :more="{ name: 'fleet-members-index', params: { slug: fleet.slug } }"
    data-test="fleet-dashboard-online"
  >
    <ul class="online-members">
      <li
        v-for="member in members"
        :key="member.username"
        class="online-members__member"
        :data-test="`fleet-dashboard-online-${member.username}`"
      >
        <Avatar :avatar="member.avatar?.smallUrl" size="small" :online="true" />
        <span class="online-members__name">
          {{ member.nickname || member.username }}
        </span>
        <i
          v-if="member.friend"
          v-tooltip="t('fleetDashboard.online.friend')"
          class="fa-light fa-user-group online-members__friend"
          :aria-label="t('fleetDashboard.online.friend')"
          data-test="fleet-dashboard-online-friend"
        />
      </li>
    </ul>
    <p v-if="more > 0" class="online-members__more">
      {{ t("fleetDashboard.online.more", { count: more }) }}
    </p>
  </DashboardPanel>
</template>

<style lang="scss" scoped>
.online-members {
  display: flex;
  flex-direction: column;
  gap: 8px;
  margin: 0;
  padding: 0;
  list-style: none;
}

.online-members__member {
  display: flex;
  align-items: center;
  gap: 10px;
  min-width: 0;
}

.online-members__name {
  flex: 1 1 auto;
  min-width: 0;
  overflow: hidden;
  color: var(--color-lifted, #eee);
  font-weight: 600;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.online-members__friend {
  color: var(--color-muted, #7a8288);
}

.online-members__more {
  margin: 10px 0 0;
  color: var(--color-text-dim, #959595);
  font-size: 13px;
}
</style>
