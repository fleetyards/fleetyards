<script lang="ts">
export default {
  name: "FleetDashboardInventoryPanel",
};
</script>

<script lang="ts" setup>
import { liveQuery } from "@/frontend/components/Fleets/Dashboard/liveQuery";
import DashboardPanel from "@/frontend/components/Fleets/Dashboard/DashboardPanel/index.vue";
import DashboardEmpty from "@/frontend/components/Fleets/Dashboard/DashboardEmpty/index.vue";
import ActivityList from "@/frontend/components/Fleets/Dashboard/ActivityList/index.vue";
import Btn from "@/shared/components/base/Btn/index.vue";
import BtnGroup from "@/shared/components/base/BtnGroup/index.vue";
import { BtnSizesEnum } from "@/shared/components/base/Btn/types";
import { useI18n } from "@/shared/composables/useI18n";
import {
  FleetActivityCategoryEnum,
  useFleetActivity,
  type Fleet,
} from "@/services/fyApi";

type Props = {
  fleet: Fleet;
};

const props = defineProps<Props>();

const { t } = useI18n();

const SHOWN = 6;

// Read as one page and split here: what touches the reader is a handful of
// the fleet's recent movements, not a list of its own worth a second request.
// The page is deeper than the panel because "mine" is picked out of it, and in
// a busy fleet the reader's own movements are not the latest few. Anything
// older is on the logistics page the panel links to.
const READ = 30;

const { data, isLoading, isFetching, isLoadingError } = useFleetActivity(
  computed(() => props.fleet.slug),
  { category: FleetActivityCategoryEnum.INVENTORY, limit: READ },
  { query: liveQuery },
);

const all = computed(() => data.value?.items ?? []);

const scope = ref<"mine" | "fleet">("mine");

const mine = computed(() => all.value.filter((entry) => entry.involvesViewer));

const entries = computed(() =>
  (scope.value === "mine" ? mine.value : all.value).slice(0, SHOWN),
);

// Nothing of the reader's own lately is not worth a panel that says so; the
// fleet's movements are the better opening. Decided once, on the first answer,
// so a refetch never takes back a choice the reader made.
let scopeChosen = false;

watch(
  () => data.value,
  (value) => {
    if (!value || scopeChosen) return;

    scopeChosen = true;
    if (!mine.value.length) scope.value = "fleet";
  },
  { immediate: true },
);
</script>

<template>
  <DashboardPanel
    :title="t('fleetDashboard.inventory.title')"
    :pending="isLoading"
    :fetching="isFetching"
    :failed="isLoadingError"
    :empty="!entries.length"
    :more="{ name: 'fleet-logistics', params: { slug: fleet.slug } }"
    data-test="fleet-dashboard-inventory"
  >
    <!-- The scope is chosen on the first answer, so the switch waits for it
         rather than jumping from one side to the other, and a fleet with no
         movements at all has nothing to switch between. -->
    <template v-if="all.length" #actions>
      <BtnGroup segmented>
        <Btn
          :size="BtnSizesEnum.SM"
          :active="scope === 'mine'"
          data-test="fleet-dashboard-inventory-mine"
          @click="scope = 'mine'"
        >
          {{ t("fleetDashboard.inventory.mine") }}
        </Btn>
        <Btn
          :size="BtnSizesEnum.SM"
          :active="scope === 'fleet'"
          data-test="fleet-dashboard-inventory-fleet"
          @click="scope = 'fleet'"
        >
          {{ t("fleetDashboard.inventory.fleet") }}
        </Btn>
      </BtnGroup>
    </template>
    <ActivityList :fleet="fleet" :entries="entries" />
    <template #empty>
      <DashboardEmpty
        icon="fa-boxes-stacked"
        :title="
          scope === 'mine'
            ? t('fleetDashboard.inventory.emptyMine')
            : t('fleetDashboard.inventory.empty')
        "
        :hint="t('fleetDashboard.inventory.emptyHint')"
      />
    </template>
  </DashboardPanel>
</template>
