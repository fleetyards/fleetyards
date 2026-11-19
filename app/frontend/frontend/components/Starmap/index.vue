<script lang="ts">
export default {
  name: "Starmap",
};
</script>

<script lang="ts" setup>
import { TresCanvas } from "@tresjs/core";
import { OrbitControls } from "@tresjs/cientos";
import KindIcon from "@/frontend/components/Locations/KindIcon/index.vue";
import WebglFallback from "@/shared/components/WebglFallback/index.vue";
import { useMobile } from "@/shared/composables/useMobile";
import { useWebglSupport } from "@/shared/composables/useWebglSupport";
import { useI18n } from "@/shared/composables/useI18n";
import { useQueries } from "@tanstack/vue-query";
import { refDebounced } from "@vueuse/core";
import LocationStatsCard from "@/frontend/components/StatsCard/Location/index.vue";
import {
  LocationKindEnum,
  getLocationTreeQueryOptions,
  useLocationJumpPoints,
  useLocation,
  useLocationStarmap,
  useLocations,
} from "@/services/fyApi";
import StarmapScene from "./Scene.vue";
import StarmapPanel from "./Panel.vue";
import StarmapRoutePanel from "./RoutePanel.vue";
import { legsInSystem, useStarmapRoute } from "./route";
import Skybox from "@/shared/components/HoloViewer/Skybox/index.vue";
import nyxSky from "@/images/skyboxes/nyx_sky_4k.webp";
import pyroSky from "@/images/skyboxes/pyro_sky_4k.webp";
import stantonNebula from "@/images/skyboxes/stanton_nebula_spherical_2k.webp";
import {
  chainOf,
  systemScene,
  systemsScene,
  type StarmapItem,
  type StarmapScene as Scene,
} from "./layout";

const { t, toNumber } = useI18n();

const route = useRoute();
const router = useRouter();

const mobile = useMobile();
const { webglSupported } = useWebglSupport();

const dpr = computed(() =>
  mobile.value
    ? Math.min(window.devicePixelRatio, 1.5)
    : window.devicePixelRatio,
);

// Where the reader is lives in the address, so a view can be shared and the
// back button walks back along the way they came.
const queryValue = (value: unknown) =>
  typeof value === "string" && value ? value : null;

const systemSlug = computed(() => queryValue(route.query.system));
const focusSlug = computed(() =>
  systemSlug.value ? queryValue(route.query.focus) : null,
);

// A planned route stays in the address as the map moves underneath it.
const ROUTE_KEYS = ["from", "to", "ship", "loadout"] as const;
type RouteKey = (typeof ROUTE_KEYS)[number];

const routeQuery = () => {
  const query: Record<string, string> = {};
  for (const key of ROUTE_KEYS) {
    const value = queryValue(route.query[key]);
    if (value) query[key] = value;
  }
  return query;
};

const navigate = (
  system: string | null,
  focus: string | null = null,
  { replace = false }: { replace?: boolean } = {},
) => {
  const query: Record<string, string> = routeQuery();
  if (system) query.system = system;
  if (system && focus) query.focus = focus;

  void (replace ? router.replace({ query }) : router.push({ query }));
};

const routeParam = (key: RouteKey) =>
  computed(() => queryValue(route.query[key]));

const routeFrom = routeParam("from");
const routeTo = routeParam("to");
const routeShip = routeParam("ship");
const routeLoadout = routeParam("loadout");

const setRouteParam = (key: RouteKey, value: string | null) => {
  const query: Record<string, string> = {};
  for (const [name, entry] of Object.entries(route.query)) {
    const text = queryValue(entry);
    if (text) query[name] = text;
  }

  if (value) query[key] = value;
  else delete query[key];

  // Another ship has other loadouts.
  if (key === "ship") delete query.loadout;

  void router.replace({ query });
};

const { data: systems, isLoading: systemsLoading } = useLocations({
  q: { kindEq: LocationKindEnum.SYSTEM },
});

const { data: jumpPoints } = useLocationJumpPoints();

// Each system's star, for drawing the systems as their stars: its colour and
// whether it flares, from the system's tree as the location pages load it.
const systemTrees = useQueries({
  queries: computed(() =>
    (systems.value?.items ?? []).map((system) =>
      getLocationTreeQueryOptions(system.slug),
    ),
  ),
});

