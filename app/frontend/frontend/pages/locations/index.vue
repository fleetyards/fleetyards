<script lang="ts">
export default {
  name: "LocationsPage",
};
</script>

<script lang="ts" setup>
import Heading from "@/shared/components/base/Heading/index.vue";
import Btn from "@/shared/components/base/Btn/index.vue";
import SystemCard from "@/frontend/components/Locations/SystemCard/index.vue";
import SystemCardSkeleton from "@/frontend/components/Locations/SystemCard/Skeleton.vue";
import { useI18n } from "@/shared/composables/useI18n";
import { LocationKindEnum, useLocations } from "@/services/fyApi";

const { t } = useI18n();

// Every system, laid out as its bodies. The list of every place has a page of
// its own, with the filters.
const {
  data: systems,
  isLoading,
  isError,
  refetch,
} = useLocations({
  q: { kindEq: LocationKindEnum.SYSTEM },
});

// As many placeholders as there are systems to come, near enough: the game
// has four.
const PLACEHOLDERS = 4;
</script>

<template>
  <div class="locations-systems__head">
    <Heading hero>{{ t("headlines.locations.index") }}</Heading>

    <Btn :to="{ name: 'locations-places' }" data-test="locations-places-link">
      <i class="fa-light fa-list" aria-hidden="true" />
      {{ t("labels.location.allPlaces") }}
    </Btn>
  </div>

  <section
    class="locations-systems"
    :aria-label="t('labels.location.systems')"
    :aria-busy="isLoading"
  >
    <template v-if="isLoading">
      <SystemCardSkeleton v-for="index in PLACEHOLDERS" :key="index" />
    </template>

    <p v-else-if="isError" class="locations-systems__error">
      {{ t("labels.location.systemsUnavailable") }}
      <Btn @click="() => refetch()">{{ t("actions.retry") }}</Btn>
    </p>

    <SystemCard
      v-for="system in systems?.items ?? []"
      v-else
      :key="system.id"
      :system="system"
    />
  </section>
</template>

<style lang="scss" scoped>
.locations-systems {
  display: flex;
  flex-direction: column;
  gap: 16px;

  &__error {
    display: flex;
    align-items: center;
    gap: 8px;
    margin: 0;
    color: var(--color-text-dim, #959595);
  }

  &__head {
    display: flex;
    flex-wrap: wrap;
    align-items: center;
    justify-content: space-between;
    gap: 16px;
    margin-bottom: 24px;
  }
}
</style>
