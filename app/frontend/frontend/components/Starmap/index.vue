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
import {
  LocationKindEnum,
  getLocationTreeQueryOptions,
  useLocationJumpPoints,
  useLocationStarmap,
  useLocations,
} from "@/services/fyApi";
import StarmapScene from "./Scene.vue";
import StarmapPanel from "./Panel.vue";
import Skybox from "@/shared/components/HoloViewer/Skybox/index.vue";
import pyroNebula from "@/images/skyboxes/pyro_nebula_2k.webp";
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

const navigate = (system: string | null, focus: string | null = null) => {
  const query: Record<string, string> = {};
  if (system) query.system = system;
  if (system && focus) query.focus = focus;

  void router.push({ query });
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
  isLoading: starmapLoading,
  isError: starmapError,
} = useLocationStarmap(
  computed(() => systemSlug.value ?? ""),
  {
    query: { enabled: computed(() => !!systemSlug.value) },
  },
);

const loading = computed(() =>
  systemSlug.value ? starmapLoading.value : systemsLoading.value,
);

const scene = computed<Scene | null>(() => {
  if (!systemSlug.value) {
    return systemsScene(
      systems.value?.items ?? [],
      jumpPoints.value ?? [],
      systemStars.value,
    );
  }

  const places = starmap.value?.places;
  return places ? systemScene(places) : null;
});

// The game's own sky behind a system, where there is one: Stanton's and
// Pyro's nebulae, as the holo viewer offers them. Nyx has none yet.
const BACKDROPS: Record<string, string> = {
  stanton: stantonNebula,
  pyro: pyroNebula,
};

const backdrop = computed(() => {
  const name = starmap.value?.system.slug.split("-")[0];
  return systemSlug.value && name ? BACKDROPS[name] : undefined;
});

const empty = computed(
  () => !loading.value && !!scene.value && scene.value.items.length === 0,
);

// On the ring a picked system is only held here: it is not a place to share.
const pickedSystem = ref<string | null>(null);

watch(systemSlug, () => {
  pickedSystem.value = null;
});

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

const onFocus = (entry: StarmapItem) => {
  if (scene.value?.kind === "systems") {
    pickedSystem.value = entry.key;
    return;
  }

  if (entry.key === focusKey.value) return;
  navigate(systemSlug.value, entry.role === "star" ? null : entry.slug);
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
  else navigate(null);
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
      go: systemSlug.value ? () => navigate(null) : undefined,
    },
  ];

  if (!systemSlug.value) return list;

  const steps = chain.value.slice(1);

  list.push({
    key: "system",
    label: starmap.value?.system.name ?? systemSlug.value,
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
    ? (starmap.value?.system.name ?? systemSlug.value)
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

// The figures the location card shows, label over value as on every metrics
// card in the app.
const facts = computed(() => {
  const entry = focused.value;
  if (!entry || !scene.value) return [];

  const list: { key: string; label: string; value: string }[] = [];
  const anchor = chain.value.at(-2);

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
});
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
        <Skybox v-if="backdrop" :src="backdrop" />
        <StarmapScene
          v-if="scene"
          ref="sceneRef"
          :scene="scene"
          :focus-key="focusKey"
          :show-labels="showLabels"
          :show-orbits="showOrbits"
          @focus="onFocus"
          @enter="enter"
          @release="release"
        />
      </TresCanvas>
      <WebglFallback v-else />

      <p v-if="loading" class="starmap__status" data-test="starmap-loading">
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

            <StarmapPanel
              :items="scene?.items ?? []"
              :focus-key="focusKey"
              @focus="onFocus"
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
    background: radial-gradient(circle at 50% 40%, #0d1c30 0%, #050a12 70%);
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
