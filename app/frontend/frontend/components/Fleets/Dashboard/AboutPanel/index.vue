<script lang="ts">
export default {
  name: "FleetDashboardAboutPanel",
};
</script>

<script lang="ts" setup>
import { liveQuery } from "@/frontend/components/Fleets/Dashboard/liveQuery";
import DashboardPanel from "@/frontend/components/Fleets/Dashboard/DashboardPanel/index.vue";
import DashboardEmpty from "@/frontend/components/Fleets/Dashboard/DashboardEmpty/index.vue";
import SquadronStrip from "@/frontend/components/Fleets/SquadronStrip/index.vue";
import Markdown from "@/shared/components/Markdown/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import { useFeatures } from "@/frontend/composables/useFeatures";
import {
  useFleetSquadrons,
  type Fleet,
  type FleetMember,
} from "@/services/fyApi";

type Props = {
  fleet: Fleet;
  membership: FleetMember;
};

const props = defineProps<Props>();

const { t } = useI18n();

const { isFleetSquadronsEnabled } = useFeatures();

const showSquadrons = computed(
  () =>
    isFleetSquadronsEnabled(props.fleet) &&
    (props.membership.capabilities?.readSquadrons ?? false),
);

const {
  data: squadrons,
  isLoading,
  isFetching,
  isLoadingError,
} = useFleetSquadrons(
  computed(() => props.fleet.slug),
  { perPage: "all" },
  { query: { ...liveQuery, enabled: showSquadrons } },
);

const allSquadrons = computed(() =>
  showSquadrons.value ? (squadrons.value?.items ?? []) : [],
);

// Two strips, the same split the squadrons page draws: a member belongs to one
// squadron and can be on any number of teams.
const squadronList = computed(() =>
  allSquadrons.value.filter((squadron) => !squadron.team),
);

const teamList = computed(() =>
  allSquadrons.value.filter((squadron) => squadron.team),
);

const empty = computed(
  () => !props.fleet.description && !allSquadrons.value.length,
);

const canEdit = computed(
  () => props.membership.capabilities?.manageFleet ?? false,
);
</script>

<template>
  <DashboardPanel
    :title="t('fleetDashboard.about.title')"
    :pending="showSquadrons && isLoading"
    :fetching="showSquadrons && isFetching"
    :failed="showSquadrons && isLoadingError"
    :empty="empty"
    data-test="fleet-dashboard-about"
  >
    <!-- Markdown renders a fragment, so it never carries this component's
         scope id. -->
    <div v-if="fleet.description" class="about-panel__description">
      <Markdown :source="fleet.description" />
    </div>
    <SquadronStrip
      v-if="squadronList.length"
      :fleet="fleet"
      :squadrons="squadronList"
      class="about-panel__strip"
      linked
    />
    <SquadronStrip
      v-if="teamList.length"
      :fleet="fleet"
      :squadrons="teamList"
      class="about-panel__strip"
      linked
    />
    <template #empty>
      <DashboardEmpty
        icon="fa-scroll"
        :title="t('fleetDashboard.about.empty.title')"
        :hint="
          canEdit
            ? t('fleetDashboard.about.empty.hintEdit')
            : t('fleetDashboard.about.empty.hint')
        "
      >
        <router-link
          v-if="canEdit"
          :to="{ name: 'fleet-settings-fleet', params: { slug: fleet.slug } }"
          data-test="fleet-dashboard-about-edit"
        >
          {{ t("fleetDashboard.about.empty.action") }}
          <i class="fa-light fa-chevron-right" aria-hidden="true" />
        </router-link>
      </DashboardEmpty>
    </template>
  </DashboardPanel>
</template>

<style lang="scss" scoped>
.about-panel__description {
  max-height: 480px;
  overflow-y: auto;
}

.about-panel__strip {
  margin-top: 12px;
}
</style>
