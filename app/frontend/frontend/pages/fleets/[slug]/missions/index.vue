<script lang="ts">
export default {
  name: "FleetMissionsPage",
};
</script>

<script lang="ts" setup>
import BreadCrumbs from "@/shared/components/BreadCrumbs/index.vue";
import Heading from "@/shared/components/base/Heading/index.vue";
import Btn from "@/shared/components/base/Btn/index.vue";
import BtnGroup from "@/shared/components/base/BtnGroup/index.vue";
import Grid from "@/shared/components/base/Grid/index.vue";
import FilteredList from "@/shared/components/FilteredList/index.vue";
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

type Props = {
  fleet: Fleet;
  membership: FleetMember;
  resourceAccess?: string[];
};

const props = defineProps<Props>();

const { t } = useI18n();
const comlink = useComlink();
const route = useRoute();

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

const openCreateModal = () => {
  comlink.emit("open-modal", {
    component: () =>
      import("@/frontend/components/Fleets/Missions/MissionModal/index.vue"),
    props: {
      fleet: props.fleet,
    },
  });
};

onMounted(() => {
  comlink.on("fleet-mission-created", () => void refetch());
  comlink.on("fleet-mission-updated", () => void refetch());
});

const crumbs = computed(() => [
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
      <Btn size="small" @click="openCreateModal">
        <i class="fa-light fa-plus" />
        <span>{{ t("actions.fleets.missions.create") }}</span>
      </Btn>
    </template>

    <template #actions-left>
      <BtnGroup>
        <Btn
          :active="!showArchived"
          inline
          size="small"
          @click="showArchived = false"
        >
          {{ t("labels.fleets.missions.activeTab") }}
        </Btn>
        <Btn
          :active="showArchived"
          size="small"
          inline
          @click="showArchived = true"
        >
          {{ t("labels.fleets.missions.archivedTab") }}
        </Btn>
      </BtnGroup>
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
