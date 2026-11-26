<script lang="ts">
export default {
  name: "ViewInArBtn",
};
</script>

<script lang="ts" setup>
import BetaBadge from "@/shared/components/BetaBadge/index.vue";
import Btn from "@/shared/components/base/Btn/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";
import {
  isIPhone,
  mayHaveAr,
  openQuickLook as presentQuickLook,
  openQuickLookFile,
  prepareAr,
  usesQuickLook,
  type ModelViewerElement,
} from "@/frontend/utils/arViewer";
import { FeatureFlagName, type Model, type ModelMedia } from "@/services/fyApi";
import { useFeatures } from "@/frontend/composables/useFeatures";

type Props = {
  model: Model;
  // The 3D view is open. Only then is the viewer fetched: the holo is being
  // downloaded for it anyway, and a page view costs nothing extra.
  active?: boolean;
  // The holo the 3D view is showing, so AR places the same pose.
  displayedHoloUrl?: string;
};

const props = withDefaults(defineProps<Props>(), {
  active: false,
  displayedHoloUrl: undefined,
});

const emit = defineEmits<{
  // Quick Look is about to convert the holo in the page. The 3D view holds a
  // second copy of it on the GPU, and an iPhone runs out of memory with both.
  quickLook: [];
  // Quick Look has opened or failed: the page may draw 3D again.
  quickLookEnd: [];
}>();

const { t } = useI18n();

const { displayAlert } = useAppNotifications();

const viewer = shallowRef<ModelViewerElement>();

const quickLook = usesQuickLook();

// Quick Look prepares on the tap, so the button stands on the cheap check alone.
const deferred = ref(false);

type ArPose = {
  holo: keyof ModelMedia;
  holoLite: keyof ModelMedia;
  usdz: keyof ModelMedia;
};

// Every pose comes out of one export in the same units, so the flight holo's
// measurement vouches for all of them. A lite holo is the same hull minus the
// interior, and a phone converts the lighter file.
const AR_POSES: ArPose[] = [
  { holo: "holo", holoLite: "holoLite", usdz: "holoUsdz" },
  { holo: "landedHolo", holoLite: "landedHoloLite", usdz: "landedHoloUsdz" },
  {
    holo: "extendedHolo",
    holoLite: "extendedHoloLite",
    usdz: "extendedHoloUsdz",
  },
];

const shownPose = computed(() =>
  AR_POSES.find((pose) =>
    [pose.holo, pose.holoLite].some((key) => {
      const url = props.model.media[key]?.url;

      return !!url && url === props.displayedHoloUrl;
    }),
  ),
);

const holoUrl = computed(() =>
  shownPose.value ? props.displayedHoloUrl : undefined,
);

// Built for the pose, so it stands for its holo and its lite export alike.
const usdzUrl = computed(() =>
  shownPose.value ? props.model.media[shownPose.value.usdz]?.url : undefined,
);

// Without a USDZ built ahead of time the page would convert the holo, which an
// iPhone cannot hold, so there it offers no Quick Look at all.
const quickLookReady = computed(
  () => !quickLook || !!usdzUrl.value || !isIPhone(),
);

// Only a holo exported in meters can be placed at true size.
const { isFeatureEnabled } = useFeatures();

const candidate = computed(
  () =>
    isFeatureEnabled(FeatureFlagName.HOLO_AR) &&
    props.active &&
    !!holoUrl.value &&
    !!props.model.holoToScale &&
    quickLookReady.value &&
    mayHaveAr(),
);

// Counts preparations, so one that finishes after a newer one started (another
// ship's holo) is thrown away rather than replacing the current viewer.
let preparation = 0;

const prepare = async () => {
  const current = ++preparation;

  viewer.value?.remove();
  viewer.value = undefined;
  deferred.value = false;

  if (!candidate.value || !holoUrl.value) {
    return;
  }

  if (quickLook) {
    deferred.value = true;
    return;
  }

  const prepared = await prepareAr(holoUrl.value).catch(() => undefined);

  if (current !== preparation) {
    prepared?.remove();
    return;
  }

  viewer.value = prepared;
};

onMounted(prepare);

// The whole condition, so the flag loading in or being switched counts too.
watch([holoUrl, candidate], prepare);

let unmounted = false;

onBeforeUnmount(() => {
  unmounted = true;
  preparation += 1;
  viewer.value?.remove();
});

const failed = () => {
  displayAlert({ text: t("messages.error.default") });
};

const opening = ref(false);

const nextFrame = () =>
  new Promise((resolve) => requestAnimationFrame(() => resolve(undefined)));

// The 3D view goes first, and the holo is loaded for Quick Look only once it is
// gone: the two copies together are more than an iPhone holds.
const openQuickLook = async (url: string) => {
  opening.value = true;

  emit("quickLook");
  await nextTick();
  await nextFrame();

  // Left, or moved on to another ship: the tap was for a holo no longer on
  // screen.
  const wanted = () => !unmounted && url === holoUrl.value;

  try {
    await presentQuickLook(url, wanted);
  } catch {
    if (wanted()) failed();
  } finally {
    opening.value = false;
    emit("quickLookEnd");
  }
};

// Scene Viewer straight from the tap, without awaiting anything first: it only
// opens from a user gesture.
const open = () => {
  if (opening.value) return;

  if (deferred.value && usdzUrl.value) {
    openQuickLookFile(usdzUrl.value);
    return;
  }

  if (deferred.value && holoUrl.value) {
    void openQuickLook(holoUrl.value);
    return;
  }

  viewer.value?.activateAR().catch(failed);
};
</script>

<template>
  <Btn
    v-if="viewer || deferred || opening"
    v-tooltip="t('labels.viewInArHint')"
    :aria-label="t('labels.viewInArHint')"
    :loading="opening"
    :disabled="opening"
    data-test="view-in-ar"
    @click="open"
  >
    <i class="fa-light fa-cube" />
    {{ t("labels.viewInAr") }}
    <BetaBadge :feature="FeatureFlagName.HOLO_AR" in-control />
  </Btn>
</template>
