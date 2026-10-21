<script lang="ts">
export default {
  name: "HomeLandingGameEvents",
};
</script>

<script lang="ts" setup>
import Heading from "@/shared/components/base/Heading/index.vue";
import { HeadingLevelEnum } from "@/shared/components/base/Heading/types";
import EventCard from "@/frontend/components/Fleets/Dashboard/EventCard/index.vue";
import { useGameEvents } from "@/services/fyApi";
import { useI18n } from "@/shared/composables/useI18n";

const { t } = useI18n();

const { data } = useGameEvents({ perPage: "6" });

const gameEvents = computed(() => data.value?.items || []);
</script>

<template>
  <!-- Curated, so a quiet week simply has no section rather than an empty one. -->
  <Transition name="fade-quick" appear>
    <section v-if="gameEvents.length" data-test="home-landing-game-events">
      <Heading :level="HeadingLevelEnum.H2" hero>
        {{ t("home.landing.gameEvents.title") }}
      </Heading>
      <p class="home-landing-game-events__subline">
        {{ t("home.landing.gameEvents.subline") }}
      </p>
      <div class="home-landing-game-events">
        <EventCard
          v-for="gameEvent in gameEvents"
          :key="gameEvent.id"
          :event="gameEvent"
        />
      </div>
    </section>
  </Transition>
</template>

<style lang="scss" scoped>
.home-landing-game-events {
  display: grid;
  grid-template-columns: repeat(3, minmax(0, 1fr));
  gap: 12px;
}

.home-landing-game-events__subline {
  margin: 0 0 12px;
  color: var(--color-text-dim, #959595);
}

@media (max-width: 991px) {
  .home-landing-game-events {
    grid-template-columns: minmax(0, 1fr);
  }
}
</style>
