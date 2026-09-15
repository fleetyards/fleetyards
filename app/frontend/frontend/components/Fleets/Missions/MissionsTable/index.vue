<script lang="ts">
export default {
  name: "FleetMissionsTable",
};
</script>

<script lang="ts" setup>
import BaseTable from "@/shared/components/base/Table/index.vue";
import type { BaseTableCol } from "@/shared/components/base/Table/types";
import { BaseTableColAlignmentEnum } from "@/shared/components/base/Table/types";
import Pill from "@/shared/components/base/Pill/index.vue";
import { PillVariantsEnum } from "@/shared/components/base/Pill/types";
import { type AsyncStatus } from "@/shared/components/AsyncData.types";
import { type Fleet, type Mission } from "@/services/fyApi";
import { useI18n } from "@/shared/composables/useI18n";
import { useMissionCover } from "@/frontend/composables/useMissionCover";
import { useRouter } from "vue-router";

type Props = {
  fleet: Fleet;
  missions: Mission[];
  asyncStatus?: AsyncStatus;
  // Drawn as a row inside the table's own frame, rather than as a panel under
  // an empty header. Same split the contracts board uses.
  emptyVisible?: boolean;
};

const props = defineProps<Props>();

const { t, l } = useI18n();
const { resolve } = useMissionCover();
const router = useRouter();

const columns = computed<BaseTableCol<Mission>[]>(() => [
  {
    name: "cover",
    label: "",
    width: "68px",
    skeletonMedia: "38px",
  },
  {
    name: "mission",
    label: t("headlines.fleets.missions.index"),
    flexGrow: 2,
    minWidth: "200px",
  },
  {
    name: "category",
    label: t("labels.fleets.missions.category"),
    flexGrow: 1,
    minWidth: "140px",
    mobile: false,
  },
  {
    name: "teamCount",
    label: t("labels.fleets.missions.teams"),
    width: "90px",
    alignment: BaseTableColAlignmentEnum.RIGHT,
  },
  {
    name: "shipCount",
    label: t("labels.fleets.missions.ships"),
    width: "90px",
    alignment: BaseTableColAlignmentEnum.RIGHT,
  },
  {
    name: "createdAt",
    // Wide enough for the date, the clock time and the zone together. The
    // column is not narrowed by dropping half the timestamp: a stored time is
    // shown, and the column is given the room it needs to show it.
    label: t("labels.createdAt"),
    width: "195px",
    mobile: false,
  },
]);

const cover = (mission: Mission) => resolve(mission);

const openMission = (mission: Mission) => {
  void router.push({
    name: "fleet-mission",
    params: { slug: props.fleet.slug, mission: mission.slug },
  });
};
</script>

<template>
  <BaseTable
    :records="missions"
    :columns="columns"
    primary-key="id"
    :async-status="asyncStatus"
    :empty-visible="emptyVisible"
    row-clickable
    data-test="missions-table"
    @row-click="openMission($event as Mission)"
  >
    <!-- The cover survives as a thumbnail, so a mission is still recognisable
         by the picture the card showed. -->
    <template #col-cover="{ record }">
      <span class="missions-table__cover">
        <img :src="cover(record as Mission)" alt="" />
      </span>
    </template>

    <template #col-mission="{ record }">
      <span class="missions-table__mission">
        <span class="missions-table__title-line">
          <span class="missions-table__title">
            {{ (record as Mission).title }}
          </span>
          <Pill
            v-if="(record as Mission).archived"
            :variant="PillVariantsEnum.NEUTRAL"
          >
            {{ t("labels.fleets.missions.archived") }}
          </Pill>
        </span>
        <span
          v-if="(record as Mission).description"
          class="missions-table__lede"
        >
          {{ (record as Mission).description }}
        </span>
      </span>
    </template>

    <template #col-category="{ record }">
      <span class="missions-table__category">
        {{
          t(`labels.fleets.missions.categories.${(record as Mission).category}`)
        }}
      </span>
    </template>

    <template #col-teamCount="{ record }">
      <span class="missions-table__count">
        {{ (record as Mission).teamCount }}
      </span>
    </template>

    <template #col-shipCount="{ record }">
      <span class="missions-table__count">
        {{ (record as Mission).shipCount }}
      </span>
    </template>

    <template #col-createdAt="{ record }">
      <span class="missions-table__created">
        {{ l((record as Mission).createdAt, "datetime.formats.dateTimeZone") }}
      </span>
    </template>
  </BaseTable>
</template>

<style lang="scss" scoped>
@import "index";
</style>
