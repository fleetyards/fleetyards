<script lang="ts">
export default {
  name: "AdminHomePage",
};
</script>

<script lang="ts" setup>
import Heading from "@/shared/components/base/Heading/index.vue";
import StatsPanel from "@/shared/components/StatsPanel/index.vue";
import Panel from "@/shared/components/base/Panel/index.vue";
import PanelHeading from "@/shared/components/base/Panel/Heading/index.vue";
import PanelBody from "@/shared/components/base/Panel/Body/index.vue";
import Chart from "@/shared/components/Chart/index.vue";
import AttentionTile from "@/admin/components/Dashboard/AttentionTile.vue";
import LinkTile from "@/admin/components/Dashboard/LinkTile.vue";
import EditFeed from "@/admin/components/Dashboard/EditFeed.vue";
import { useI18n } from "@/shared/composables/useI18n";
import {
  useDashboard as useDashboardQuery,
  useVisitsPerDay as useVisitsPerDayQuery,
  useMostViewedPages as useMostViewedPagesQuery,
  useVisitsPerMonth as useVisitsPerMonthQuery,
  useRegistrationsPerMonth as useRegistrationsPerMonthQuery,
} from "@/services/fyAdminApi";
import { useSessionStore } from "@/admin/stores/session";

const { t, lUtc: l, timeDistance } = useI18n();

const sessionStore = useSessionStore();

const hasStats = () => sessionStore.hasAccessTo("stats");

/*
 * One request for every figure on the page, refetched by the query client rather
 * than by a hand-rolled interval - a `setInterval` started in `onMounted` was
 * never cleared, so each visit to this page stacked another poll on top of the
 * last.
 */
const { data: dashboard } = useDashboardQuery({
  query: { refetchInterval: 30_000 },
});

/*
 * A queue with nothing in it is not news. The band renders only the tiles with
 * a count above zero and collapses entirely when they are all clear, so a
 * populated attention row always means something needs doing.
 *
 * A figure the admin has no privilege for is absent rather than zero, which is
 * why a missing key is never treated as an "all clear" worth showing.
 */
const attentionTiles = computed(() =>
  [
    {
      key: "unlistedModels",
      count: dashboard.value?.unlistedModelsCount,
      icon: "fa-duotone fa-rocket fa-4x",
      to: { name: "admin-unlisted-models" },
      severity: "warning" as const,
    },
    {
      key: "failedImports",
      count: dashboard.value?.failedImportsCount,
      icon: "fa-duotone fa-file-import fa-4x",
      to: { name: "imports" },
      severity: "error" as const,
    },
    {
      key: "stuckImports",
      count: dashboard.value?.stuckImportsCount,
      icon: "fa-duotone fa-hourglass-half fa-4x",
      to: { name: "imports" },
      severity: "warning" as const,
    },
    {
      key: "deadJobs",
      count: dashboard.value?.jobsDeadCount,
      icon: "fa-duotone fa-skull fa-4x",
      to: { name: "workers" },
      severity: "error" as const,
    },
    {
      key: "retryJobs",
      count: dashboard.value?.jobsRetryCount,
      icon: "fa-duotone fa-arrow-rotate-right fa-4x",
      to: { name: "workers" },
      severity: "warning" as const,
    },
    {
      key: "rsiRequestLogs",
      count: dashboard.value?.unresolvedRsiRequestLogsCount,
      icon: "fa-duotone fa-plug-circle-xmark fa-4x",
      to: { name: "rsi-api-status" },
      severity: "error" as const,
    },
    {
      key: "notifications",
      count: dashboard.value?.actionableNotificationsCount,
      icon: "fa-duotone fa-bell-exclamation fa-4x",
      to: { name: "admin-notifications" },
      severity: "warning" as const,
    },
  ].filter((tile) => (tile.count ?? 0) > 0),
);

const percentDelta = (current?: number, before?: number) => {
  if (current === undefined || !before) {
    return undefined;
  }

  const delta = Math.round(((current - before) / before) * 100);

  return `${delta > 0 ? "+" : ""}${delta}%`;
};

const visitsDelta = computed(() =>
  percentDelta(
    dashboard.value?.visitsToday,
    dashboard.value?.visitsSameWeekdayLastWeek,
  ),
);

const signupsDelta = computed(() =>
  percentDelta(
    dashboard.value?.signupsThisWeek,
    dashboard.value?.signupsLastWeek,
  ),
);

// "4.9.0-live.12344265" -> "4.9.0". The build id is nineteen characters that
// would force this one value to a smaller size than every other card on the row;
// it rides in the tooltip instead. A version with no build id is shown whole.
const cataloguePatch = computed(() => {
  const version = dashboard.value?.catalogueVersion;

  if (!version) {
    return t("labels.admin.dashboard.catalogueUnknown");
  }

  return version.split("-")[0];
});

const catalogueTooltip = computed(() => {
  const version = dashboard.value?.catalogueVersion;

  if (!version) {
    return false;
  }

  const loadedAt = dashboard.value?.catalogueLoadedAt;

  if (!loadedAt) {
    return version;
  }

  return `${version} — ${l(loadedAt, "datetime.formats.short")}`;
});

