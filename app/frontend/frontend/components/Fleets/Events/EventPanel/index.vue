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
import Chip from "@/shared/components/base/Chip/index.vue";
import { PanelRoundedEnum } from "@/shared/components/base/Panel/types";
import { PanelHeadingShadowEnum } from "@/shared/components/base/Panel/Heading/types";
import { HeadingLevelEnum } from "@/shared/components/base/Heading/types";
import { useEventStatus } from "@/frontend/composables/useEventStatus";
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

const { toneFor, labelKeyFor } = useEventStatus();
const statusTone = computed(() =>
  toneFor(props.event.status, props.event.past),
);
const statusLabel = computed(() =>
  t(labelKeyFor(props.event.status, props.event.past)),
);

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
    :bg-image="cover"
    :bg-rounded="PanelRoundedEnum.TOP"
    :tone="statusTone"
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
      <!-- The cap already carries the lifecycle; this names it, for anyone who
           cannot read a colour and for the states that share a tone. -->
      <template #actions>
        <Chip bare>{{ statusLabel }}</Chip>
      </template>
    </PanelHeading>

    <!--
      Footer, not the default slot: Panel parents the background image to
      .panel__inner so it covers the default slot and stops there. Anything that
      belongs *below* the cover rather than on it goes here.
    -->
    <template #footer>
      <PanelBody>
        <p v-if="event.description" class="event-panel__lede">
          {{ event.description }}
        </p>
        <div class="metrics-card__rows">
          <div class="metrics-card__row">
            <div class="metrics-card__row__label">
              {{ t("labels.fleets.events.startsAt") }}
            </div>
            <div class="metrics-card__row__value">{{ startDate }}</div>
          </div>
          <div v-if="event.recurring" class="metrics-card__row">
            <div class="metrics-card__row__label">
              {{ t("labels.fleets.events.repeats") }}
            </div>
            <div class="metrics-card__row__value">{{ recurringLabel }}</div>
          </div>
          <div v-if="event.location" class="metrics-card__row">
            <div class="metrics-card__row__label">
              {{ t("labels.fleets.events.location") }}
            </div>
            <div class="metrics-card__row__value">{{ event.location }}</div>
          </div>
          <div v-if="event.meetupLocation" class="metrics-card__row">
            <div class="metrics-card__row__label">
              {{ t("labels.fleets.events.meetupLocation") }}
            </div>
            <div class="metrics-card__row__value">
              {{ event.meetupLocation }}
            </div>
          </div>
          <div class="metrics-card__row">
            <div class="metrics-card__row__label">
              {{ t("labels.fleets.events.signups") }}
            </div>
            <div class="metrics-card__row__value">
              {{ event.signupsCount }}
            </div>
          </div>
        </div>
        <div v-if="canManage && event.archived" class="event-panel__actions">
          <Btn :loading="unarchiveMutation.isPending.value" @click="unarchive">
            <i class="fa-light fa-box-open" />
            {{ t("actions.fleets.events.unarchive") }}
          </Btn>
        </div>
      </PanelBody>
    </template>
  </Panel>
</template>

<style lang="scss" scoped>
@import "@/shared/components/metricsCard";

/*
 * The cover height, and the whole of what used to be five :deep() rules into
 * Panel's internals. Panel exposes this so a consumer never has to reach in;
 * two of the selectors it replaces no longer matched anything anyway, since the
 * redesign collapsed .panel-inner into .panel__inner.
 */
.event-panel {
  --panel-image-height: 200px;
}

.event-panel__lede {
  margin: 0 0 12px;
  font-size: 14px;
  color: var(--color-muted, #7a8288);
}

.event-panel__actions {
  display: flex;
  flex-wrap: wrap;
  gap: 10px;
  margin-top: 14px;
}
</style>
