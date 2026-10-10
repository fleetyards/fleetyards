<script lang="ts">
export default {
  name: "FleetDashboardInventoryPanel",
};
</script>

<script lang="ts" setup>
import DashboardPanel from "@/frontend/components/Fleets/Dashboard/DashboardPanel/index.vue";
import ActivityList from "@/frontend/components/Fleets/Dashboard/ActivityList/index.vue";
import Btn from "@/shared/components/base/Btn/index.vue";
import BtnGroup from "@/shared/components/base/BtnGroup/index.vue";
import { BtnSizesEnum } from "@/shared/components/base/Btn/types";
import { useI18n } from "@/shared/composables/useI18n";
import type { Fleet, FleetActivity } from "@/services/fyApi";

type Props = {
  fleet: Fleet;
  // The fleet's movements, from the dashboard's one activity answer.
  entries?: FleetActivity[];
  loading?: boolean;
};

const props = withDefaults(defineProps<Props>(), {
  entries: undefined,
  loading: false,
});

const { t } = useI18n();

const SHOWN = 6;

const scope = ref<"mine" | "fleet">("mine");

const mine = computed(() =>
  (props.entries ?? []).filter((entry) => entry.involvesViewer),
);

const shown = computed(() =>
  (scope.value === "mine" ? mine.value : (props.entries ?? [])).slice(0, SHOWN),
);

// Nothing of the reader's own lately is not worth a panel that says so; the
// fleet's movements are the better opening. Decided once, on the first answer,
// so a refetch never takes back a choice the reader made.
let scopeChosen = false;

watch(
  () => props.entries,
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
    v-if="props.entries?.length"
    :title="t('fleetDashboard.inventory.title')"
    :loading="loading"
    :empty="!shown.length"
    :empty-text="
      scope === 'mine'
        ? t('fleetDashboard.inventory.emptyMine')
        : t('fleetDashboard.inventory.empty')
    "
    :more="{ name: 'fleet-logistics', params: { slug: fleet.slug } }"
    data-test="fleet-dashboard-inventory"
  >
    <template #actions>
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
    <ActivityList :fleet="fleet" :entries="shown" />
  </DashboardPanel>
</template>