const { data: visitsPerDay, ...visitsPerDayStatus } = useVisitsPerDayQuery({
  query: { enabled: hasStats },
});

const { data: mostViewedPages, ...mostViewedPagesStatus } =
  useMostViewedPagesQuery({ query: { enabled: hasStats } });

const { data: visitsPerMonth, ...visitsPerMonthStatus } =
  useVisitsPerMonthQuery({ query: { enabled: hasStats } });

const { data: registrationsPerMonth, ...registrationsPerMonthStatus } =
  useRegistrationsPerMonthQuery({ query: { enabled: hasStats } });
</script>

<template>
  <Teleport to="#header-left">
    <Heading hero>{{ t("headlines.admin.dashboard.title") }}</Heading>
  </Teleport>

  <section>
    <div v-if="attentionTiles.length" class="row" data-test="attention-band">
      <div
        v-for="tile in attentionTiles"
        :key="tile.key"
        class="col-12 col-sm-6 col-lg-4 col-xl mb-4"
      >
        <AttentionTile
          :count="tile.count || 0"
          :label="t(`labels.admin.dashboard.attention.${tile.key}`)"
          :icon="tile.icon"
          :to="tile.to"
          :severity="tile.severity"
        />
      </div>
    </div>

    <div class="row">
      <div class="col-12 col-sm-6 col-lg-3">
        <StatsPanel
          icon="fa-duotone fa-user fa-4x"
          :value="dashboard?.onlineCount || 0"
          :label="t('labels.admin.dashboard.quickStats.onlineUsers')"
        />
      </div>
      <div class="col-12 col-sm-6 col-lg-3">
        <StatsPanel
          icon="fa-duotone fa-chart-line fa-4x"
          :value="dashboard?.visitsToday || 0"
          :label="t('labels.admin.dashboard.quickStats.visitsToday')"
          :suffix="visitsDelta"
        />
      </div>
      <div class="col-12 col-sm-6 col-lg-3">
        <StatsPanel
          icon="fa-duotone fa-user-plus fa-4x"
          :value="dashboard?.signupsThisWeek || 0"
          :label="t('labels.admin.dashboard.quickStats.signupsThisWeek')"
          :suffix="signupsDelta"
        />
      </div>
      <div class="col-12 col-sm-6 col-lg-3">
        <LinkTile
          v-tooltip="catalogueTooltip"
          icon="fa-duotone fa-database fa-4x"
          :label="t('headlines.admin.dashboard.catalogue')"
          :value="cataloguePatch"
          :suffix="
            dashboard?.catalogueLoadedAt
              ? timeDistance(dashboard.catalogueLoadedAt)
              : undefined
          "
          :to="{ name: 'imports' }"
        />
      </div>
    </div>

    <div class="row">
      <div class="col-12 col-md-7">
        <Panel fill-height>
          <PanelHeading>
            {{ t("headlines.admin.dashboard.visitsPerDay") }}
          </PanelHeading>
          <PanelBody class="dashboard-panel-body">
            <Chart
              name="visits-per-day"
              type="area"
              :options="visitsPerDay"
              :async-status="visitsPerDayStatus"
              tooltip-type="visit"
              :height="292"
              admin
            />
          </PanelBody>
        </Panel>
      </div>
      <div class="col-12 col-md-5">
        <Panel fill-height>
          <PanelHeading>
            {{ t("headlines.admin.dashboard.mostViewedPages") }}
          </PanelHeading>
          <PanelBody class="dashboard-panel-body">
            <Chart
              name="most-viewed-pages"
              type="bar"
              :options="mostViewedPages"
              :async-status="mostViewedPagesStatus"
              tooltip-type="view"
              :height="292"
              admin
            />
          </PanelBody>
        </Panel>
      </div>
    </div>

    <div class="row">
      <div class="col-12 col-md-6">
        <Panel fill-height>
          <PanelHeading>
            {{ t("headlines.admin.dashboard.visitsPerMonth") }}
          </PanelHeading>
          <PanelBody class="dashboard-panel-body">
            <Chart
              name="visits-per-month"
              type="column"
              :options="visitsPerMonth"
              :async-status="visitsPerMonthStatus"
              tooltip-type="visit"
              :height="320"
              admin
            />
          </PanelBody>
        </Panel>
      </div>
      <div class="col-12 col-md-6">
        <Panel fill-height>
          <PanelHeading>
            {{ t("headlines.admin.dashboard.registrationsPerMonth") }}
          </PanelHeading>
          <PanelBody class="dashboard-panel-body">
            <Chart
              name="registrations-per-month"
              type="column"
              :options="registrationsPerMonth"
              :async-status="registrationsPerMonthStatus"
              tooltip-type="user"
              :height="320"
              admin
            />
          </PanelBody>
        </Panel>
      </div>
    </div>

    <div class="row">
      <div class="col-12">
        <EditFeed />
      </div>
    </div>
  </section>
</template>

<style lang="scss" scoped>
.dashboard-panel-body {
  position: relative;
  flex: 1;
}
</style>