const systemStars = computed(() => {
  const stars = new Map<string, { color: string | null; unstable: boolean }>();

  for (const result of systemTrees.value) {
    const tree = result.data;
    const star = tree?.children.find(
      (node) => node.location.kind === LocationKindEnum.STAR,
    )?.location;
    if (tree && star) {
      stars.set(tree.location.id, {
        color: star.color,
        unstable: !!star.unstable,
      });
    }
  }

  return stars;
});

const {
  data: starmap,
  isLoading: starmapFirstLoading,
  isPlaceholderData: starmapPlaceholder,
  isError: starmapError,
} = useLocationStarmap(
  computed(() => systemSlug.value ?? ""),
  {
    query: { enabled: computed(() => !!systemSlug.value) },
  },
);

// The app keeps a query's last data while the next loads: here that is the
// last system's places, which are not the opened system's.
const starmapLoading = computed(
  () => starmapFirstLoading.value || starmapPlaceholder.value,
);

const openedStarmap = computed(() =>
  starmapPlaceholder.value ? undefined : starmap.value,
);

const loading = computed(() =>
  systemSlug.value ? starmapLoading.value : systemsLoading.value,
);

// Out of a system the camera climbs away from its star first, and the
// systems view opens once it has. The browser's back button skips the climb
// and the systems view only fades in.
const leaveSystem = async () => {
  await sceneRef.value?.leave();
  navigate(null);
};

// A system is opened and its places are not in yet.
const waiting = computed(
  () => !!systemSlug.value && !scene.value && !starmapError.value,
);

// How much of the scene is shown as it fades between the systems and a system.
const curtain = ref(1);

// The system just stepped out of, which the systems view pulls back from.
const cameFrom = ref<string | null>(null);

watch(systemSlug, (_now, before) => {
  cameFrom.value = before ?? null;
});

const scene = computed<Scene | null>(() => {
  if (!systemSlug.value) {
    return systemsScene(
      systems.value?.items ?? [],
      jumpPoints.value ?? [],
      systemStars.value,
    );
  }

  const places = openedStarmap.value?.places;
  return places ? systemScene(places) : null;
});

// The game's own sky behind a system: Nyx's and Pyro's as the game draws
// them, at the opacity it draws them with over the stars, and Stanton's
// nebula as the holo viewer offers it until Stanton's own is exported.
const BACKDROPS: Record<string, { src: string; opacity: number }> = {
  stanton: { src: stantonNebula, opacity: 1 },
  pyro: { src: pyroSky, opacity: 0.6 },
  nyx: { src: nyxSky, opacity: 1 },
};

const backdrop = computed(() => {
  const name = openedStarmap.value?.system.slug.split("-")[0];
  return systemSlug.value && name ? BACKDROPS[name] : undefined;
});

const railTab = ref<"places" | "route">(
  routeFrom.value || routeTo.value || routeShip.value ? "route" : "places",
);

const planning = computed(
  () =>
    railTab.value === "route" ||
    !!(routeFrom.value && routeTo.value && routeShip.value),
);

const {
  options: routeOptions,
  routeSystems,
  placesLoading: routePlacesLoading,
  model: routeModel,
  drive: routeDrive,
  driveLoading: routeDriveLoading,
  loadoutOptions: routeLoadoutOptions,
  missingLoadout: routeMissingLoadout,
  route: plannedRoute,
} = useStarmapRoute({
  enabled: planning,
  systems: () => systems.value?.items ?? [],
  jumpPoints: () => jumpPoints.value ?? [],
  from: routeFrom,
  to: routeTo,
  ship: routeShip,
  loadout: routeLoadout,
});

const sceneRoute = computed(() => {
  const opened = openedStarmap.value?.system.id;
  if (!opened || scene.value?.kind !== "system") return [];

  return legsInSystem(
    plannedRoute.value,
    routeSystems.value.find((system) => system.id === opened),
  );
});

const empty = computed(
  () => !loading.value && !!scene.value && scene.value.items.length === 0,
);

// On the ring a picked system is only held here: it is not a place to share.
const pickedSystem = ref<string | null>(null);

watch(systemSlug, () => {
  pickedSystem.value = null;
});

// The scene on screen: the last one built, kept while the next one loads, so
// the systems view stays behind the star being opened rather than blanking.
const shownScene = shallowRef<Scene | null>(null);

watch(
  scene,
  (next) => {
    if (next || !systemSlug.value) shownScene.value = next;
  },
  { immediate: true },
);

