<script lang="ts">
export default {
  name: "FleetSquadronStrip",
};
</script>

<script lang="ts" setup>
import SquadronEmblem from "@/frontend/components/Fleets/Squadrons/SquadronEmblem/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import type {
  Fleet,
  FleetSquadron,
  PublicFleetSquadron,
} from "@/services/fyApi";

type Props = {
  fleet: Fleet;
  squadrons: (FleetSquadron | PublicFleetSquadron)[];
  // A squadron's own page is for members, so only they get links.
  linked?: boolean;
  centred?: boolean;
};

withDefaults(defineProps<Props>(), {
  linked: false,
  centred: false,
});

const { t } = useI18n();

const memberCount = (squadron: FleetSquadron | PublicFleetSquadron) =>
  "memberCount" in squadron ? squadron.memberCount : null;
</script>

<template>
  <!-- A row of links rather than a grid of cards: this introduces the fleet,
       and the squadrons page is where they are read properly. -->
  <div class="squadron-strip" :class="{ 'squadron-strip--centred': centred }">
    <template v-if="linked">
      <router-link
        v-for="squadron in squadrons"
        :key="squadron.id"
        class="squadron-strip__item"
        :to="{
          name: 'fleet-squadron',
          params: { slug: fleet.slug, squadron: squadron.slug },
        }"
        :data-test="`fleet-squadron-${squadron.slug}`"
      >
        <SquadronEmblem :squadron="squadron" :size="32" />
        <span>{{ squadron.name }}</span>
      </router-link>
    </template>
    <template v-else>
      <div
        v-for="squadron in squadrons"
        :key="squadron.id"
        class="squadron-strip__item"
        :data-test="`fleet-public-squadron-${squadron.slug}`"
      >
        <SquadronEmblem :squadron="squadron" :size="32" />
        <span>{{ squadron.name }}</span>
        <span
          v-if="memberCount(squadron) !== null"
          class="squadron-strip__count"
          data-test="fleet-public-squadron-count"
        >
          {{
            t("labels.fleet.squadrons.memberCount", {
              count: memberCount(squadron) ?? 0,
            })
          }}
        </span>
      </div>
    </template>
  </div>
</template>

<style lang="scss" scoped>
.squadron-strip {
  display: flex;
  flex-wrap: wrap;
  gap: 8px;
}

.squadron-strip--centred {
  justify-content: center;
}

.squadron-strip__item {
  display: flex;
  align-items: center;
  gap: 10px;
  padding: 8px 12px;
  background-color: var(--color-control, rgb(39 43 48 / 0.9));
  border: 1px solid var(--color-edge-soft, rgb(122 130 136 / 0.28));
  border-radius: var(--radius-control, 8px);
  color: var(--color-text, #c8c8c8);
  text-decoration: none;
  transition: background-color 150ms ease;

  &:is(a):hover,
  &:is(a):focus-visible {
    background-color: var(--color-control-hover, rgb(52 58 64 / 0.95));
    color: var(--color-text, #c8c8c8);
  }
}

.squadron-strip__count {
  color: var(--color-text-dim, #959595);
  font-size: 0.85em;
}
</style>
