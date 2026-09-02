<script lang="ts">
export default {
  name: "FleetMissionsPage",
};
</script>

<script lang="ts" setup>
import BreadCrumbs from "@/shared/components/BreadCrumbs/index.vue";
import { type Crumb } from "@/shared/components/BreadCrumbs/types";
import Heading from "@/shared/components/base/Heading/index.vue";
import Btn from "@/shared/components/base/Btn/index.vue";
import BtnGroup from "@/shared/components/base/BtnGroup/index.vue";
import Grid from "@/shared/components/base/Grid/index.vue";
import FilteredList from "@/shared/components/FilteredList/index.vue";
import GridSkeleton from "@/shared/components/GridSkeleton/index.vue";
import MissionPanel from "@/frontend/components/Fleets/Missions/MissionPanel/index.vue";
import {
  type Fleet,
  type FleetMember,
  type Mission,
  useFleetMissions,
} from "@/services/fyApi";
import { useI18n } from "@/shared/composables/useI18n";
import { useComlink } from "@/shared/composables/useComlink";
import { checkAccess } from "@/shared/utils/Access";
import { useRouter } from "vue-router";

type Props = {
  fleet: Fleet;
  membership: FleetMember;
  resourceAccess?: string[];
};

const props = defineProps<Props>();

const { t } = useI18n();
const comlink = useComlink();
const route = useRoute();
const router = useRouter();

const fleetSlug = computed(() => props.fleet.slug);
const showArchived = ref(false);

const queryParams = computed(() => ({
  archived: showArchived.value || undefined,
}));

const {
  data: missions,
  refetch,
  ...asyncStatus
} = useFleetMissions(fleetSlug, queryParams);

const missionList = computed<Mission[]>(() => missions.value?.items ?? []);

const canCreate = computed(() =>
  checkAccess(props.resourceAccess, [
    "fleet:manage",
    "fleet:missions:manage",
    "fleet:missions:create",
  ]),
);

const goToCreate = () => {
  void router.push({
    name: "fleet-mission-new",
    params: { slug: props.fleet.slug },
  });
};

const fleetMissionCreatedComlink = ref<() => void>();
const fleetMissionUpdatedComlink = ref<() => void>();

onMounted(() => {
  fleetMissionCreatedComlink.value = comlink.on(
    "fleet-mission-created",
    () => void refetch(),
  );
  fleetMissionUpdatedComlink.value = comlink.on(
    "fleet-mission-updated",
    () => void refetch(),
  );
});

onUnmounted(() => {
  fleetMissionCreatedComlink.value?.();
  fleetMissionUpdatedComlink.value?.();
});

const crumbs = computed<Crumb[]>(() => [
  {
    to: { name: "fleet", params: { slug: props.fleet.slug } },
    label: props.fleet.name,
  },
  {
    to: { name: "fleet-events", params: { slug: props.fleet.slug } },
    label: t("headlines.fleets.events.index"),
  },
]);
</script>

<template>
  <BreadCrumbs :crumbs="crumbs" />

  <Heading size="hero" hero>
    {{ t("headlines.fleets.missions.index") }}
  </Heading>

  <FilteredList
    key="fleet-missions-index"
    :name="route.name?.toString() || ''"
    :records="missionList"
    :async-status="asyncStatus"
    hide-empty
  >
    <template v-if="canCreate" #actions-right>
      <Btn @click="goToCreate">
        <i class="fa-light fa-plus" />
        <span>{{ t("actions.fleets.missions.create") }}</span>
      </Btn>
    </template>

    <template #actions-left>
      <BtnGroup segmented>
        <Btn
          :active="!showArchived"
          mobile-icon-only
          @click="showArchived = false"
        >
          <i class="fa-light fa-flag" />
          {{ t("labels.fleets.missions.activeTab") }}
        </Btn>
        <Btn
          :active="showArchived"
          mobile-icon-only
          @click="showArchived = true"
        >
          <i class="fa-light fa-box-archive" />
          {{ t("labels.fleets.missions.archivedTab") }}
        </Btn>
      </BtnGroup>
    </template>

    <template #skeleton="{ filterVisible }">
      <GridSkeleton :filter-visible="filterVisible" />
    </template>

    <template #default="{ records }">
      <Grid :records="records as Mission[]" primary-key="id">
        <template #default="{ record }">
          <MissionPanel
            :mission="record"
            :fleet="fleet"
            :editable="canCreate"
          />
        </template>
      </Grid>
    </template>
  </FilteredList>
</template>