const star = computed(() =>
  scene.value?.items.find((entry) => entry.role === "star"),
);

const focusKey = computed(() => {
  if (!scene.value) return null;
  if (scene.value.kind === "systems") return pickedSystem.value;

  const entry = focusSlug.value
    ? scene.value.items.find((item) => item.slug === focusSlug.value)
    : undefined;

  return entry?.key ?? star.value?.key ?? null;
});

const focused = computed(
  () =>
    scene.value?.items.find((entry) => entry.key === focusKey.value) ?? null,
);

const chain = computed(() =>
  scene.value?.kind === "system" ? chainOf(scene.value, focusKey.value) : [],
);

// A focus the zoom handed over replaces the last one in the history: one
// scroll down through a body's places is not a step back for each of them.
const onFocus = (entry: StarmapItem, zoomed = false) => {
  if (scene.value?.kind === "systems") {
    pickedSystem.value = entry.key;
    return;
  }

  if (entry.key === focusKey.value) return;
  navigate(systemSlug.value, entry.role === "star" ? null : entry.slug, {
    replace: zoomed,
  });
};

const release = () => {
  if (scene.value?.kind === "systems") {
    pickedSystem.value = null;
    return;
  }

  navigate(systemSlug.value);
};

const enter = (entry: StarmapItem) => {
  if (entry.role === "system") navigate(entry.slug);
};

// Escape steps out: from a place to its body, a moon to its planet, a planet
// to the star, and from the star to the systems.
const stepOut = () => {
  if (!systemSlug.value) {
    pickedSystem.value = null;
    return;
  }

  const parent = chain.value.at(-2);
  if (parent) onFocus(parent);
  else void leaveSystem();
};

const onKeydown = (event: KeyboardEvent) => {
  if (event.key !== "Escape" || event.defaultPrevented) return;

  const target = event.target as HTMLElement | null;
  if (target?.closest("input, textarea, select, [contenteditable]")) return;

  // Escape belongs to whatever is open over the map first: a modal, a menu.
  // Menus stay in the page while closed, so only a visible one counts.
  const overlays = document.querySelectorAll<HTMLElement>(
    "[role='dialog'], dialog[open], [aria-modal='true'], [role='menu']",
  );
  if ([...overlays].some((element) => element.checkVisibility?.() ?? true)) {
    return;
  }

  stepOut();
};

onMounted(() => window.addEventListener("keydown", onKeydown));
onBeforeUnmount(() => window.removeEventListener("keydown", onKeydown));

const crumbs = computed(() => {
  const list: { key: string; label: string; go?: () => void }[] = [
    {
      key: "systems",
      label: t("starmap.systems"),
      go: systemSlug.value ? () => void leaveSystem() : undefined,
    },
  ];

  if (!systemSlug.value) return list;

  const steps = chain.value.slice(1);

  list.push({
    key: "system",
    label: openedStarmap.value?.system.name ?? systemSlug.value,
    go: steps.length ? () => navigate(systemSlug.value) : undefined,
  });

  steps.forEach((entry, index) => {
    list.push({
      key: entry.key,
      label: entry.name,
      go: index < steps.length - 1 ? () => onFocus(entry) : undefined,
    });
  });

  return list;
});

const sceneRef = ref<InstanceType<typeof StarmapScene> | null>(null);

const reframe = () => sceneRef.value?.reframe();
const zoomIn = () => sceneRef.value?.zoomStep(0.6);
const zoomOut = () => sceneRef.value?.zoomStep(1 / 0.6);

const showLabels = ref(true);
const showOrbits = ref(true);

// The rail starts open where there is room for it beside the map.
const railOpen = ref(!mobile.value);

const title = computed(() =>
  systemSlug.value
    ? (openedStarmap.value?.system.name ?? systemSlug.value)
    : t("starmap.systems"),
);

// Metres, in the largest unit that keeps the number readable: a planet's
// radius reads as 1,000 km rather than 1 Mm.
const formatLength = (metres: number) => {
  if (metres >= 1e9) {
    return t("starmap.units.gm", { value: toNumber(metres / 1e9) });
  }
  if (metres >= 1e7) {
    return t("starmap.units.mm", { value: toNumber(metres / 1e6) });
  }

  return t("starmap.units.km", { value: toNumber(metres / 1e3) });
};

