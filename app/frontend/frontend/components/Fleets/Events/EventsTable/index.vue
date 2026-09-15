<script lang="ts">
export default {
  name: "FleetEventsTable",
};
</script>

<script lang="ts" setup>
import BaseTable from "@/shared/components/base/Table/index.vue";
import type { BaseTableCol } from "@/shared/components/base/Table/types";
import { BaseTableColAlignmentEnum } from "@/shared/components/base/Table/types";
import Pill from "@/shared/components/base/Pill/index.vue";
import { type AsyncStatus } from "@/shared/components/AsyncData.types";
import { type Fleet, type FleetEvent } from "@/services/fyApi";
import { useI18n } from "@/shared/composables/useI18n";
import { useEventStatus } from "@/frontend/composables/useEventStatus";
import { useMissionCover } from "@/frontend/composables/useMissionCover";
import { useRouter } from "vue-router";

type Props = {
  fleet: Fleet;
  events: FleetEvent[];
  asyncStatus?: AsyncStatus;
  // Drawn as a row inside the table's own frame, rather than as a panel under
  // an empty header. Same split the contracts board uses.
  emptyVisible?: boolean;
};

const props = defineProps<Props>();

const { t, l } = useI18n();
const { resolve } = useMissionCover();
const { labelKeyFor, pillVariantFor } = useEventStatus();
const router = useRouter();

const columns = computed<BaseTableCol<FleetEvent>[]>(() => [
  {
    name: "cover",
    label: "",
    width: "68px",
    skeletonMedia: "38px",
  },
  {
    name: "event",
    label: t("headlines.fleets.events.index"),
    flexGrow: 2,
    minWidth: "200px",
  },
  {
    name: "startsAt",
    // Wide enough for the date, the clock time and the zone together - when an
    // event starts is the one figure somebody reads this list for, and a
    // timezone is not optional on it.
    label: t("labels.fleets.events.startsAt"),
    width: "195px",
  },
  {
    name: "location",
    label: t("labels.fleets.events.location"),
    flexGrow: 1,
    minWidth: "140px",
    mobile: false,
  },
  {
    name: "signupsCount",
    label: t("labels.fleets.events.signups"),
    width: "100px",
    alignment: BaseTableColAlignmentEnum.RIGHT,
  },
  {
    name: "teamCount",
    // The events namespace has no word for this and the missions one does;
    // the event form already borrows that namespace for its categories.
    label: t("labels.fleets.missions.teams"),
    width: "90px",
    alignment: BaseTableColAlignmentEnum.RIGHT,
    mobile: false,
  },
]);

const cover = (event: FleetEvent) => resolve(event);

// A signup count means something different against a cap: four of six is a
// different reading from four.
const signups = (event: FleetEvent) =>
  event.maxAttendees
    ? `${event.signupsCount} / ${event.maxAttendees}`
    : `${event.signupsCount}`;

const openEvent = (event: FleetEvent) => {
  void router.push({
    name: "fleet-event",
    params: { slug: props.fleet.slug, event: event.slug },
  });
};
</script>

<template>
  <BaseTable
    :records="events"
    :columns="columns"
    primary-key="id"
    :async-status="asyncStatus"
    :empty-visible="emptyVisible"
    row-clickable
    data-test="events-table"
    @row-click="openEvent($event as FleetEvent)"
  >
    <!-- The cover survives as a thumbnail, so an event is still recognisable
         by the picture the card showed. -->
    <template #col-cover="{ record }">
      <span class="events-table__cover">
        <img :src="cover(record as FleetEvent)" alt="" />
      </span>
    </template>

    <template #col-event="{ record }">
      <span class="events-table__event">
        <span class="events-table__title-line">
          <span class="events-table__title">
            {{ (record as FleetEvent).title }}
          </span>
          <Pill
            :variant="
              pillVariantFor(
                (record as FleetEvent).status,
                (record as FleetEvent).past,
              )
            "
            data-test="event-status"
          >
            {{
              t(
                labelKeyFor(
                  (record as FleetEvent).status,
                  (record as FleetEvent).past,
                ),
              )
            }}
          </Pill>
        </span>
        <span
          v-if="(record as FleetEvent).description"
          class="events-table__lede"
        >
          {{ (record as FleetEvent).description }}
        </span>
      </span>
    </template>

    <template #col-startsAt="{ record }">
      <span class="events-table__starts-at">
        {{
          l((record as FleetEvent).startsAt, "datetime.formats.dateTimeZone")
        }}
      </span>
    </template>

    <template #col-location="{ record }">
      <span class="events-table__location">
        {{ (record as FleetEvent).location || "—" }}
      </span>
    </template>

    <template #col-signupsCount="{ record }">
      <span class="events-table__count">
        {{ signups(record as FleetEvent) }}
      </span>
    </template>

    <template #col-teamCount="{ record }">
      <span class="events-table__count">
        {{ (record as FleetEvent).teamCount }}
      </span>
    </template>
  </BaseTable>
</template>

<style lang="scss" scoped>
@import "index";
</style>
