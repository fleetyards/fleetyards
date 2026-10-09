<script lang="ts">
export default {
  name: "FleetDashboardHealthPanel",
};
</script>

<script lang="ts" setup>
import type { RouteLocationRaw } from "vue-router";
import DashboardPanel from "@/frontend/components/Fleets/Dashboard/DashboardPanel/index.vue";
import Avatar from "@/shared/components/Avatar/index.vue";
import { liveQuery } from "@/frontend/components/Fleets/Dashboard/liveQuery";
import { useI18n } from "@/shared/composables/useI18n";
import {
  useFleetHealth,
  type Fleet,
  type FleetHealthMembers,
} from "@/services/fyApi";

type Props = {
  fleet: Fleet;
};

const props = defineProps<Props>();

const { t } = useI18n();

const { data } = useFleetHealth(
  computed(() => props.fleet.slug),
  {
    query: liveQuery,
  },
);

type Row = {
  key: string;
  icon: string;
  label: string;
  members?: FleetHealthMembers["sample"];
  names?: string[];
  to: RouteLocationRaw;
};

const membersPage = computed(() => ({
  name: "fleet-members-index",
  params: { slug: props.fleet.slug },
}));

// Each a loose end with somewhere to go and tie it; a question with nothing to
// report is left out rather than reported as fine.
const rows = computed<Row[]>(() => {
  const health = data.value;
  if (!health) return [];

  const result: Row[] = [];

  if (health.inactiveMembers.count) {
    result.push({
      key: "inactive",
      icon: "fa-moon",
      label: t("fleetDashboard.health.inactive", {
        count: health.inactiveMembers.count,
      }),
      members: health.inactiveMembers.sample,
      to: membersPage.value,
    });
  }

  if (health.unverifiedMembers?.count) {
    result.push({
      key: "unverified",
      icon: "fa-badge-check",
      label: t("fleetDashboard.health.unverified", {
        count: health.unverifiedMembers.count,
      }),
      members: health.unverifiedMembers.sample,
      to: membersPage.value,
    });
  }

  if (health.emptyRoles?.length) {
    result.push({
      key: "empty-roles",
      icon: "fa-user-slash",
      label: t("fleetDashboard.health.emptyRoles", {
        count: health.emptyRoles.length,
      }),
      names: health.emptyRoles.map(({ name }) => name),
      to: { name: "fleet-settings-roles", params: { slug: props.fleet.slug } },
    });
  }

  return result;
});
</script>

<template>
  <DashboardPanel
    v-if="rows.length"
    :title="t('fleetDashboard.health.title')"
    data-test="fleet-dashboard-health"
  >
    <ul class="fleet-health">
      <li
        v-for="row in rows"
        :key="row.key"
        class="fleet-health__row"
        :data-test="`fleet-dashboard-health-${row.key}`"
      >
        <router-link :to="row.to" class="fleet-health__headline">
          <i :class="['fa-light', row.icon]" aria-hidden="true" />
          {{ row.label }}
          <i class="fa-light fa-chevron-right" aria-hidden="true" />
        </router-link>
        <div v-if="row.members?.length" class="fleet-health__people">
          <Avatar
            v-for="member in row.members"
            :key="member.username"
            v-tooltip="member.nickname || member.username"
            :avatar="member.avatar?.smallUrl"
            size="small"
          />
        </div>
        <p v-if="row.names?.length" class="fleet-health__names">
          {{ row.names.join(", ") }}
        </p>
      </li>
    </ul>
  </DashboardPanel>
</template>

<style lang="scss" scoped>
.fleet-health {
  display: flex;
  flex-direction: column;
  gap: 16px;
  margin: 0;
  padding: 0;
  list-style: none;
}

.fleet-health__headline {
  display: flex;
  align-items: center;
  gap: 10px;
  color: var(--color-lifted, #eee);
  font-weight: 600;
}

.fleet-health__people {
  display: flex;
  flex-wrap: wrap;
  gap: 6px;
  margin-top: 8px;
}

.fleet-health__names {
  margin: 6px 0 0;
  color: var(--color-text-dim, #959595);
  font-size: 13px;
}
</style>
