<script lang="ts">
export default {
  name: "ModelsFleetchartImages",
};
</script>

<script lang="ts" setup>
import { useMobile } from "@/shared/composables/useMobile";
import { useI18n } from "@/shared/composables/useI18n";
import Btn from "@/shared/components/base/Btn/index.vue";
import BtnGroup from "@/shared/components/base/BtnGroup/index.vue";
import Loader from "@/shared/components/Loader/index.vue";
import {
  ModelStateEnum,
  ModelViewEnum,
  modelStateMetrics,
  modelStateShowsRearViews,
  modelStateView,
  useModelStates,
} from "@/frontend/composables/useModelStates";

import type { Model, MediaFile } from "@/services/fyApi";

type Props = {
  model: Model;
  state?: ModelStateEnum;
  // Starts as the angled view alone, which opens the rest when tapped.
  collapsible?: boolean;
};

const props = withDefaults(defineProps<Props>(), {
  state: ModelStateEnum.FLIGHT,
  collapsible: false,
});

const emit = defineEmits<{
  (e: "update:state", value: ModelStateEnum): void;
}>();

const { t } = useI18n();

const mobile = useMobile();

const { availableStates } = useModelStates(() => props.model);

const setState = (value: ModelStateEnum) => {
  emit("update:state", value);
};

const pickViewUrl = (
  colored: MediaFile | undefined,
  regular: MediaFile | undefined,
) => {
  if (colored) {
    return mobile.value ? colored.mediumUrl : colored.largeUrl;
  }

  if (mobile.value && regular?.mediumUrl) {
    return regular.mediumUrl;
  }

  return regular?.largeUrl;
};

const viewUrl = (view: ModelViewEnum) => {
  const { colored, regular } = modelStateView(props.model, props.state, view);

  return pickViewUrl(colored, regular);
};

// Each set is drawn in the same four cells, and each cell sizes its view the
// same way: the plan view (top, bottom) and the profile (port, starboard) span
// the ship's length, and the end-on view (front, rear) is held to the height of
// the profile beside it.
type ViewSet = {
  key: string;
  angled: ModelViewEnum;
  plan: ModelViewEnum;
  end: ModelViewEnum;
  profile: ModelViewEnum;
};

const VIEW_SETS: ViewSet[] = [
  {
    key: "front",
    angled: ModelViewEnum.ANGLED,
    plan: ModelViewEnum.TOP,
    end: ModelViewEnum.FRONT,
    profile: ModelViewEnum.PORT,
  },
  {
    key: "rear",
    angled: ModelViewEnum.ANGLED_REAR,
    plan: ModelViewEnum.BOTTOM,
    end: ModelViewEnum.REAR,
    profile: ModelViewEnum.STARBOARD,
  },
];

const viewSets = computed(() =>
  VIEW_SETS.filter(
    (set) =>
      set.key !== "rear" || modelStateShowsRearViews(props.model, props.state),
  )
    .map((set) => ({
      key: set.key,
      angled: viewUrl(set.angled),
      plan: viewUrl(set.plan),
      end: viewUrl(set.end),
      profile: viewUrl(set.profile),
    }))
    .filter((set) => set.angled || set.plan || set.end || set.profile),
);

const hasImages = computed(() => viewSets.value.length > 0);

// A phone has no other state switch, so a ship without views still gets this one.
const visible = computed(
  () =>
    hasImages.value || (props.collapsible && availableStates.value.length > 1),
);

const expanded = ref(false);

const frontAngled = computed(
  () => viewSets.value.find((set) => set.key === "front")?.angled,
);

// A ship without an angled view has nothing to fold behind, so it shows them all.
const foldable = computed(() => props.collapsible && !!frontAngled.value);

const collapsed = computed(() => foldable.value && !expanded.value);

// The coloured views run to several megabytes each, so switching state leaves the
// previous set on screen for a beat. Settled by URL rather than by a counter: the
// <img> elements stay put across a switch, so each one reports the file it just
// finished, and an image already in the browser cache reports immediately.
const settledUrls = ref(new Set<string>());

const currentUrls = computed(() =>
  (collapsed.value
    ? [frontAngled.value]
    : viewSets.value.flatMap((set) => [
        set.angled,
        set.plan,
        set.end,
        set.profile,
      ])
  ).filter((url): url is string => Boolean(url)),
);

const loading = computed(() =>
  currentUrls.value.some((url) => !settledUrls.value.has(url)),
);

// Only a switch has a previous set to dim and hold the loader over. On the first
// load the images have no size yet, so the grid is a bare gap and a loader centred
// on it would cover the sections around it.
const firstSetShown = ref(false);

watch(loading, (value) => {
  if (!value) {
    firstSetShown.value = true;
  }
});

// Navigating to another ship can keep this component mounted; its views are a
// first load again unless the browser already has every one of them.
watch(
  () => props.model.id,
  () => {
    expanded.value = false;
    firstSetShown.value = !loading.value;
  },
);

const switching = computed(() => firstSetShown.value && loading.value);

// Unfolding brings in views that were never shown, a first load like any other.
const toggleExpanded = () => {
  expanded.value = !expanded.value;
  firstSetShown.value = !loading.value;
};

