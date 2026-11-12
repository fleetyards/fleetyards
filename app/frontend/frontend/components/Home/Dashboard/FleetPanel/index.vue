<script lang="ts">
export default {
  name: "HomeDashboardFleetPanel",
};
</script>

<script lang="ts" setup>
import DashboardPanel from "@/shared/components/Dashboard/Panel/index.vue";
import DashboardEmpty from "@/shared/components/Dashboard/Empty/index.vue";
import { liveQuery } from "@/shared/components/Dashboard/liveQuery";
import Avatar from "@/shared/components/Avatar/index.vue";
import { type MyFleetSummary, useMyFleetSummaries } from "@/services/fyApi";
import { primaryFleet } from "@/frontend/components/Home/Dashboard/primaryFleet";
import { useI18n } from "@/shared/composables/useI18n";

const { t, l } = useI18n();

const { data, isLoading, isFetching, isLoadingError } = useMyFleetSummaries({
  query: liveQuery,
});

const fleets = computed(() => data.value?.items || []);

// Almost every pilot is in one fleet, so the panel is that fleet. The rare
// second one is a link away rather than a list everybody else pays for.
const fleet = computed(() => primaryFleet(fleets.value));

const others = computed(() =>
  fleets.value.filter((item) => item.id !== fleet.value?.id),
);

// Only what the reader's role can answer: the counts arrive only for such a
// role. Every fleet's, so a request waiting in a second fleet is not lost
// behind its name link.
const pendingFor = (item: MyFleetSummary) =>
  [
    {
      key: `${item.id}-requests`,
      label: t("home.dashboard.fleet.requests"),
      count: item.pendingJoinRequestsCount || 0,
      to: { name: "fleet-members", params: { slug: item.slug } },
    },
    {
      key: `${item.id}-transfers`,
      label: t("home.dashboard.fleet.transfers"),
      count: item.pendingTransfersCount || 0,
      to: { name: "fleet-logistics-transfers", params: { slug: item.slug } },
    },
  ]
    .filter((entry) => entry.count)
    .map((entry) => ({
      ...entry,
      fleetName: item.id === fleet.value?.id ? undefined : item.name,
    }));

const pending = computed(() => {
  const primary = fleet.value;
  if (!primary) return [];

  return [primary, ...others.value].flatMap(pendingFor);
});
</script>

<template>
  <DashboardPanel
    :title="t('home.dashboard.fleet.title')"
    :pending="isLoading"
    :fetching="isFetching"
    :failed="isLoadingError"
    :empty="!fleet"
    :more="fleet ? { name: 'fleet', params: { slug: fleet.slug } } : undefined"
    :more-label="t('home.dashboard.fleet.open')"
    data-test="home-fleet"
  >
    <div v-if="fleet" class="home-fleet">
      <router-link
        :to="{ name: 'fleet', params: { slug: fleet.slug } }"
        class="home-fleet__head"
      >
        <Avatar :avatar="fleet.logo?.smallUrl" icon="fa-duotone fa-users" />
        <span class="home-fleet__identity">
          <span class="home-fleet__name">{{ fleet.name }}</span>
          <span class="home-fleet__sub">
            <span v-if="fleet.roleName">{{ fleet.roleName }}</span>
            <span v-if="fleet.onlineCount !== undefined">
              {{
                t("home.dashboard.fleet.online", {
                  count: fleet.onlineCount,
                  total: fleet.memberCount,
                })
              }}
            </span>
            <span v-else>
              {{
                t("home.dashboard.fleet.members", { count: fleet.memberCount })
              }}
            </span>
          </span>
        </span>
      </router-link>

      <div
        v-if="fleet.latestAnnouncement"
        class="home-fleet__announcement"
        data-test="home-fleet-announcement"
      >
        <span class="home-fleet__label">
          {{ t("home.dashboard.fleet.announcement") }} ·
          <time :datetime="fleet.latestAnnouncement.createdAt">
            {{
              l(fleet.latestAnnouncement.createdAt, "datetime.formats.short")
            }}
          </time>
        </span>
        <p>{{ fleet.latestAnnouncement.excerpt }}</p>
      </div>

      <router-link
        v-for="item in pending"
        :key="item.key"
        :to="item.to"
        class="home-fleet__pending"
      >
        <span>
          {{ item.label }}
          <span v-if="item.fleetName" class="home-fleet__pending-fleet">
            · {{ item.fleetName }}
          </span>
        </span>
        <span class="home-fleet__count">{{ item.count }}</span>
      </router-link>

      <p v-if="others.length" class="home-fleet__others">
        {{ t("home.dashboard.fleet.others") }}
        <template v-for="(other, index) in others" :key="other.id">
          <router-link :to="{ name: 'fleet', params: { slug: other.slug } }">
            {{ other.name }}</router-link
          ><template v-if="index < others.length - 1">, </template>
        </template>
      </p>
    </div>
    <template #empty>
      <DashboardEmpty
        icon="fa-users"
        :title="t('home.dashboard.fleet.empty.title')"
        :hint="t('home.dashboard.fleet.empty.hint')"
      >
        <router-link :to="{ name: 'fleet-directory' }">
          {{ t("home.dashboard.fleet.empty.action") }}
        </router-link>
      </DashboardEmpty>
    </template>
  </DashboardPanel>
</template>

<style lang="scss" scoped>
.home-fleet {
  display: flex;
  flex-direction: column;
  gap: 12px;
}

.home-fleet__head {
  display: flex;
  align-items: center;
  gap: 12px;
  color: inherit;
  text-decoration: none;
}

.home-fleet__identity {
  display: flex;
  flex-direction: column;
  min-width: 0;
}

.home-fleet__name {
  overflow: hidden;
  color: var(--color-lifted, #eee);
  font-size: 1rem;
  font-weight: 600;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.home-fleet__sub {
  display: flex;
  flex-wrap: wrap;
  gap: 4px 10px;
  color: var(--color-text-dim, #959595);
  font-size: 0.75rem;
}

.home-fleet__announcement {
  padding: 10px 12px;
  border: 1px solid var(--color-edge-faint, rgb(122 130 136 / 0.16));
  border-radius: 10px;
  background: var(--color-gray-black, #1a1d21);

  p {
    margin: 4px 0 0;
    color: var(--color-lifted, #eee);
    font-size: 0.8125rem;
  }
}

.home-fleet__label {
  color: var(--color-text-dim, #959595);
  font-size: 0.6875rem;
  letter-spacing: 0.08em;
  text-transform: uppercase;
}

.home-fleet__pending {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 12px;
  min-height: 44px;
  padding: 0 12px;
  border: 1px solid var(--color-edge-faint, rgb(122 130 136 / 0.16));
  border-radius: 10px;
  background: var(--color-gray-black, #1a1d21);
  color: inherit;
  text-decoration: none;

  &:hover {
    border-color: var(--color-edge, rgb(122 130 136 / 0.5));
  }
}

.home-fleet__pending-fleet {
  color: var(--color-text-dim, #959595);
}

.home-fleet__count {
  color: var(--color-lifted, #eee);
  font-weight: 600;
}

.home-fleet__others {
  margin: 0;
  color: var(--color-text-dim, #959595);
  font-size: 0.8125rem;
}
</style>
