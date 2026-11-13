<script lang="ts">
export default {
  name: "FleetSquadronFlightSummary",
};
</script>

<script lang="ts" setup>
import type { RouteLocationRaw } from "vue-router";
import Panel from "@/shared/components/base/Panel/index.vue";
import PanelHeading from "@/shared/components/base/Panel/Heading/index.vue";
import PanelBody from "@/shared/components/base/Panel/Body/index.vue";
import { HeadingLevelEnum } from "@/shared/components/base/Heading/types";
import { PanelVariantsEnum } from "@/shared/components/base/Panel/types";
import { useI18n } from "@/shared/composables/useI18n";
import type { FleetSquadronFlight } from "@/services/fyApi";

type Props = {
  flight: FleetSquadronFlight;
  to: RouteLocationRaw;
};

const props = defineProps<Props>();

const { t } = useI18n();

const slotCount = computed(
  () =>
    props.flight.slots.length +
    props.flight.ships.reduce(
      (sum, ship) => sum + (ship.slots?.length ?? 0),
      0,
    ),
);

// An uploaded cover fills the frame; a ship render is cut out on transparency,
// so it is fitted inside the frame instead. Only an upload the server could
// represent has a largeUrl, so anything that is not an image falls through.
const cover = computed(() => {
  const upload = props.flight.coverImage?.largeUrl;
  if (upload) return { url: upload, render: false };

  const render = props.flight.ships
    .map((ship) => {
      const model = ship.model ?? ship.allowedModels?.[0];
      return model?.angledView?.mediumUrl || model?.image?.mediumUrl;
    })
    .find(Boolean);

  return render ? { url: render, render: true } : undefined;
});

const counts = computed(() => [
  {
    value: props.flight.ships.length,
    label: t("headlines.fleets.missions.ships"),
  },
  { value: slotCount.value, label: t("headlines.fleets.missions.slots") },
]);
</script>

<template>
  <Panel
    :variant="PanelVariantsEnum.SLIM"
    class="flight-summary"
    :data-test="`flight-summary-${flight.id}`"
    fill-height
  >
    <router-link
      v-if="cover"
      :to="to"
      class="flight-summary__cover"
      :class="{ 'flight-summary__cover--render': cover.render }"
      tabindex="-1"
      aria-hidden="true"
      data-test="flight-summary-cover"
    >
      <img :src="cover.url" alt="" loading="lazy" />
    </router-link>
    <PanelHeading compact divider :level="HeadingLevelEnum.H3">
      <template #default>
        <router-link :to="to">{{ flight.name }}</router-link>
      </template>
    </PanelHeading>
    <PanelBody class="flight-summary__body" rounded="bottom">
      <p
        v-if="flight.shortDescription"
        class="flight-summary__description"
        data-test="flight-summary-description"
      >
        {{ flight.shortDescription }}
      </p>
      <div class="flight-summary__counts">
        <div
          v-for="count in counts"
          :key="count.label"
          class="flight-summary__count"
        >
          <span class="flight-summary__count-number">{{ count.value }}</span>
          <span class="flight-summary__count-label">{{ count.label }}</span>
        </div>
      </div>
    </PanelBody>
  </Panel>
</template>

<style lang="scss" scoped>
.flight-summary__cover {
  display: block;
  overflow: hidden;
  height: 140px;
  border-radius: var(--radius-surface-slim) var(--radius-surface-slim) 0 0;
}

.flight-summary__cover img {
  width: 100%;
  height: 100%;
  object-fit: cover;
}

.flight-summary__cover--render {
  padding: 12px 20px 4px;
  background: radial-gradient(
    ellipse at 50% 70%,
    rgb(66 139 202 / 0.12),
    transparent 70%
  );
}

.flight-summary__cover--render img {
  object-fit: contain;
  filter: drop-shadow(0 10px 14px rgb(0 0 0 / 0.7));
}

.flight-summary__body {
  display: flex;
  flex: 1;
  flex-direction: column;
  gap: 12px;
  padding: 14px 16px;
}

.flight-summary__description {
  display: -webkit-box;
  overflow: hidden;
  margin: 0;
  color: var(--color-text-dim);
  font-size: 0.875rem;
  white-space: pre-line;
  -webkit-box-orient: vertical;
  -webkit-line-clamp: 3;
}

.flight-summary__counts {
  display: flex;
  align-items: center;
  gap: 24px;
  margin-top: auto;
}

.flight-summary__count {
  display: flex;
  align-items: baseline;
  gap: 6px;
}

.flight-summary__count-number {
  font-size: 1.5em;
  line-height: 1;
}

.flight-summary__count-label {
  color: var(--color-text-dim);
  font-size: 0.85em;
}
</style>
