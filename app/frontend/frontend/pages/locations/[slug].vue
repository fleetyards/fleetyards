<script lang="ts">
export default {
  name: "LocationPage",
};
</script>

<script lang="ts" setup>
import AsyncData from "@/shared/components/AsyncData.vue";
import Heading from "@/shared/components/base/Heading/index.vue";
import LocationsList from "@/frontend/components/Locations/List/index.vue";
import StarmapFacts from "@/frontend/components/Locations/StarmapFacts/index.vue";
import MissionsList from "@/frontend/components/Missions/List/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import { useMetaInfo } from "@/shared/composables/useMetaInfo";
import { useGameMissions, useLocation, useLocations } from "@/services/fyApi";

const { t } = useI18n();
const { updateMetaInfo } = useMetaInfo();
const route = useRoute();

const slug = computed(() => route.params.slug as string);

const { data: location, ...asyncStatus } = useLocation(slug);

const locationId = computed(() => location.value?.id);

// A page's worth, with a link to the rest: the Nyx star holds 464 places.
const CHILDREN_PER_PAGE = 60;

const { data: children } = useLocations(
  computed(() => ({
    perPage: String(CHILDREN_PER_PAGE),
    q: { parentIdEq: locationId.value },
  })),
  { query: { enabled: computed(() => !!locationId.value) } },
);

const MISSIONS_PER_PAGE = 20;

const { data: missions } = useGameMissions(
  computed(() => ({
    perPage: String(MISSIONS_PER_PAGE),
    q: { atLocation: locationId.value },
  })),
  { query: { enabled: computed(() => !!locationId.value) } },
);

// The export writes line breaks as a literal `\n`.
const description = computed(() =>
  location.value?.description?.replaceAll("\\n", "\n"),
);

const moreChildren = computed(
  () => (location.value?.childrenCount ?? 0) > CHILDREN_PER_PAGE,
);

const moreMissions = computed(
  () => (missions.value?.meta?.pagination?.totalCount ?? 0) > MISSIONS_PER_PAGE,
);

watch(
  () => location.value,
  (value) => {
    if (!value) return;

    updateMetaInfo({
      title: [value.name, value.parent?.name].filter(Boolean).join(" - "),
      description: value.description ?? undefined,
    });
  },
  { immediate: true },
);
</script>

<template>
  <AsyncData :async-status="asyncStatus">
    <template #resolved>
      <div v-if="location" class="location-page">
        <div class="location-page__masthead">
          <div class="location-page__title">
            <Heading hero>{{ location.name }}</Heading>

            <nav
              v-if="location.ancestors?.length"
              class="location-page__breadcrumb"
              :aria-label="t('labels.location.breadcrumb')"
            >
              <template
                v-for="(ancestor, index) in location.ancestors"
                :key="ancestor.id"
              >
                <span v-if="index > 0" aria-hidden="true">›</span>
                <router-link
                  :to="{ name: 'location', params: { slug: ancestor.slug } }"
                >
                  {{ ancestor.name }}
                </router-link>
              </template>
            </nav>
          </div>

          <div class="location-page__badges">
            <span
              v-if="location.retired"
              class="location-page__badge location-page__badge--retired"
            >
              <span class="location-page__badge-value">
                {{ t("labels.location.retired") }}
              </span>
            </span>

            <span class="location-page__badge">
              <span class="location-page__badge-label">
                {{ t("labels.location.kind") }}
              </span>
              <span class="location-page__badge-value">
                {{ t(`labels.location.kinds.${location.kind}`) }}
              </span>
            </span>
          </div>
        </div>

        <section v-if="description" class="location-page__panel">
          <p class="location-page__description">{{ description }}</p>
        </section>

        <section class="location-page__panel">
          <h2 class="location-page__panel-title">
            {{ t("labels.location.starmap") }}
          </h2>

          <StarmapFacts :location="location" />
        </section>

        <section v-if="location.childrenCount" class="location-page__panel">
          <h2 class="location-page__panel-title">
            {{
              t("labels.location.children", { count: location.childrenCount })
            }}
          </h2>

          <LocationsList :locations="children?.items ?? []" />

          <router-link
            v-if="moreChildren"
            class="location-page__more"
            :to="{ name: 'locations', query: { parentIdEq: location.id } }"
          >
            {{
              t("labels.location.allChildren", {
                count: location.childrenCount,
              })
            }}
          </router-link>
        </section>

        <section v-if="missions?.items?.length" class="location-page__panel">
          <h2 class="location-page__panel-title">
            {{ t("labels.location.missions") }}
          </h2>

          <MissionsList :missions="missions.items" />

          <router-link
            v-if="moreMissions"
            class="location-page__more"
            :to="{ name: 'missions', query: { atLocation: location.id } }"
          >
            {{ t("labels.location.allMissions") }}
          </router-link>
        </section>

        <section v-if="location.terminals?.length" class="location-page__panel">
          <h2 class="location-page__panel-title">
            {{ t("labels.location.terminals") }}
          </h2>

          <ul class="location-page__terminals">
            <li v-for="terminal in location.terminals" :key="terminal.id">
              {{ terminal.name }}
            </li>
          </ul>
        </section>
      </div>
    </template>
  </AsyncData>
</template>

<style lang="scss" scoped>
@import "index";
</style>