const isBody = (entry: StarmapItem) =>
  entry.role === "planet" ||
  entry.role === "moon" ||
  entry.role === "star" ||
  entry.role === "system";

// The figures the location card and the hover tooltip show, label over
// value as on every metrics card in the app.
const factsOf = (entry: StarmapItem | null | undefined) => {
  if (!entry || !scene.value) return [];

  const list: { key: string; label: string; value: string }[] = [];
  const anchor = entry.anchor
    ? scene.value.items.find((item) => item.key === entry.anchor)
    : undefined;

  if (anchor && entry.distance) {
    list.push({
      key: "distance",
      label: t("starmap.distanceFrom", { name: anchor.name }),
      value: formatLength(entry.distance),
    });
  }

  if (entry.realRadius) {
    list.push({
      key: "radius",
      label: t("starmap.radius"),
      value: formatLength(entry.realRadius),
    });
  }

  const children = scene.value.items.filter(
    (item) => item.anchor === entry.key,
  );
  const moons = children.filter((item) => item.role === "moon").length;
  const places = children.length - moons;

  if (moons) {
    list.push({
      key: "moons",
      label: t("starmap.moons"),
      value: String(moons),
    });
  }
  if (places) {
    list.push({
      key: "places",
      label: t("starmap.places"),
      value: String(places),
    });
  }

  return list;
};

const facts = computed(() => factsOf(focused.value));

// What is under the pointer, for the tooltip over it. Not shown for what is
// focused: the card already says all of it.
const hovered = shallowRef<{ item: StarmapItem; x: number; y: number } | null>(
  null,
);

const tooltip = computed(() => {
  const target = hovered.value;
  if (!target || target.item.key === focusKey.value) return null;
  if (target.item.role === "system") return null;

  // Below the place where above it would run off the top of the map.
  return { ...target, below: target.y < HOVER_CARD_ROOM };
});

const HOVER_CARD_ROOM = 300;

// The hover card every place link in the app opens, for what is under the
// pointer. Fetched once the pointer rests on a place, so sweeping across the
// map does not ask for every marker it passes.
const hoveredSlug = computed(() => tooltip.value?.item.slug ?? "");
const restingSlug = refDebounced(hoveredSlug, 250);

const { data: hoverLocation, isPending: hoverPending } = useLocation(
  restingSlug,
  { query: { enabled: computed(() => !!restingSlug.value) } },
);

const hoverCardReady = computed(
  () => !!tooltip.value && restingSlug.value === hoveredSlug.value,
);

watch(
  () => scene.value,
  () => {
    hovered.value = null;
  },
);
</script>

