<script lang="ts">
export default {
  name: "FleetSquadronOverviewPage",
};
</script>

<script lang="ts" setup>
import type { RouteLocationRaw } from "vue-router";
import Markdown from "@/shared/components/Markdown/index.vue";
import Panel from "@/shared/components/base/Panel/index.vue";
import PanelBody from "@/shared/components/base/Panel/Body/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import { type Fleet, type FleetSquadron } from "@/services/fyApi";

type Props = {
  fleet: Fleet;
  squadron: FleetSquadron;
};

const props = defineProps<Props>();
const { t } = useI18n();

type Figure = {
  key: string;
  value: number;
  label: string;
  to: RouteLocationRaw;
};

const figures = computed<Figure[]>(() => {
  const params = { slug: props.fleet.slug, squadron: props.squadron.slug };

  return [
    {
      key: "members",
      value: props.squadron.memberCount,
      label: t("labels.fleet.squadrons.figures.members"),
      to: { name: "fleet-squadron-members", params },
    },
    {
      key: "ships",
      value: props.squadron.shipCount ?? 0,
      label: t("labels.fleet.squadrons.figures.ships"),
      to: {
        name: "fleet-ships",
        params: { slug: props.fleet.slug },
        query: { squadronSlugIn: [props.squadron.slug] },
      },
    },
    // Only once the squadron has a flight.
    ...(!props.squadron.flightCount
      ? []
      : [
          {
            key: "flights",
            value: props.squadron.flightCount,
            label: t("labels.fleet.squadrons.figures.flights"),
            to: { name: "fleet-squadron-flights", params },
          },
        ]),
  ];
});

const hasText = computed(
  () => !!props.squadron.shortDescription || !!props.squadron.description,
);
</script>

<template>
  <Panel fill-height>
    <ul class="squadron-figures">
      <li
        v-for="figure in figures"
        :key="figure.key"
        :data-test="`squadron-figure-${figure.key}`"
      >
        <router-link :to="figure.to" class="squadron-figure">
          <span class="squadron-figure__value">{{ figure.value }}</span>
          <span class="squadron-figure__label">{{ figure.label }}</span>
        </router-link>
      </li>
    </ul>
    <PanelBody
      class="squadron-description-body"
      :class="{
        'squadron-description-body--empty': !hasText,
      }"
    >
      <!-- Written in a textarea, so the lines somebody typed are the lines
           drawn. -->
      <p
        v-if="props.squadron.shortDescription"
        class="squadron-short-description"
        data-test="squadron-short-description"
      >
        {{ props.squadron.shortDescription }}
      </p>
      <Markdown
        v-if="props.squadron.description"
        class="squadron-description"
        :source="props.squadron.description"
      />
      <p v-else-if="!hasText" class="squadron-description-placeholder">
        {{ t("labels.fleet.squadrons.noDescription") }}
      </p>
    </PanelBody>
  </Panel>
</template>

<style lang="scss" scoped>
.squadron-figures {
  display: flex;
  flex-wrap: wrap;
  gap: 8px 32px;
  margin: 0;
  padding: 16px 18px;
  border-bottom: 1px solid var(--color-edge-faint);
  list-style: none;
}

.squadron-figure {
  display: flex;
  align-items: baseline;
  gap: 6px;
  color: inherit;
  text-decoration: none;

  &:hover .squadron-figure__label,
  &:focus-visible .squadron-figure__label {
    color: var(--color-text);
  }
}

.squadron-figure__value {
  font-size: 1.5rem;
  line-height: 1;
}

.squadron-figure__label {
  color: var(--color-text-dim);
  font-size: 0.875rem;
}

.squadron-short-description {
  margin: 0 0 16px;
  font-size: 1.0625rem;
  white-space: pre-line;

  &:last-child {
    margin-bottom: 0;
  }
}

.squadron-description-body {
  padding: 18px;
}

.squadron-description {
  margin: 0;
}

.squadron-description-placeholder {
  margin: 0;
  color: var(--color-text-muted, #8a8f95);
  font-style: italic;
}

.squadron-description-body--empty {
  display: flex;
  align-items: center;
  justify-content: center;
  min-height: 180px;
  text-align: center;
}
</style>
