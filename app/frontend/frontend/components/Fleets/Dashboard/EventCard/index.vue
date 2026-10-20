<script lang="ts">
export default {
  name: "FleetDashboardEventCard",
};
</script>

<script lang="ts" setup>
import Pill from "@/shared/components/base/Pill/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import { useMissionCover } from "@/frontend/composables/useMissionCover";
import { useEventStatus } from "@/frontend/composables/useEventStatus";
import { coverStyle } from "@/frontend/components/Fleets/Dashboard/coverStyle";
import type { Fleet, FleetEvent, GameEvent } from "@/services/fyApi";

// A fleet event links to its page; a game event links out to wherever the team
// pointed it, or nowhere. Both take the same card so an agenda that mixes them
// reads as one list.
type Props = {
  fleet?: Pick<Fleet, "slug">;
  event: FleetEvent | GameEvent;
};

const props = withDefaults(defineProps<Props>(), {
  fleet: undefined,
});

const fleetEvent = computed(() =>
  props.fleet && "slug" in props.event
    ? (props.event as FleetEvent)
    : undefined,
);

const externalUrl = computed(() =>
  "url" in props.event ? props.event.url : undefined,
);

const { t, l } = useI18n();

const { resolve: resolveCover } = useMissionCover();

const link = computed(() => {
  if (!props.fleet || !fleetEvent.value) return undefined;

  return {
    name: "fleet-event",
    params: {
      slug: props.fleet.slug,
      event: fleetEvent.value.parentEventSlug || fleetEvent.value.slug,
    },
    query: fleetEvent.value.occurrenceDate
      ? { occurrence: fleetEvent.value.occurrenceDate }
      : undefined,
  };
});

const tag = computed(() => {
  if (link.value) return "router-link";
  if (externalUrl.value) return "a";

  return "div";
});

const linkAttrs = computed(() => {
  if (link.value) return { to: link.value };
  if (externalUrl.value) {
    return { href: externalUrl.value, target: "_blank", rel: "noopener" };
  }

  return {};
});

const cover = computed(() => coverStyle(resolveCover(props.event)));

const { signupPillVariantFor } = useEventStatus();
</script>

<template>
  <!-- The whole card is the link, so the sign-up hint inside it is a label
       rather than a second link nested in the first. -->
  <component :is="tag" v-bind="linkAttrs" class="event-card" :style="cover">
    <div class="event-card__date" aria-hidden="true">
      <span class="event-card__weekday">
        {{ l(event.startsAt, "fleetDashboard.formats.weekday") }}
      </span>
      <span class="event-card__day">
        {{ l(event.startsAt, "fleetDashboard.formats.day") }}
      </span>
    </div>
    <div class="event-card__text">
      <span class="event-card__title">{{ event.title }}</span>
      <span class="event-card__meta">
        <time :datetime="event.startsAt">
          {{ l(event.startsAt, "datetime.formats.short") }}
        </time>
        <template v-if="event.location"> · {{ event.location }}</template>
      </span>
    </div>
    <slot name="badge">
      <Pill
        v-if="fleetEvent?.viewerSignup"
        :variant="signupPillVariantFor(fleetEvent.viewerSignup.status)"
        data-test="fleet-dashboard-event-signup"
      >
        {{
          t(
            `labels.fleets.events.signupStatuses.${fleetEvent.viewerSignup.status}`,
          )
        }}
      </Pill>
      <span
        v-else-if="fleetEvent?.signupsOpen"
        class="event-card__signup"
        data-test="fleet-dashboard-event-signup-cta"
      >
        {{ t("fleetDashboard.events.signUp") }}
        <i class="fa-light fa-chevron-right" aria-hidden="true" />
      </span>
    </slot>
  </component>
</template>

<style lang="scss" scoped>
.event-card {
  display: flex;
  align-items: center;
  gap: 14px;
  min-width: 0;
  min-height: 64px;
  padding: 10px 14px;
  border: 1px solid var(--color-edge-soft, rgb(122 130 136 / 0.28));
  border-radius: var(--radius-control, 8px);
  background-position: center;
  background-size: cover;
  color: #fff;
  text-decoration: none;
  text-shadow: 0 1px 2px rgb(0 0 0 / 0.9);
  transition: filter 150ms ease;

  &:hover,
  &:focus-visible {
    filter: brightness(1.2);
    color: #fff;
  }
}

.event-card__date {
  display: flex;
  flex: 0 0 44px;
  flex-direction: column;
  align-items: center;
  padding: 4px 0;
  background-color: rgb(0 0 0 / 0.55);
  border: 1px solid var(--color-edge-soft, rgb(122 130 136 / 0.28));
  border-radius: var(--radius-control, 8px);
  line-height: 1.1;
}

.event-card__weekday {
  color: rgb(255 255 255 / 0.75);
  font-size: 10px;
  letter-spacing: 0.16em;
  text-transform: uppercase;
}

.event-card__day {
  color: #fff;
  font-size: 18px;
  font-weight: 600;
}

.event-card__text {
  display: flex;
  flex: 1 1 auto;
  flex-direction: column;
  gap: 2px;
  min-width: 0;
}

.event-card__title {
  overflow: hidden;
  font-weight: 600;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.event-card__meta {
  overflow: hidden;
  color: rgb(255 255 255 / 0.85);
  font-size: 13px;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.event-card__signup {
  flex: 0 0 auto;
  font-size: 13px;
  white-space: nowrap;
}

@media (prefers-reduced-motion: reduce) {
  .event-card {
    transition-duration: 1ms;
  }
}
</style>