<template>
  <div
    class="starmap"
    :class="{
      'starmap--rail': railOpen && webglSupported,
      'starmap--card': !!focused && focused.role !== 'star',
    }"
  >
    <div class="starmap__stage">
      <TresCanvas
        v-if="webglSupported"
        :clear-alpha="0"
        :shadows="false"
        :dpr="dpr"
        :power-preference="mobile ? 'low-power' : 'default'"
        logarithmic-depth-buffer
        alpha
      >
        <TresPerspectiveCamera
          :position="[0, 30, 50]"
          :args="[50, 1, 0.001, 1e7]"
        />
        <OrbitControls
          enable-damping
          :damping-factor="0.08"
          :enable-zoom="false"
          :rotate-speed="0.6"
          :enable-pan="false"
          make-default
        />
        <Skybox
          v-if="backdrop"
          :key="backdrop.src"
          :src="backdrop.src"
          :opacity="backdrop.opacity * curtain"
        />
        <StarmapScene
          v-if="shownScene"
          ref="sceneRef"
          :scene="shownScene"
          :came-from="cameFrom"
          :waiting="waiting"
          :focus-key="focusKey"
          :show-labels="showLabels"
          :show-orbits="showOrbits"
          :route="sceneRoute"
          @focus="onFocus"
          @enter="enter"
          @release="release"
          @hover="hovered = $event"
          @curtain="curtain = $event"
        />
      </TresCanvas>
      <WebglFallback v-else />

      <p
        v-if="loading"
        class="starmap__status starmap__status--loading"
        data-test="starmap-loading"
      >
        <i class="fa-duotone fa-spinner-third fa-spin" aria-hidden="true" />
        {{ t("starmap.loading") }}
      </p>
      <p v-else-if="systemSlug && starmapError" class="starmap__status">
        {{ t("starmap.unavailable") }}
      </p>
      <p v-else-if="systemSlug && !scene" class="starmap__status">
        {{ t("starmap.notFound") }}
      </p>
      <p v-else-if="empty" class="starmap__status" data-test="starmap-empty">
        {{ t("starmap.empty") }}
      </p>

      <template v-if="webglSupported">
        <div class="starmap__column">
          <aside
            v-if="railOpen"
            class="starmap__rail starmap__glass"
            :aria-label="title"
            data-test="starmap-panel"
          >
            <div class="starmap__rail-head">
              <div class="starmap__rail-titles">
                <nav class="starmap__crumbs" :aria-label="t('starmap.level')">
                  <template v-for="(crumb, index) in crumbs" :key="crumb.key">
                    <i
                      v-if="index > 0"
                      class="fa-light fa-chevron-right starmap__crumb-separator"
                      aria-hidden="true"
                    />
                    <button
                      v-if="crumb.go"
                      type="button"
                      class="starmap__crumb"
                      :data-test="`starmap-crumb-${crumb.key}`"
                      @click="crumb.go"
                    >
                      {{ crumb.label }}
                    </button>
                    <span
                      v-else
                      class="starmap__crumb starmap__crumb--current"
                      aria-current="page"
                    >
                      {{ crumb.label }}
                    </span>
                  </template>
                </nav>
                <h1 class="starmap__title">{{ title }}</h1>
              </div>
              <button
                type="button"
                class="starmap__icon-btn starmap__icon-btn--framed"
                :aria-label="t('starmap.panel.hide')"
                data-test="starmap-panel-toggle"
                @click="railOpen = false"
              >
                <i class="fa-light fa-sidebar" aria-hidden="true" />
              </button>
            </div>

            <div
              class="starmap__group starmap__tabs"
              role="tablist"
              :aria-label="t('starmap.panel.tabs')"
            >
              <button
                v-for="tab in ['places', 'route'] as const"
                :key="tab"
                type="button"
                role="tab"
                class="starmap__tab"
                :class="{ 'starmap__tab--on': railTab === tab }"
                :aria-selected="railTab === tab"
                :data-test="`starmap-tab-${tab}`"
                @click="railTab = tab"
              >
                {{ t(`starmap.panel.${tab}`) }}
              </button>
            </div>

            <StarmapPanel
              v-if="railTab === 'places'"
              :items="scene?.items ?? []"
              :focus-key="focusKey"
              @focus="onFocus"
            />
            <StarmapRoutePanel
              v-else
              :options="routeOptions"
              :from="routeFrom"
              :to="routeTo"
              :ship="routeShip"
              :loadout="routeLoadout"
              :loadout-options="routeLoadoutOptions"
              :missing-loadout="routeMissingLoadout"
              :route="plannedRoute"
              :has-drive="!!routeDrive"
              :loading="routePlacesLoading || routeDriveLoading"
              :tank-size="routeModel?.metrics?.quantumFuelTankSize ?? null"
              :focused="
                focused && focused.role !== 'system'
                  ? { slug: focused.slug, name: focused.name }
                  : null
              "
              @update:from="setRouteParam('from', $event)"
              @update:to="setRouteParam('to', $event)"
              @update:ship="setRouteParam('ship', $event)"
              @update:loadout="setRouteParam('loadout', $event)"
            />
          </aside>
          <button
            v-else
            type="button"
            class="starmap__reopen starmap__glass"
            :aria-label="t('starmap.panel.show')"
            data-test="starmap-panel-toggle"
            @click="railOpen = true"
          >
            <i class="fa-light fa-sidebar" aria-hidden="true" />
            <span class="starmap__reopen-title">{{ title }}</span>
          </button>
        </div>

        <Teleport defer to="#header-right">
          <div class="starmap__controls">
            <div
              class="starmap__group"
              role="group"
              :aria-label="t('starmap.view')"
            >
              <button
                type="button"
                class="starmap__icon-btn"
                :aria-label="t('starmap.reframe')"
                :title="t('starmap.reframe')"
                data-test="starmap-reset"
                @click="reframe"
              >
                <i class="fa-light fa-crosshairs" aria-hidden="true" />
              </button>
              <button
                type="button"
                class="starmap__icon-btn"
                :class="{ 'starmap__icon-btn--on': showLabels }"
                :aria-pressed="showLabels"
                :aria-label="t('starmap.labels')"
                :title="t('starmap.labels')"
                @click="showLabels = !showLabels"
              >
                <i class="fa-light fa-tag" aria-hidden="true" />
              </button>
              <button
                type="button"
                class="starmap__icon-btn"
                :class="{ 'starmap__icon-btn--on': showOrbits }"
                :aria-pressed="showOrbits"
                :aria-label="t('starmap.orbits')"
                :title="t('starmap.orbits')"
                @click="showOrbits = !showOrbits"
              >
                <i class="fa-light fa-circle-dashed" aria-hidden="true" />
              </button>
            </div>
            <div
              class="starmap__group"
              role="group"
              :aria-label="t('starmap.zoom')"
            >
              <button
                type="button"
                class="starmap__icon-btn"
                :aria-label="t('starmap.zoomIn')"
                :title="t('starmap.zoomIn')"
                @click="zoomIn"
              >
                <i class="fa-light fa-plus" aria-hidden="true" />
              </button>
              <button
                type="button"
                class="starmap__icon-btn"
                :aria-label="t('starmap.zoomOut')"
                :title="t('starmap.zoomOut')"
                @click="zoomOut"
              >
                <i class="fa-light fa-minus" aria-hidden="true" />
              </button>
            </div>
          </div>
        </Teleport>

        <section
          v-if="focused && focused.role !== 'star'"
          class="starmap__card starmap__glass"
          data-test="starmap-detail"
          :aria-label="focused.name"
        >
          <span
            v-if="isBody(focused)"
            class="starmap__card-globe"
            :style="{ '--dot-color': focused.color }"
          />
          <KindIcon v-else class="starmap__card-glyph" :kind="focused.kind" />

          <div class="starmap__card-body">
            <div class="starmap__card-title">
              <h2 class="starmap__card-name">{{ focused.name }}</h2>
              <span class="starmap__micro">
                {{ t(`labels.location.kinds.${focused.kind}`) }}
              </span>
            </div>
            <dl v-if="facts.length" class="starmap__facts">
              <div v-for="fact in facts" :key="fact.key">
                <dt class="starmap__micro">{{ fact.label }}</dt>
                <dd>{{ fact.value }}</dd>
              </div>
            </dl>
          </div>

          <button
            v-if="focused.role === 'system'"
            type="button"
            class="starmap__icon-btn starmap__icon-btn--framed"
            :aria-label="t('starmap.openSystem', { name: focused.name })"
            :title="t('starmap.openSystem', { name: focused.name })"
            data-test="starmap-enter"
            @click="enter(focused)"
          >
            <i class="fa-light fa-arrow-right-to-bracket" aria-hidden="true" />
          </button>
          <RouterLink
            v-else
            class="starmap__icon-btn starmap__icon-btn--framed"
            :to="{ name: 'location', params: { slug: focused.slug } }"
            :aria-label="t('starmap.openLocation')"
            :title="t('starmap.openLocation')"
            data-test="starmap-location-link"
          >
            <i
              class="fa-light fa-arrow-up-right-from-square"
              aria-hidden="true"
            />
          </RouterLink>
        </section>

        <div
          v-if="tooltip && hoverCardReady"
          class="starmap__hover-card"
          :class="{ 'starmap__hover-card--below': tooltip.below }"
          :style="{ left: `${tooltip.x}px`, top: `${tooltip.y}px` }"
          data-test="starmap-tooltip"
        >
          <LocationStatsCard
            :to="false"
            :name="tooltip.item.name"
            :location="hoverLocation"
            :loading="hoverPending"
          />
        </div>

        <p v-if="!systemSlug" class="starmap__footnote">
          {{ t("starmap.footnote") }}
        </p>
      </template>
    </div>
  </div>
