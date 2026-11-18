<script lang="ts">
export default {
  name: "Starmap",
};
</script>

<script lang="ts" setup>
import { TresCanvas } from "@tresjs/core";
import { OrbitControls } from "@tresjs/cientos";
import Btn from "@/shared/components/base/Btn/index.vue";
import WebglFallback from "@/shared/components/WebglFallback/index.vue";
import { useMobile } from "@/shared/composables/useMobile";
import { useWebglSupport } from "@/shared/composables/useWebglSupport";
import { useI18n } from "@/shared/composables/useI18n";
import {
  LocationKindEnum,
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
    return systemsScene(systems.value?.items ?? [], jumpPoints.value ?? []);
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

// The panel starts open where there is room for it beside the map.
const panelOpen = ref(!mobile.value);

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

const facts = computed(() => {
  const entry = focused.value;
  if (!entry) return [];

  const list: { key: string; label: string; value: string }[] = [];
  const anchor = chain.value.at(-2);

  if (entry.parentName) {
    list.push({
      key: "parent",
      label: t("starmap.parent"),
      value: entry.parentName,
    });
  }

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

  return list;
});

const hint = computed(() =>
  systemSlug.value ? t("starmap.hints.system") : t("starmap.hints.systems"),
);
</script>

<template>
  <div class="starmap">
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
          @focus="onFocus"
          @enter="enter"
          @release="release"
        />
      </TresCanvas>
      <WebglFallback v-else />

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
        <aside
          v-if="scene?.kind === 'system' && panelOpen"
          class="starmap__panel"
          data-test="starmap-panel"
        >
          <StarmapPanel
            :items="scene.items"
            :focus-key="focusKey"
            @focus="onFocus"
          />
        </aside>

        <div class="starmap__tools">
          <Btn
            v-if="scene?.kind === 'system'"
            size="sm"
            data-test="starmap-panel-toggle"
            :active="panelOpen"
            @click="panelOpen = !panelOpen"
          >
            <i class="fa-light fa-list-tree" aria-hidden="true" />
            {{ panelOpen ? t("starmap.panel.hide") : t("starmap.panel.show") }}
          </Btn>
          <Btn size="sm" data-test="starmap-reset" @click="reframe">
            <i class="fa-light fa-arrows-to-circle" aria-hidden="true" />
            {{ t("starmap.reframe") }}
          </Btn>
        </div>

        <aside
          v-if="focused && focused.role !== 'star'"
          class="starmap__detail"
          data-test="starmap-detail"
          :aria-label="focused.name"
        >
          <span class="starmap__detail-kind">
            {{ t(`labels.location.kinds.${focused.kind}`) }}
          </span>
          <h2 class="starmap__detail-name">{{ focused.name }}</h2>

          <dl v-if="facts.length" class="starmap__facts">
            <template v-for="fact in facts" :key="fact.key">
              <dt>{{ fact.label }}</dt>
              <dd>{{ fact.value }}</dd>
            </template>
          </dl>

          <div class="starmap__detail-actions">
            <Btn
              v-if="focused.role === 'system'"
              size="sm"
              data-test="starmap-enter"
              @click="enter(focused)"
            >
              <i class="fa-light fa-magnifying-glass-plus" aria-hidden="true" />
              {{ t("starmap.openSystem", { name: focused.name }) }}
            </Btn>
            <Btn
              size="sm"
              variant="ghost"
              :to="{ name: 'location', params: { slug: focused.slug } }"
              data-test="starmap-location-link"
            >
              {{ t("starmap.openLocation") }}
            </Btn>
          </div>
        </aside>

        <p class="starmap__hint">{{ hint }}</p>
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

.starmap {
  position: relative;
  display: flex;
  flex: 1;
  flex-direction: column;
  min-height: 0;

  &__crumbs {
    position: absolute;
    top: calc($inset + 12px);
    left: 12px;
    right: 12px;
    z-index: $overlay;
    width: fit-content;
    max-width: calc(100% - 24px);
    padding: 6px 12px;
    border-radius: var(--radius-surface-slim);
    background: rgb(8 16 28 / 82%);
    display: flex;
    flex-wrap: wrap;
    align-items: center;
    gap: 6px;
    font-size: 0.875rem;
  }

  &__crumb {
    padding: 0;
    border: 0;
    background: none;
    color: var(--color-primary);
    cursor: pointer;

    &--current {
      color: var(--color-text);
      font-weight: 600;
      cursor: default;
    }
  }

  &__crumb-separator {
    font-size: 0.625rem;
    color: var(--color-text-dim);
  }

  &__stage {
    position: relative;
    flex: 1;
    min-height: 420px;
    background: radial-gradient(circle at 50% 40%, #0d1c30 0%, #050a12 70%);
    overflow: hidden;
    user-select: none;
    touch-action: none;
  }

  &__status {
    position: absolute;
    inset: 0;
    display: flex;
    align-items: center;
    justify-content: center;
    gap: 8px;
    margin: 0;
    color: rgb(255 255 255 / 70%);
    pointer-events: none;
  }

  &__panel {
    position: absolute;
    z-index: $overlay;
    top: calc($inset + 100px);
    bottom: 36px;
    left: 12px;
    width: min(260px, calc(100% - 24px));
    padding: 10px;
    border: 1px solid rgb(90 175 212 / 30%);
    border-radius: var(--radius-surface-slim);
    background: rgb(8 16 28 / 88%);
  }

  &__tools {
    position: absolute;
    z-index: $overlay;
    top: calc($inset + 56px);
    left: 12px;
    display: flex;
    flex-wrap: wrap;
    gap: 8px;
  }

  &__detail {
    position: absolute;
    z-index: $overlay;
    top: calc($inset + 12px);
    right: 12px;
    display: flex;
    flex-direction: column;
    gap: 8px;
    width: min(280px, calc(100% - 24px));
    padding: 14px 16px;
    border: 1px solid rgb(90 175 212 / 30%);
    border-radius: var(--radius-surface-slim);
    background: rgb(8 16 28 / 90%);
    color: rgb(255 255 255 / 85%);
  }

  &__detail-kind {
    font-size: 0.6875rem;
    text-transform: uppercase;
    letter-spacing: 0.06em;
    color: rgb(255 255 255 / 55%);
  }

  &__detail-name {
    margin: 0;
    font-size: 1.125rem;
    color: #fff;
  }

  &__facts {
    display: grid;
    grid-template-columns: auto 1fr;
    gap: 4px 12px;
    margin: 0;
    font-size: 0.8125rem;

    dt {
      color: rgb(255 255 255 / 55%);
    }

    dd {
      margin: 0;
      text-align: right;
    }
  }

  &__detail-actions {
    display: flex;
    flex-wrap: wrap;
    gap: 8px;
  }

  &__hint {
    position: absolute;
    bottom: 10px;
    left: 12px;
    right: 12px;
    margin: 0;
    font-size: 0.75rem;
    color: rgb(255 255 255 / 50%);
    pointer-events: none;
  }

  &__footnote {
    position: absolute;
    bottom: 30px;
    left: 12px;
    right: 12px;
    margin: 0;
    font-size: 0.75rem;
    color: rgb(255 255 255 / 50%);
    pointer-events: none;
  }
}

@media (width <= 767px) {
  .starmap__detail {
    top: auto;
    bottom: 36px;
  }

  .starmap__panel {
    bottom: 36px;
  }
}
</style>
