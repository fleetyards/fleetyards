<script lang="ts">
export default {
  name: "LocationPage",
};
</script>

<script lang="ts" setup>
import Panel from "@/shared/components/base/Panel/index.vue";
import PanelBody from "@/shared/components/base/Panel/Body/index.vue";
import MetricsCard from "@/frontend/components/Models/MetricsCard/index.vue";
import ExternalLinks from "@/shared/components/ExternalLinks/index.vue";
import LocationShops from "@/frontend/components/Locations/Shops/index.vue";
import LocationGlobe from "@/frontend/components/Locations/Globe/index.vue";
import AsyncData from "@/shared/components/AsyncData.vue";
import BreadCrumbs from "@/shared/components/BreadCrumbs/index.vue";
import type { Crumb } from "@/shared/components/BreadCrumbs/types";
import Heading from "@/shared/components/base/Heading/index.vue";
import BodyColumns from "@/frontend/components/Locations/BodyColumns/index.vue";
import ContentsList from "@/frontend/components/Locations/Contents/index.vue";
import LocationResources from "@/frontend/components/Locations/Resources/index.vue";
import LocationFacilities from "@/frontend/components/Locations/Facilities/index.vue";
import StarmapFacts from "@/frontend/components/Locations/StarmapFacts/index.vue";
import SystemStrip from "@/frontend/components/Locations/SystemStrip/index.vue";
import LocationMissions from "@/frontend/components/Locations/Missions/index.vue";
import LocationPeople from "@/frontend/components/Locations/People/index.vue";
import { useSessionStore } from "@/frontend/stores/session";
import { storeToRefs } from "pinia";
import { useI18n } from "@/shared/composables/useI18n";
import { useMetaInfo } from "@/shared/composables/useMetaInfo";
import { isGlobeKind, sunStyle } from "@/shared/utils/LocationGlobe";
import {
  LocationKindEnum,
  type LocationTreeNode,
  useGameMissions,
  useLocation,
  useLocationContents,
  useLocationPeople,
  useLocationShops,
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

// The star opens the same page as its system, so it is left out.
const crumbs = computed<Crumb[]>(() => [
  { to: { name: "locations" }, label: t("labels.location.allSystems") },
  ...(location.value?.ancestors ?? [])
    .filter((ancestor) => ancestor.kind !== LocationKindEnum.STAR)
    .map((ancestor) => ({
      to: { name: "location", params: { slug: ancestor.slug } },
      label: ancestor.name ?? undefined,
    })),
]);

const contentGroups = computed(() =>
  (contents.value?.groups ?? []).filter(
    (group) =>
      !moonColumns.value.length || group.kind !== LocationKindEnum.MOON,
  ),
);

// What a system page counts: every place in it, its planets, their moons.
type SystemBadge = {
  key: string;
  label: string;
  value: string | number;
  title?: string;
  warning?: boolean;
};

const systemBadges = computed((): SystemBadge[] => {
  const planets = bodies.value.filter(
    (body) => body.location.kind === LocationKindEnum.PLANET,
  );
  const moons = bodies.value.flatMap((body) =>
    body.children.filter(
      (child) => child.location.kind === LocationKindEnum.MOON,
    ),
  );

  const unstable: SystemBadge[] = star.value?.location.unstable
    ? [
        {
          key: "unstable",
          label: t("labels.location.kinds.star"),
          value: t("labels.location.unstable"),
          title: t("labels.location.unstableHint"),
          warning: true,
        },
      ]
    : [];

  return [
    ...unstable,
    {
      key: "places",
      label: t("labels.location.places"),
      value: location.value?.placesCount ?? 0,
    },
    {
      key: "planets",
      label: t("labels.location.planets"),
      value: planets.length,
    },
    {
      key: "moons",
      label: t("labels.location.moonsBadge"),
      value: moons.length,
    },
  ];
});

// What sits around the star but on no planet: Wikelo's emporiums, a stray
// asteroid. The planets and gateways are on the strip and in the columns.
const { data: starContents } = useLocationContents(
  computed(() => star.value?.location.slug ?? ""),
  { query: { enabled: computed(() => isSystemView.value && !!star.value) } },
);

const elsewhereGroups = computed(() => {
  const shown = new Set([
    ...(star.value?.gateways ?? []).map((gateway) => gateway.id),
  ]);

  return (starContents.value?.groups ?? [])
    .filter(
      (group) =>
        group.kind !== LocationKindEnum.PLANET &&
        group.kind !== LocationKindEnum.MOON,
    )
    .map((group) => {
      const entries = group.entries.filter(
        (entry) => !shown.has(entry.location.id),
      );

      return {
        ...group,
        entries,
        count: entries.reduce((sum, entry) => sum + entry.count, 0),
      };
    })
    .filter((group) => group.entries.length);
});

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

// The shops UEX lists here. The game files carry none, so this is the only
// source; a system page has no shops of its own.
const { data: shops } = useLocationShops(slug, {
  query: { enabled: computed(() => loaded.value && !isSystemView.value) },
});

const sessionStore = useSessionStore();

const { isAuthenticated } = storeToRefs(sessionStore);

// Friends and fleet mates here or somewhere inside, which only a signed-in
// reader has. Never from the previous place while this one loads: the
// client's placeholder carries a result across keys.
const { data: peopleData, isPlaceholderData: peopleIsPlaceholder } =
  useLocationPeople(slug, undefined, {
    query: { enabled: computed(() => loaded.value && isAuthenticated.value) },
  });

const people = computed(() =>
  isAuthenticated.value && !peopleIsPlaceholder.value
    ? peopleData.value
    : undefined,
);

// A page's worth in the rail, grouped by who offers them; the mission list,
// filtered to here, has the rest.
const MISSIONS_PER_PAGE = 100;

const { data: missions } = useGameMissions(
  computed(() => ({
    perPage: String(MISSIONS_PER_PAGE),
    q: { atLocation: locationId.value },
  })),
  { query: { enabled: loaded } },
);

// A star or a body is drawn before its name, as in the strip. A picture, of
// any place, is the header above the page.
const showGlobe = computed(
  () =>
    !!location.value &&
    (location.value.kind === LocationKindEnum.STAR ||
      isGlobeKind(location.value.kind)),
);

const headerImage = computed(() => {
  const image = location.value?.image;
  if (!image) return undefined;

  return image.xlargeUrl ?? image.largeUrl ?? image.url;
});

// The export writes line breaks as a literal `\n`.
const description = computed(() =>
  location.value?.description?.replaceAll("\\n", "\n"),
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
        <div>
          <BreadCrumbs :crumbs="crumbs" />

          <img
            v-if="headerImage"
            :src="headerImage"
            alt=""
            class="location-page__header-image"
            data-test="location-header-image"
          />

          <div class="location-page__masthead">
            <div class="location-page__title">
              <LocationGlobe
                v-if="showGlobe && isGlobeKind(location.kind)"
                class="location-page__globe"
                :location="location"
              />
              <span
                v-else-if="showGlobe"
                class="location-page__globe location-page__globe--star"
                :class="{ 'location-page__globe--unstable': location.unstable }"
                :style="sunStyle(location)"
                aria-hidden="true"
                data-test="location-sun"
              />
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

              <template v-if="isSystemView">
                <span
                  v-for="badge in systemBadges"
                  :key="badge.key"
                  class="location-page__badge"
                  :class="{ 'location-page__badge--warning': badge.warning }"
                  :title="badge.title"
                >
                  <span class="location-page__badge-label">
                    {{ badge.label }}
                  </span>
                  <span class="location-page__badge-value">
                    {{ badge.value }}
                  </span>
                </span>
              </template>

              <span v-else class="location-page__badge">
                <span class="location-page__badge-label">
                  {{ t("labels.location.kind") }}
                </span>
                <span class="location-page__badge-value">
                  {{
                    location.bodyType
                      ? t(`labels.location.bodyTypes.${location.bodyType}`)
                      : t(`labels.location.kinds.${location.kind}`)
                  }}
                </span>
              </span>
            </div>
          </div>
        </div>

        <ExternalLinks v-if="location.name" :title="location.name" />

        <SystemStrip
          v-if="tree"
          :tree="tree"
          :path="path"
          :compact="!isSystemView"
        />

        <template v-if="isSystemView">
          <Panel v-if="description">
            <PanelBody>
              <p class="location-page__description">{{ description }}</p>
            </PanelBody>
          </Panel>

          <BodyColumns :bodies="bodies" />

          <section v-if="elsewhereGroups.length" class="location-page__panel">
            <h2 class="location-page__panel-title">
              {{
                t("labels.location.elsewhere", { star: star?.location.name })
              }}
            </h2>
            <ContentsList
              :groups="elsewhereGroups"
              :parent-id="star?.location.id ?? location.id"
            />
          </section>

          <LocationPeople
            v-if="people?.people.length"
            :people="people.people"
            :total-count="people.totalCount"
            :location-id="location.id"
          />

          <!-- A mission can name the star itself: Pyro's Firesale contracts. -->
          <LocationMissions
            v-if="missions?.items?.length"
            :missions="missions.items"
            :total="
              missions.meta.pagination?.totalCount ?? missions.items.length
            "
            :location-id="location.id"
          />
        </template>

        <div v-else class="location-page__layout">
          <div class="location-page__main">
            <Panel v-if="description">
              <PanelBody>
                <p class="location-page__description">{{ description }}</p>
              </PanelBody>
            </Panel>

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

            <LocationShops v-if="shops?.shops.length" :shops="shops.shops" />
          </div>

          <aside class="location-page__aside">
            <LocationPeople
              v-if="people?.people.length"
              :people="people.people"
              :total-count="people.totalCount"
              :location-id="location.id"
            />
            <MetricsCard
              v-if="location.facilities"
              :title="t('labels.location.facilities')"
              variant="slim"
            >
              <LocationFacilities :facilities="location.facilities" />
            </MetricsCard>
            <MetricsCard
              v-if="location.resources?.length"
              :title="t('labels.location.resources')"
              variant="slim"
            >
              <LocationResources :groups="location.resources" />
            </MetricsCard>

            <MetricsCard :title="t('labels.location.starmap')" variant="slim">
              <StarmapFacts :location="location" />
            </MetricsCard>

            <MetricsCard
              v-if="location.terminals?.length"
              :title="t('labels.location.terminals')"
              variant="slim"
            >
              <div class="metrics-card__rows">
                <div
                  v-for="terminal in location.terminals"
                  :key="terminal.id"
                  class="metrics-card__row"
                >
                  <span class="location-page__terminal">
                    {{ terminal.name }}
                  </span>
                </div>
              </div>
            </MetricsCard>
            <LocationMissions
              v-if="missions?.items?.length"
              :missions="missions.items"
              :total="
                missions.meta.pagination?.totalCount ?? missions.items.length
              "
              :location-id="location.id"
            />
          </aside>
        </div>
      </div>
    </template>
  </AsyncData>
</template>

<style lang="scss" scoped>
@import "index";
@import "@/shared/components/metricsCard";
</style>
