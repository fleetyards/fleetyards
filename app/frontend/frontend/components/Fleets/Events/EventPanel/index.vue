<script lang="ts">
export default {
  name: "FleetEventsPanel",
};
</script>

<script lang="ts" setup>
import Panel from "@/shared/components/base/Panel/index.vue";
import PanelHeading from "@/shared/components/base/Panel/Heading/index.vue";
import PanelBody from "@/shared/components/base/Panel/Body/index.vue";
import {
  PanelShadowsEnum,
  PanelBgRoundedEnum,
} from "@/shared/components/base/Panel/types";
import { HeadingLevelEnum } from "@/shared/components/base/Heading/types";
import EventStatusBadge from "@/frontend/components/Fleets/Events/EventStatusBadge/index.vue";
import { type Fleet, type FleetEvent } from "@/services/fyApi";
import { useI18n } from "@/shared/composables/useI18n";
import { useMissionCover } from "@/frontend/composables/useMissionCover";
import { format, parseISO } from "date-fns";

type Props = {
  fleet: Fleet;
  event: FleetEvent;
};

const props = defineProps<Props>();

const { t } = useI18n();
const { resolve } = useMissionCover();
const cover = computed(() => resolve(props.event));

const startDate = computed(() => {
  try {
    return format(parseISO(props.event.startsAt), "MMM d, yyyy · HH:mm");
  } catch {
    return props.event.startsAt;
  }
});
</script>

<template>
  <Panel
    :shadow="PanelShadowsEnum.TOP"
    :bg-image="cover"
    :bg-rounded="PanelBgRoundedEnum.TOP"
    class="event-panel"
  >
    <PanelHeading :level="HeadingLevelEnum.H2">
      <template #default>
        <router-link
          :to="{
            name: 'fleet-event',
            params: { slug: fleet.slug, event: event.slug },
          }"
        >
          {{ event.title }}
        </router-link>
      </template>
      <template #subtitle>
        <EventStatusBadge :status="event.status" />
      </template>
    </PanelHeading>
    <PanelBody>
      <p v-if="event.description" class="event-desc text-muted">
        {{ event.description }}
      </p>
      <ul class="event-stats">
        <li>
          <i class="fa-light fa-calendar" />
          <span>{{ startDate }}</span>
        </li>
        <li v-if="event.location">
          <i class="fa-light fa-location-dot" />
          <span>{{ event.location }}</span>
        </li>
        <li v-if="event.meetupLocation">
          <i class="fa-light fa-flag" />
          <span>{{ event.meetupLocation }}</span>
        </li>
        <li>
          <i class="fa-light fa-users" />
          <span>{{
            t("labels.fleets.events.signupsCount", {
              count: event.signupsCount,
            })
          }}</span>
        </li>
      </ul>
    </PanelBody>
  </Panel>
</template>

<style lang="scss" scoped>
$eventImageHeight: 200px;

.event-panel :deep(.panel-bg) {
  height: $eventImageHeight;
  bottom: auto;
}
.event-panel :deep(.panel-inner) {
  padding-top: $eventImageHeight;
  position: relative;
}
.event-panel :deep(.panel-heading) {
  position: absolute;
  top: 0;
  left: 0;
  right: 0;
  height: auto;
  z-index: 1;
}
.event-panel :deep(.panel-body) {
  position: relative;
}
.event-desc {
  margin: 0 0 0.5rem;
  font-size: 0.9rem;
}
.event-stats {
  display: flex;
  flex-direction: column;
  gap: 0.35rem;
  list-style: none;
  padding: 0;
  margin: 0;
  font-size: 0.85rem;
  color: var(--text-muted);

  li {
    display: flex;
    align-items: center;
    gap: 0.5rem;
  }

  i {
    width: 1rem;
    text-align: center;
  }
}
</style>