</template>

<style lang="scss" scoped>
// Above the map's labels, which sit in layers of their own over the canvas.
$overlay: 20;
// The app's header floats over the map; what sits at the map's top clears it.
$inset: var(--fullscreen-header-height, 0px);
$gap: 16px;
$rail: 300px;
$card-height: 96px;

.starmap {
  position: relative;
  display: flex;
  flex: 1;
  flex-direction: column;
  min-height: 0;

  &__stage {
    position: relative;
    flex: 1;
    min-height: 420px;
    background: #03050a;
    overflow: hidden;
    user-select: none;
    touch-action: none;
  }

  // The app's slim panel over the map: dark glass, a soft frame and the
  // end-caps every panel and button carries.
  &__glass {
    position: absolute;
    z-index: $overlay;
    border: 1px solid var(--color-edge-soft);
    border-radius: var(--radius-surface-slim);
    background: rgb(18 20 23 / 78%);
    box-shadow: 0 6px 20px -14px rgb(0 0 0 / 90%);
    backdrop-filter: blur(12px);

    &::before,
    &::after {
      content: "";
      position: absolute;
      left: 12%;
      right: 12%;
      height: 3px;
      background: var(--color-endcap);
      pointer-events: none;
    }

    &::before {
      top: -1px;
      border-radius: 0 0 3px 3px;
    }

    &::after {
      bottom: -1px;
      border-radius: 3px 3px 0 0;
    }
  }

  &__status {
    position: absolute;
    inset: 0;
    display: flex;
    align-items: center;
    justify-content: center;
    gap: 8px;
    margin: 0;
    color: var(--color-text);
    pointer-events: none;

    // Under the star the camera is on, not over it.
    &--loading {
      transform: translateY(48px);
    }
  }

  // As tall as what it lists, and scrolling only once that is taller than
  // the map.
  // The place list down the left of the map, stopping short of the card of
  // what is focused at the bottom.
  &__column {
    position: absolute;
    z-index: $overlay;
    top: calc($inset + $gap);
    bottom: $gap;
    transition: bottom 0.2s ease;
    left: $gap;
    display: flex;
    flex-direction: column;
    gap: 12px;
    width: $rail;
    pointer-events: none;

    > * {
      pointer-events: auto;
    }
  }

  &__rail {
    position: relative;
    flex: 0 1 auto;
    min-height: 0;
    display: flex;
    flex-direction: column;
    gap: 14px;
    padding: 16px;
    box-sizing: border-box;
  }

  &__rail-head {
    display: flex;
    align-items: flex-start;
    gap: 8px;
  }

  &__rail-titles {
    display: flex;
    flex: 1;
    flex-direction: column;
    gap: 6px;
    min-width: 0;
  }

  &__crumbs {
    display: flex;
    flex-wrap: wrap;
    align-items: center;
    gap: 6px;
    font-size: 0.78125rem;
  }

  &__crumb {
    padding: 0;
    border: 0;
    background: none;
    color: var(--color-text-dim);
    cursor: pointer;

    &:hover {
      color: var(--color-lifted);
    }

    &--current {
      color: var(--color-lifted);
      cursor: default;
    }
  }

  &__crumb-separator {
    font-size: 0.5625rem;
    color: var(--color-muted);
  }

  &__title {
    margin: 0;
    overflow: hidden;
    font-family: Orbitron, sans-serif;
    font-size: 22px;
    font-weight: 400;
    line-height: 1.2;
    text-overflow: ellipsis;
    white-space: nowrap;
    color: var(--color-lifted);
  }

  &__reopen {
    position: relative;
    align-self: flex-start;
    display: flex;
    align-items: center;
    gap: 10px;
    height: 44px;
    padding: 0 16px;
    color: var(--color-text);
    font-family: Orbitron, sans-serif;
    font-size: 13px;
    letter-spacing: 0.08em;
    text-transform: uppercase;
    cursor: pointer;

    &:hover {
      color: var(--color-lifted);
    }
  }

  // In the app's header, where a page keeps its own actions.
  &__controls {
    display: flex;
    gap: 8px;
  }

  &--card &__column {
    bottom: calc($gap * 2 + #{$card-height});
  }

  &__tabs {
    flex-shrink: 0;
  }

  &__tab {
    flex: 1;
    min-height: 34px;
    padding: 0 12px;
    border: 0;
    border-radius: var(--radius-control-inner);
    background: transparent;
    color: var(--color-text);
    font-size: 0.84375rem;
    cursor: pointer;

    &:hover {
      background: var(--color-control-hover);
      color: var(--color-lifted);
    }

    &:focus-visible {
      outline: 2px solid var(--color-primary);
      outline-offset: 1px;
    }

    &--on,
    &--on:hover {
      background: rgb(66 139 202 / 22%);
      color: #fff;
    }
  }

  // As the holo viewer's: a dark group of icon buttons on one frame.
  &__group {
    display: flex;
    gap: 2px;
    padding: 3px;
    border: 1px solid var(--color-edge);
    border-radius: var(--radius-control);
    background: var(--color-control);
    box-shadow: 0 6px 20px -14px rgb(0 0 0 / 90%);
  }

  &__icon-btn {
    display: flex;
    flex-shrink: 0;
    align-items: center;
    justify-content: center;
    width: 40px;
    height: 40px;
    padding: 0;
    border: 0;
    border-radius: var(--radius-control-inner);
    background: transparent;
    color: var(--color-text);
    font-size: 16px;
    text-decoration: none;
    cursor: pointer;

    &:hover {
      background: var(--color-control-hover);
      color: var(--color-lifted);
    }

    &:focus-visible {
      outline: 2px solid var(--color-primary);
      outline-offset: 1px;
    }

    &--on {
      background: rgb(66 139 202 / 22%);
      color: #fff;
    }

    &--framed {
      border: 1px solid var(--color-edge);
      border-radius: var(--radius-control);
      background: var(--color-control);
    }
  }

  // The card of what is focused: wide and low, at the bottom left.
  &__card {
    bottom: $gap;
    left: $gap;
    display: flex;
    align-items: center;
    gap: 18px;
    width: min(560px, calc(100% - #{$gap * 2}));
    padding: 16px 18px;
    box-sizing: border-box;
  }

  &__card-globe {
    flex-shrink: 0;
    width: 44px;
    height: 44px;
    border-radius: 50%;
    background:
      radial-gradient(
        circle at 32% 28%,
        rgb(255 255 255 / 45%) 0%,
        rgb(255 255 255 / 0%) 34%,
        rgb(0 0 0 / 30%) 62%,
        rgb(0 0 0 / 75%) 100%
      ),
      var(--dot-color);
  }

  &__card-glyph {
    flex-shrink: 0;
    width: 44px;
    font-size: 32px;
    color: var(--color-lifted);
  }

  &__card-body {
    display: flex;
    flex: 1;
    flex-direction: column;
    gap: 10px;
    min-width: 0;
  }

  &__card-title {
    display: flex;
    flex-wrap: wrap;
    align-items: baseline;
    gap: 4px 10px;
  }

  &__card-name {
    margin: 0;
    font-family: Orbitron, sans-serif;
    font-size: 20px;
    font-weight: 400;
    line-height: 1.2;
    color: var(--color-lifted);
  }

  &__micro {
    font-family: Orbitron, sans-serif;
    font-size: 10px;
    letter-spacing: 0.16em;
    line-height: 1.3;
    text-transform: uppercase;
    color: var(--color-text-dim);
  }

  &__facts {
    display: flex;
    flex-wrap: wrap;
    gap: 8px 22px;
    margin: 0;

    dd {
      margin: 4px 0 0;
      font-size: 13.5px;
      font-weight: 600;
      line-height: 1.3;
      color: var(--color-lifted);
    }
  }

  // The frame of the app's popover, which the same card opens in everywhere
  // else, over the place it is about.
  &__hover-card {
    position: absolute;
    z-index: $overlay;
    width: max-content;
    max-width: min(340px, calc(100% - 24px));
    border: 1px solid var(--color-edge);
    border-radius: var(--radius-control);
    background: var(--color-gray-darker, #272b30);
    box-shadow: 0 8px 24px rgb(0 0 0 / 45%);
    pointer-events: none;
    transform: translate(-50%, calc(-100% - 12px));
    animation: starmap-tooltip-in 0.15s ease-out;

    &--below {
      transform: translate(-50%, 36px);
    }
  }

  &__footnote {
    position: absolute;
    z-index: $overlay - 1;
    right: $gap;
    bottom: calc($gap + 24px);
    max-width: 420px;
    margin: 0;
    font-size: 0.71875rem;
    text-align: right;
    color: var(--color-text-dim);
    text-shadow: 0 1px 3px rgb(0 0 0 / 90%);
    pointer-events: none;
  }
}

@keyframes starmap-tooltip-in {
  from {
    opacity: 0;
  }

  to {
    opacity: 1;
  }
}

@media (prefers-reduced-motion: reduce) {
  .starmap__hover-card {
    animation: none;
  }
}

@media (width <= 767px) {
  .starmap__footnote {
    display: none;
  }

  .starmap__column {
    right: $gap;
    width: auto;
  }
}
</style>
