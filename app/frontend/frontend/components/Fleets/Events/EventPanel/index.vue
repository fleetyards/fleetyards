<script lang="ts">
export default {
  name: "FleetEventsPanel",
};
</script>

<script lang="ts" setup>
import Panel from "@/shared/components/base/Panel/index.vue";
import PanelHeading from "@/shared/components/base/Panel/Heading/index.vue";
import PanelBody from "@/shared/components/base/Panel/Body/index.vue";
import Btn from "@/shared/components/base/Btn/index.vue";
import { BtnSizesEnum } from "@/shared/components/base/Btn/types";
import {
  PanelShadowsEnum,
  PanelBgRoundedEnum,
} from "@/shared/components/base/Panel/types";
import { PanelHeadingShadowEnum } from "@/shared/components/base/Panel/Heading/types";
import { HeadingLevelEnum } from "@/shared/components/base/Heading/types";
import EventStatusBadge from "@/frontend/components/Fleets/Events/EventStatusBadge/index.vue";
import {
  type Fleet,
  type FleetEvent,
  useUnarchiveFleetEvent,
} from "@/services/fyApi";
import { useI18n } from "@/shared/composables/useI18n";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";
import { useComlink } from "@/shared/composables/useComlink";
import { useMissionCover } from "@/frontend/composables/useMissionCover";
import { format, parseISO } from "date-fns";

type Props = {
  fleet: Fleet;
  event: FleetEvent;
  canManage?: boolean;
};

const props = withDefaults(defineProps<Props>(), {
  canManage: false,
});

const { t } = useI18n();
const { displaySuccess, displayAlert } = useAppNotifications();
const comlink = useComlink();
const { resolve } = useMissionCover();
const cover = computed(() => resolve(props.event));

const recurringLabel = computed(() => {
  const interval = props.event.recurrenceInterval as string | undefined;
  if (!interval) return t("labels.fleets.events.recurring");
  return t(`labels.fleets.events.recurrence.${interval}`);
});

const startDate = computed(() => {
  try {
    return format(parseISO(props.event.startsAt), "MMM d, yyyy · HH:mm");
  } catch {
    return props.event.startsAt;
  }
});

const unarchiveMutation = useUnarchiveFleetEvent();

const unarchive = async () => {
  try {
    await unarchiveMutation.mutateAsync({
      fleetSlug: props.fleet.slug,
      slug: props.event.slug,
    });
    displaySuccess({ text: t("messages.fleets.event.unarchive.success") });
    comlink.emit("fleet-event-updated");
  } catch {
    displayAlert({ text: t("messages.fleets.event.unarchive.failure") });
  }
};
</script>

<template>
  <Panel
    :shadow="PanelShadowsEnum.TOP"
    :bg-image="cover"
    :bg-rounded="PanelBgRoundedEnum.TOP"
    class="event-panel"
  >
    <PanelHeading
      :level="HeadingLevelEnum.H2"
      :shadow="PanelHeadingShadowEnum.TOP"
    >
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
    </PanelHeading>
    <EventStatusBadge
      :status="event.status"
      :past="event.past"
      variant="corner"
    />
    <PanelBody>
      <p v-if="event.description" class="event-desc text-muted">
        {{ event.description }}
      </p>
      <ul class="event-stats">
        <li>
          <i class="fa-light fa-calendar" />
          <span>{{ startDate }}</span>
        </li>
        <li v-if="event.recurring">
          <i class="fa-light fa-arrows-rotate" />
          <span>{{ recurringLabel }}</span>
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
      <div v-if="canManage && event.archived" class="event-panel__actions">
        <Btn
          :size="BtnSizesEnum.SMALL"
          inline
          :loading="unarchiveMutation.isPending.value"
          @click="unarchive"
        >
          <i class="fa-light fa-box-open" />
          {{ t("actions.fleets.events.unarchive") }}
        </Btn>
      </div>
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
  min-height: 0;
}
.event-panel :deep(.panel-heading) {
  position: absolute;
  top: 0;
  left: 0;
  right: 0;
  height: $eventImageHeight;
  z-index: 1;
  pointer-events: none;
}
.event-panel :deep(.panel-heading__title) {
  pointer-events: auto;
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
.event-panel__actions {
  margin-top: 0.6rem;
  display: flex;
  gap: 0.4rem;
  flex-wrap: wrap;
}
</style>
