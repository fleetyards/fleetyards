<script lang="ts">
export default {
  name: "EventStatsCard",
};
</script>

<script lang="ts" setup>
import { type RouteLocationRaw } from "vue-router";
import StatsCard from "@/frontend/components/StatsCard/index.vue";
import {
  type StatsCardBadge,
  type StatsCardStatus,
  type StatsCardStatusTone,
} from "@/frontend/components/StatsCard/types";
import { useEventStatus } from "@/frontend/composables/useEventStatus";
import { PillVariantsEnum } from "@/shared/components/base/Pill/types";
import { useI18n } from "@/shared/composables/useI18n";
import { type FleetEvent } from "@/services/fyApi";

type Props = {
  event?: FleetEvent;
  name?: string;
  to?: RouteLocationRaw | false;
  loading?: boolean;
};

const props = withDefaults(defineProps<Props>(), {
  event: undefined,
  name: undefined,
  to: undefined,
  loading: false,
});

const emit = defineEmits<{ navigate: [] }>();

const { t, l } = useI18n();

const { labelKeyFor, pillVariantFor } = useEventStatus();

// The event board's pill, in the card's narrower palette.
const TONES: Partial<Record<string, StatsCardStatusTone>> = {
  [PillVariantsEnum.SUCCESS]: "success",
  [PillVariantsEnum.WARNING]: "warning",
  [PillVariantsEnum.DANGER]: "danger",
};

const status = computed<StatsCardStatus | undefined>(() => {
  const event = props.event;
  if (!event) return undefined;

  return {
    label: t(labelKeyFor(event.status, event.past)),
    tone: TONES[pillVariantFor(event.status, event.past)] ?? "neutral",
  };
});

const category = computed(() =>
  props.event?.category
    ? t(`labels.fleets.missions.categories.${props.event.category}`)
    : undefined,
);

const subtitle = computed(() =>
  props.event
    ? l(props.event.startsAt, "datetime.formats.dateTimeZone")
    : undefined,
);

const badges = computed<StatsCardBadge[]>(() =>
  props.event?.location
    ? [
        {
          key: "location",
          label: t("labels.fleets.events.location"),
          value: props.event.location,
        },
      ]
    : [],
);
</script>

<template>
  <StatsCard
    compact
    :title="event?.title || name || ''"
    kind="FleetEvent"
    :category="category"
    :subtitle="subtitle"
    :status="status"
    :badges="badges"
    :to="to === false ? undefined : to"
    :loading="loading"
    :unavailable="!loading && !event"
    @navigate="emit('navigate')"
  />
</template>
