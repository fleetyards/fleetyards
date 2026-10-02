<script lang="ts">
export default {
  name: "LocationPage",
};
</script>

<script lang="ts" setup>
import AsyncData from "@/shared/components/AsyncData.vue";
import Heading from "@/shared/components/base/Heading/index.vue";
import BodyColumns from "@/frontend/components/Locations/BodyColumns/index.vue";
import ContentsList from "@/frontend/components/Locations/Contents/index.vue";
import KindCounts from "@/frontend/components/Locations/KindCounts/index.vue";
import StarmapFacts from "@/frontend/components/Locations/StarmapFacts/index.vue";
import SystemStrip from "@/frontend/components/Locations/SystemStrip/index.vue";
import MissionsList from "@/frontend/components/Missions/List/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import { useMetaInfo } from "@/shared/composables/useMetaInfo";
import {
  LocationKindEnum,
  type LocationTreeNode,
  useGameMissions,
  useLocation,
  useLocationContents,
  useLocationTree,
} from "@/services/fyApi";

const { t } = useI18n();
const { updateMetaInfo } = useMetaInfo();
const route = useRoute();

const slug = computed(() => route.params.slug as string);

const { data: location, ...asyncStatus } = useLocation(slug);

const locationId = computed(() => location.value?.id);
const loaded = computed(() => !!locationId.value);

// The system the place is in, as its bodies: drawn at the top of every page
// so a reader always sees where they are.
const { data: tree } = useLocationTree(slug, { query: { enabled: loaded } });

// A system or its star reads as the whole system laid out; anything else as
// the place, with the strip shrunk to a header above it.
const isSystemView = computed(
  () =>
    location.value?.kind === LocationKindEnum.SYSTEM ||
    location.value?.kind === LocationKindEnum.STAR,
);

const star = computed(() =>
  tree.value?.children.find((node) => node.location.kind === "star"),
);

const bodies = computed(
  () => star.value?.children ?? tree.value?.children ?? [],
);

// The node the strip draws for this place, when it draws one: a planet's moons
// are laid out as columns on its page, the way the system page lays out its
// planets.
const findNode = (
  nodes: LocationTreeNode[],
  id?: string,
): LocationTreeNode | undefined => {
  for (const node of nodes) {
    if (node.location.id === id) return node;

    const found = findNode(node.children, id);
    if (found) return found;
  }

  return undefined;
};

const ownNode = computed(() =>
  tree.value ? findNode([tree.value], locationId.value) : undefined,
);

const moonColumns = computed(() =>
  (ownNode.value?.children ?? []).filter(
    (child) => child.location.kind === LocationKindEnum.MOON,
  ),
);

// The ancestors the strip already shows -- system, star, planet, moon, a
// city on them -- would only repeat it. A place deeper than that names the
// ones it cannot: the clinic inside Everus Harbor says Everus Harbor.
const STRIP_KINDS: string[] = [
  LocationKindEnum.SYSTEM,
  LocationKindEnum.STAR,
  LocationKindEnum.PLANET,
  LocationKindEnum.MOON,
  LocationKindEnum.CITY,
];

const unseenAncestors = computed(() =>
  (location.value?.ancestors ?? []).filter(
    (ancestor) => !STRIP_KINDS.includes(ancestor.kind),
  ),
);

const contentGroups = computed(() =>
  (contents.value?.groups ?? []).filter(
    (group) =>
      !moonColumns.value.length || group.kind !== LocationKindEnum.MOON,
  ),
);

const path = computed(() => [
  ...(location.value?.ancestors ?? []).map((ancestor) => ancestor.id),
  ...(locationId.value ? [locationId.value] : []),
]);

const { data: contents } = useLocationContents(slug, {
  query: {
    enabled: computed(
      () =>
        loaded.value && !isSystemView.value && !!location.value?.childrenCount,
    ),
  },
});

// A handful on the page; the mission list, filtered to here, has the rest.
const MISSIONS_PER_PAGE = 5;

const { data: missions } = useGameMissions(
  computed(() => ({
    perPage: String(MISSIONS_PER_PAGE),
    q: { atLocation: locationId.value },
  })),
  { query: { enabled: computed(() => loaded.value && !isSystemView.value) } },
);

// The export writes line breaks as a literal `\n`.
const description = computed(() =>
  location.value?.description?.replaceAll("\\n", "\n"),
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
        <SystemStrip
          v-if="tree"
          :tree="tree"
          :path="path"
          :map-parent="location.mapParent"
          :compact="!isSystemView"
        />

        <div class="location-page__masthead">
          <div class="location-page__title">
            <p v-if="unseenAncestors.length" class="location-page__within">
              {{ t("labels.location.within") }}
              <template
                v-for="(ancestor, index) in unseenAncestors"
                :key="ancestor.id"
              >
                <span v-if="index > 0" aria-hidden="true">›</span>
                <router-link
                  :to="{ name: 'location', params: { slug: ancestor.slug } }"
                >
                  {{ ancestor.name }}
                </router-link>
              </template>
            </p>

            <Heading hero>{{ location.name }}</Heading>
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

            <span v-if="location.childrenCount" class="location-page__badge">
              <span class="location-page__badge-label">
                {{ t("labels.location.inside") }}
              </span>
              <span class="location-page__badge-value">
                {{ location.childrenCount }}
              </span>
            </span>
          </div>
        </div>

        <template v-if="isSystemView">
          <section v-if="description" class="location-page__panel">
            <p class="location-page__description">{{ description }}</p>
          </section>

          <BodyColumns :bodies="bodies" />

          <section v-if="star?.counts.length" class="location-page__panel">
            <h2 class="location-page__panel-title">
              {{ t("labels.location.elsewhere", { star: star.location.name }) }}
            </h2>
            <KindCounts :counts="star.counts" />
          </section>
        </template>

        <div v-else class="location-page__layout">
          <div class="location-page__main">
            <BodyColumns
              v-if="moonColumns.length"
              :bodies="moonColumns"
              :counts-label="t('labels.location.places')"
            />

            <ContentsList
              v-if="contentGroups.length"
              :groups="contentGroups"
              :parent-id="location.id"
            />

            <section
              v-if="missions?.items?.length"
              class="location-page__panel"
            >
              <h2 class="location-page__panel-title">
                {{ t("labels.location.missions") }} ·
                {{ missions.meta.pagination?.totalCount }}
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
          </div>

          <aside class="location-page__aside">
            <section v-if="description" class="location-page__panel">
              <p class="location-page__description">{{ description }}</p>
            </section>

            <section class="location-page__panel">
              <h2 class="location-page__panel-title">
                {{ t("labels.location.starmap") }}
              </h2>

              <StarmapFacts :location="location" />
            </section>

            <section
              v-if="location.terminals?.length"
              class="location-page__panel"
            >
              <h2 class="location-page__panel-title">
                {{ t("labels.location.terminals") }}
              </h2>

              <ul class="location-page__terminals">
                <li v-for="terminal in location.terminals" :key="terminal.id">
                  {{ terminal.name }}
                </li>
              </ul>
            </section>
          </aside>
        </div>
      </div>
    </template>
  </AsyncData>
</template>

<style lang="scss" scoped>
@import "index";
</style>
