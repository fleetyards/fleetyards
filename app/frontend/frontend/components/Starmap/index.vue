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
import {
  bodyScene,
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
// back button steps out a level.
const queryValue = (value: unknown) =>
  typeof value === "string" && value ? value : null;

const systemSlug = computed(() => queryValue(route.query.system));
const bodySlug = computed(() =>
  systemSlug.value ? queryValue(route.query.body) : null,
);

const navigate = (system: string | null, body: string | null = null) => {
  const query: Record<string, string> = {};
  if (system) query.system = system;
  if (system && body) query.body = body;

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
  if (!places) return null;

  if (bodySlug.value) return bodyScene(places, bodySlug.value);

  return systemScene(places);
});

const empty = computed(
  () => !loading.value && !!scene.value && scene.value.items.length === 0,
);

const bodyName = computed(
  () =>
    starmap.value?.places.find((place) => place.slug === bodySlug.value)
      ?.name ?? bodySlug.value,
);

const crumbs = computed(() => {
  const list: { key: string; label: string; go?: () => void }[] = [
    {
      key: "systems",
      label: t("starmap.systems"),
      go: systemSlug.value ? () => navigate(null) : undefined,
    },
  ];

  if (systemSlug.value) {
    list.push({
      key: "system",
      label: starmap.value?.system.name ?? systemSlug.value,
      go: bodySlug.value ? () => navigate(systemSlug.value) : undefined,
    });
  }

  if (bodySlug.value) {
    list.push({ key: "body", label: bodyName.value ?? "" });
  }

  return list;
});

const selectedKey = ref<string | null>(null);

const levelKey = computed(() =>
  [systemSlug.value, bodySlug.value].filter(Boolean).join("/"),
);

// Whichever way the level changed -- a crumb, a double-click or the browser's
// back button -- what was picked on the last one does not carry over.
watch(levelKey, () => {
  selectedKey.value = null;
});

const selected = computed(
  () =>
    scene.value?.items.find((entry) => entry.key === selectedKey.value) ?? null,
);

const onSelect = (entry: StarmapItem | null) => {
  selectedKey.value = entry?.key ?? null;
};

const enter = (entry: StarmapItem) => {
  if (entry.role === "system") {
    navigate(entry.slug);
  } else if (systemSlug.value) {
    navigate(systemSlug.value, entry.slug);
  }
};

const sceneRef = ref<InstanceType<typeof StarmapScene> | null>(null);

const resetView = () => sceneRef.value?.frame();

// Metres, in the largest unit that keeps the number readable: a planet's
// radius reads as 1,000 km rather than 1 Mm.
const formatLength = (metres: number) => {
  if (metres >= 1e9)
    return t("starmap.units.gm", { value: toNumber(metres / 1e9) });
  if (metres >= 1e7)
    return t("starmap.units.mm", { value: toNumber(metres / 1e6) });

  return t("starmap.units.km", { value: toNumber(metres / 1e3) });
};

const facts = computed(() => {
  const entry = selected.value;
  if (!entry) return [];

  const list: { key: string; label: string; value: string }[] = [];

  if (entry.parentName) {
    list.push({
      key: "parent",
      label: t("starmap.parent"),
      value: entry.parentName,
    });
  }

  if (entry.distance) {
    list.push({
      key: "distance",
      label: bodySlug.value
        ? t("starmap.distanceBody")
        : t("starmap.distanceStar"),
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

const hint = computed(() => {
  if (!systemSlug.value) return t("starmap.hints.systems");

  return t("starmap.hints.system");
});
</script>

<template>
  <div class="starmap">
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

    <div class="starmap__stage">
      <TresCanvas
        v-if="webglSupported"
        :clear-alpha="0"
        :shadows="false"
        :dpr="dpr"
        :power-preference="mobile ? 'low-power' : 'default'"
        alpha
      >
        <TresPerspectiveCamera
          :position="[0, 30, 50]"
          :args="[50, 1, 0.01, 10000]"
        />
        <OrbitControls
          enable-damping
          :damping-factor="0.08"
          :zoom-speed="0.8"
          :enable-pan="true"
          make-default
        />
        <StarmapScene
          v-if="scene"
          ref="sceneRef"
          :scene="scene"
          :level-key="levelKey"
          :selected-key="selectedKey"
          @select="onSelect"
          @enter="enter"
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

      <div v-if="webglSupported" class="starmap__tools">
        <Btn size="sm" data-test="starmap-reset" @click="resetView">
          <i class="fa-light fa-arrows-to-circle" aria-hidden="true" />
          {{ t("starmap.reset") }}
        </Btn>
      </div>

      <aside
        v-if="selected"
        class="starmap__detail"
        data-test="starmap-detail"
        :aria-label="selected.name"
      >
        <span class="starmap__detail-kind">
          {{ t(`labels.location.kinds.${selected.kind}`) }}
        </span>
        <h2 class="starmap__detail-name">{{ selected.name }}</h2>

        <dl v-if="facts.length" class="starmap__facts">
          <template v-for="fact in facts" :key="fact.key">
            <dt>{{ fact.label }}</dt>
            <dd>{{ fact.value }}</dd>
          </template>
        </dl>

        <div class="starmap__detail-actions">
          <Btn
            v-if="selected.enterable"
            size="sm"
            data-test="starmap-enter"
            @click="enter(selected)"
          >
            <i class="fa-light fa-magnifying-glass-plus" aria-hidden="true" />
            {{ t("starmap.enter", { name: selected.name }) }}
          </Btn>
          <Btn
            size="sm"
            variant="ghost"
            :to="{ name: 'location', params: { slug: selected.slug } }"
            data-test="starmap-location-link"
          >
            {{ t("starmap.openLocation") }}
          </Btn>
        </div>
      </aside>

      <p class="starmap__hint">{{ hint }}</p>
    </div>

    <p v-if="!systemSlug" class="starmap__footnote">
      {{ t("starmap.footnote") }}
    </p>
  </div>
</template>

<style lang="scss" scoped>
.starmap {
  display: flex;
  flex-direction: column;
  gap: 12px;

  &__crumbs {
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
    height: calc(100vh - 240px);
    min-height: 420px;
    border: 1px solid var(--color-edge-soft);
    border-radius: var(--radius-surface-slim);
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

  &__tools {
    position: absolute;
    top: 12px;
    left: 12px;
  }

  &__detail {
    position: absolute;
    top: 12px;
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
    margin: 0;
    font-size: 0.8125rem;
    color: var(--color-text-dim);
  }
}

@media (width <= 767px) {
  .starmap__detail {
    top: auto;
    bottom: 36px;
  }
}
</style>
