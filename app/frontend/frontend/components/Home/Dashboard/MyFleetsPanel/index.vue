<script lang="ts">
export default {
  name: "HomeDashboardMyFleetsPanel",
};
</script>

<script lang="ts" setup>
import DashboardPanel from "@/shared/components/Dashboard/Panel/index.vue";
import DashboardEmpty from "@/shared/components/Dashboard/Empty/index.vue";
import { liveQuery } from "@/shared/components/Dashboard/liveQuery";
import RowListItem from "@/shared/components/RowListItem/index.vue";
import type { RowListItemBadge } from "@/shared/components/RowListItem/types";
import Avatar from "@/shared/components/Avatar/index.vue";
import { type MyFleetSummary, useMyFleetSummaries } from "@/services/fyApi";
import { useI18n } from "@/shared/composables/useI18n";

const { t, l } = useI18n();

const { data, isLoading, isFetching, isLoadingError } = useMyFleetSummaries({
  query: liveQuery,
});

const fleets = computed(() => data.value?.items || []);

// What is waiting on the reader, and only what their role can answer: the
// counts arrive only for such a role.
const badgesFor = (fleet: MyFleetSummary): RowListItemBadge[] => {
  const badges: RowListItemBadge[] = [];

  if (fleet.pendingJoinRequestsCount) {
    badges.push({
      key: "requests",
      label: t("home.dashboard.fleets.requests"),
      value: String(fleet.pendingJoinRequestsCount),
    });
  }

  if (fleet.pendingTransfersCount) {
    badges.push({
      key: "transfers",
      label: t("home.dashboard.fleets.transfers"),
      value: String(fleet.pendingTransfersCount),
    });
  }

  return badges;
};
</script>

<template>
  <DashboardPanel
    :title="t('home.dashboard.fleets.title')"
    :pending="isLoading"
    :fetching="isFetching"
    :failed="isLoadingError"
    :empty="!fleets.length"
    :more="{ name: 'fleets' }"
    data-test="home-my-fleets"
  >
    <div class="home-my-fleets">
      <RowListItem
        v-for="fleet in fleets"
        :key="fleet.id"
        :to="{ name: 'fleet', params: { slug: fleet.slug } }"
        :badges="badgesFor(fleet)"
      >
        <template #leading>
          <Avatar
            :avatar="fleet.logo?.smallUrl"
            size="small"
            icon="fa-duotone fa-users"
          />
        </template>
        <template #name>{{ fleet.name }}</template>
        <template #sub>
          <span v-if="fleet.roleName">{{ fleet.roleName }}</span>
          <span v-if="fleet.onlineCount !== undefined">
            {{
              t("home.dashboard.fleets.online", {
                count: fleet.onlineCount,
                total: fleet.memberCount,
              })
            }}
          </span>
          <span v-else>
            {{
              t("home.dashboard.fleets.members", { count: fleet.memberCount })
            }}
          </span>
        </template>
        <p v-if="fleet.latestAnnouncement" class="home-my-fleets__announcement">
          <time :datetime="fleet.latestAnnouncement.createdAt">
            {{
              l(fleet.latestAnnouncement.createdAt, "datetime.formats.short")
            }}
          </time>
          {{ fleet.latestAnnouncement.excerpt }}
        </p>
      </RowListItem>
    </div>
    <template #empty>
      <DashboardEmpty
        icon="fa-users"
        :title="t('home.dashboard.fleets.empty.title')"
        :hint="t('home.dashboard.fleets.empty.hint')"
      >
        <router-link :to="{ name: 'fleet-directory' }">
          {{ t("home.dashboard.fleets.empty.action") }}
        </router-link>
      </DashboardEmpty>
    </template>
  </DashboardPanel>
</template>

<style lang="scss" scoped>
.home-my-fleets {
  display: flex;
  flex-direction: column;
  gap: 8px;
}

.home-my-fleets__announcement {
  margin: 4px 0 0;
  overflow: hidden;
  color: var(--color-text-dim, #959595);
  font-size: 12.5px;
  text-overflow: ellipsis;
  white-space: nowrap;

  time {
    margin-right: 6px;
  }
}
</style>