// An image that fails settles too, or the loader would sit over a view that is
// never going to arrive.
const settleImage = (event: Event) => {
  const image = event.target as HTMLImageElement;

  // A `load` belonging to the file the switch navigated away from: the element
  // has already been pointed at its replacement, so the src attribute reads as
  // the new file and settling on it would clear the loader over an image still
  // arriving. The element's own `complete` is what knows the difference.
  if (event.type === "load" && !image.complete) {
    return;
  }

  const url = image.getAttribute("src");

  if (!url) {
    return;
  }

  settledUrls.value = new Set(settledUrls.value).add(url);
};

const windowWidth = ref(window.innerWidth / 2);

const maxFleetchartWidth = computed(
  () => windowWidth.value - (windowWidth.value / 100) * 40,
);

const length = computed(() => {
  if (!props.model) {
    return 0;
  }

  if (modelBeam.value > modelLength.value) {
    return (maxFleetchartWidth.value * modelLength.value) / modelBeam.value;
  }

  return maxFleetchartWidth.value;
});

const beam = computed(() => {
  if (!props.model) {
    return 0;
  }

  if (modelLength.value > modelBeam.value) {
    return (maxFleetchartWidth.value * modelBeam.value) / modelLength.value;
  }

  return maxFleetchartWidth.value;
});

const stateMetrics = computed(() =>
  modelStateMetrics(props.model, props.state),
);

const modelLength = computed(() => stateMetrics.value.fleetchartLength || 1);

const modelBeam = computed(() => stateMetrics.value.fleetchartBeam || 1);

const profileImgs: Record<string, HTMLImageElement | null> = {};
const profileHeights = ref<Record<string, number>>({});

const setProfileImg = (key: string, el: unknown) => {
  profileImgs[key] = el as HTMLImageElement | null;
};

const updateProfileHeights = () => {
  profileHeights.value = Object.fromEntries(
    Object.entries(profileImgs)
      .filter(([, img]) => img)
      .map(([key, img]) => [key, img!.clientHeight]),
  );
};

const endStyle = (key: string) => {
  const height = profileHeights.value[key];

  return height ? { maxHeight: `${height}px` } : {};
};

onMounted(() => {
  window.addEventListener("resize", () => {
    windowWidth.value = window.innerWidth / 2;
    updateProfileHeights();
  });
});
</script>

<template>
  <div v-if="visible" class="fleetchart-views-wrapper">
    <BtnGroup
      v-if="availableStates.length > 1"
      segmented
      class="fleetchart-views-toggle"
      data-test="model-states"
    >
      <Btn
        v-for="modelState in availableStates"
        :key="modelState"
        :active="state === modelState"
        :data-test="`model-state-${modelState}`"
        @click="setState(modelState)"
      >
        {{ t(`labels.model.state.${modelState}`) }}
      </Btn>
    </BtnGroup>
    <div
      v-if="hasImages"
      class="fleetchart-views"
      :class="{ 'fleetchart-views--loading': switching }"
    >
      <!-- Announced here rather than inside Loader: it is a leaf component
           mounted without a store in several specs, and useI18n needs pinia. -->
      <!-- Immediate: the views dim at once, and a switch rarely takes the half
           second a loader otherwise waits, so it would never show. -->
      <Loader
        relative
        immediate
        :loading="switching"
        role="status"
        :aria-label="t('labels.loading')"
      />
      <template
        v-for="set in collapsed ? viewSets.slice(0, 1) : viewSets"
        :key="set.key"
      >
        <div class="fleetchart-views__cell">
          <button
            v-if="foldable && set.key === 'front'"
            type="button"
            class="fleetchart-views__fold"
            :aria-expanded="expanded"
            data-test="model-views-fold"
            @click="toggleExpanded"
          >
            <img
              :src="set.angled"
              :width="(length > beam ? length : beam) * 1.2"
              @load="settleImage"
              @error="settleImage"
            />
            <span class="fleetchart-views__fold-label">
              {{
                expanded
                  ? t("actions.model.hideViews")
                  : t("actions.model.showViews")
              }}
              <i
                class="fa-light"
                :class="expanded ? 'fa-chevron-up' : 'fa-chevron-down'"
              />
            </span>
          </button>
          <img
            v-else-if="set.angled"
            :src="set.angled"
            :width="(length > beam ? length : beam) * 1.2"
            @load="settleImage"
            @error="settleImage"
          />
        </div>
        <template v-if="!collapsed">
          <div class="fleetchart-views__cell">
            <img
              v-if="set.plan"
              :src="set.plan"
              :width="length"
              @load="settleImage"
              @error="settleImage"
            />
          </div>
          <div class="fleetchart-views__cell" :class="{ small: mobile }">
            <img
              v-if="set.end"
              :src="set.end"
              :style="endStyle(set.key)"
              @load="settleImage"
              @error="settleImage"
            />
          </div>
          <div class="fleetchart-views__cell">
            <img
              v-if="set.profile"
              :ref="(el) => setProfileImg(set.key, el)"
              :src="set.profile"
              :width="length"
              @load="
                updateProfileHeights();
                settleImage($event);
              "
              @error="settleImage"
            />
          </div>
        </template>
      </template>
    </div>
  </div>
</template>

<style scoped lang="scss">
@import "index.scss";
</style>
