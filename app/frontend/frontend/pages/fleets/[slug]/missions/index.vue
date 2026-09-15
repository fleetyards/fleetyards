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
import { BtnSizesEnum } from "@/shared/components/base/Btn/types";
import Grid from "@/shared/components/base/Grid/index.vue";
import FilteredList from "@/shared/components/FilteredList/index.vue";
import GridSkeleton from "@/shared/components/GridSkeleton/index.vue";
import Empty from "@/shared/components/Empty/index.vue";
import EmptyInfo from "@/shared/components/Empty/Info/index.vue";
import { EmptyVariantsEnum } from "@/shared/components/Empty/types";
import MissionPanel from "@/frontend/components/Fleets/Missions/MissionPanel/index.vue";
import MissionsTable from "@/frontend/components/Fleets/Missions/MissionsTable/index.vue";
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
import { storeToRefs } from "pinia";
import { useMissionsStore } from "@/frontend/stores/missions";

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

// Which of the two tabs came back empty, so the box says what is missing here
// rather than that the fleet has no missions at all.
const emptyKey = computed(() => (showArchived.value ? "archived" : "active"));

const missionsStore = useMissionsStore();
const { gridView } = storeToRefs(missionsStore);

const openDisplayOptionsModal = () => {
  comlink.emit("open-modal", {
    component: () =>
      import("@/shared/components/DisplayOptionsModal/index.vue"),
    props: {
      gridView: gridView.value,
      testPrefix: "missions",
      updateCallback: (next: boolean) => {
        missionsStore.gridView = next;
      },
    },
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

  <!-- Creating a mission is what this page is for, so it sits in the header
       beside the fleet's own actions - where the events and contracts pages
       already put theirs - rather than in the list's toolbar. -->
  <Teleport to="#header-right">
    <Btn
      v-if="canCreate"
      :size="BtnSizesEnum.MD"
      :aria-label="t('actions.fleets.missions.create')"
      data-test="create-mission"
      mobile-icon-only
      @click="goToCreate"
    >
      <i class="fa-light fa-plus" />
      <span>{{ t("actions.fleets.missions.create") }}</span>
    </Btn>
  </Teleport>

  <FilteredList
    key="fleet-missions-index"
    :name="route.name?.toString() || ''"
    :records="missionList"
    :async-status="asyncStatus"
    :hide-empty="!gridView"
    :placeholders="!gridView"
  >
    <template #actions-right>
      <Btn
        :size="BtnSizesEnum.SM"
        :aria-label="t('actions.models.openTableConfiguration')"
        data-test="missions-display-options"
        @click="openDisplayOptionsModal"
      >
        <i class="fa-duotone fa-sliders" />
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

    <!-- Only the grid needs placeholder cards. In table view the slot is gone,
         which hands the wait to `placeholders` below: the table draws its own
         header and a page of placeholder rows out of an empty record set,
         which is closer to what arrives than cards would be. -->
    <template v-if="gridView" #skeleton="{ filterVisible }">
      <GridSkeleton :filter-visible="filterVisible" />
    </template>

    <template #empty>
      <Empty :variant="EmptyVariantsEnum.BOX" data-test="fleet-missions-empty">
        <template #headline="{ queryPresent }">
          <span v-if="!queryPresent">
            {{ t(`empty.fleets.missions.${emptyKey}`) }}
          </span>
        </template>

        <template #info="{ queryPresent }">
          <EmptyInfo v-if="queryPresent" :query-present="queryPresent" />
          <template v-else>
            <p>{{ t(`empty.fleets.missions.info.${emptyKey}`) }}</p>
            <!-- The create button lives here rather than in the `actions`
                 slot: Empty only renders its footer when a filter or a page
                 sent the reader here, and this box is what a fleet with no
                 missions at all sees. -->
            <Btn v-if="canCreate && !showArchived" @click="goToCreate">
              <i class="fa-light fa-plus" />
              <span>{{ t("actions.fleets.missions.create") }}</span>
            </Btn>
          </template>
        </template>
      </Empty>
    </template>

    <template #default="{ records, emptyVisible }">
      <Grid v-if="gridView" :records="records as Mission[]" primary-key="id">
        <template #default="{ record }">
          <MissionPanel
            :mission="record"
            :fleet="fleet"
            :editable="canCreate"
          />
        </template>
      </Grid>

      <!-- The dense view: every mission on one screen, in the app's table.
           The table draws its own empty row inside its frame, so the list's
           panel would be a second one under it - hence `hide-empty` above. -->
      <MissionsTable
        v-else
        :fleet="fleet"
        :missions="records as Mission[]"
        :async-status="asyncStatus"
        :empty-visible="emptyVisible"
      />
    </template>
  </FilteredList>
</template>
