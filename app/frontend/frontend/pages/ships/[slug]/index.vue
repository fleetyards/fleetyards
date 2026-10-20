<script lang="ts">
export default {
  name: "ShipPage",
};
</script>

<script lang="ts" setup>
import AddToHangar from "@/frontend/components/Models/AddToHangar/index.vue";
import Btn from "@/shared/components/base/Btn/index.vue";
import BtnGroup from "@/shared/components/base/BtnGroup/index.vue";
import ViewInArBtn from "@/frontend/components/Models/ViewInArBtn/index.vue";
import BtnDropdown from "@/shared/components/base/BtnDropdown/index.vue";
import Hardpoints from "@/frontend/components/Models/Hardpoints/index.vue";
import CrewPositions from "@/frontend/components/Models/CrewPositions/index.vue";
import PaintsList from "@/frontend/components/Models/PaintsList/index.vue";
import LoanersList from "@/frontend/components/Models/LoanersList/index.vue";
import OwnersList from "@/frontend/components/Models/OwnersList/index.vue";
import VariantsList from "@/frontend/components/Models/VariantsList/index.vue";
import UpgradesList from "@/frontend/components/Models/UpgradesList/index.vue";
import ModulesList from "@/frontend/components/Models/ModulesList/index.vue";
import {
  useModelModules as useModelModulesQuery,
  type ModelModule,
} from "@/services/fyApi";
import FleetchartImages from "@/frontend/components/Models/FleetchartImages/index.vue";
import ModelBaseMetrics from "@/frontend/components/Models/BaseMetrics/index.vue";
import BreadCrumbs from "@/shared/components/BreadCrumbs/index.vue";
import { type Crumb } from "@/shared/components/BreadCrumbs/types";
import ShareBtn from "@/frontend/components/ShareBtn/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import { useHangarItems } from "@/frontend/composables/useHangarItems";
import { useWishlistItems } from "@/frontend/composables/useWishlistItems";
import { useMetaInfo } from "@/shared/composables/useMetaInfo";
import CarriedByList from "@/frontend/components/Models/CarriedByList/index.vue";
import LazyImage from "@/shared/components/LazyImage/index.vue";
import { useScrollToHash } from "@/shared/composables/useScrollToHash";
import { useMobile } from "@/shared/composables/useMobile";
import { useModelsStore } from "@/frontend/stores/models";
import {
  ModelStateEnum,
  modelStateHolo,
  modelStateMetrics,
  useModelStates,
} from "@/frontend/composables/useModelStates";
import { storeToRefs } from "pinia";
import fallbackImageJpg from "@/images/fallback/store_image.jpg";
import fallbackImage from "@/images/fallback/store_image.webp";
import { useWebpCheck } from "@/shared/composables/useWebpCheck";
import { FeatureFlagName, type ModelExtended } from "@/services/fyApi";
import { useSessionStore } from "@/frontend/stores/session";
import { useFeatures } from "@/frontend/composables/useFeatures";
import {
  BtnSizesEnum,
  BtnVariantsEnum,
} from "@/shared/components/base/Btn/types";
import { useClampedText } from "@/shared/composables/useClampedText";
import starcitizenToolsLogo from "@/images/icons/starcitizentools.svg";
import adiIcon from "@/images/adi_icon.png";
import {
  isLowPowerDevice,
  useLowPowerDevice,
} from "@/shared/composables/useLowPowerDevice";
import { LOW_POWER_HOLO_SIZE_LIMIT } from "@/shared/components/HoloViewer/limits";

// three.js and the viewer are most of a ship page's script. A desktop draws the
// inline preview on every visit, so it starts fetching them straight away; a
// phone only does once the 3D view is opened.
const loadHoloViewer = () => import("@/shared/components/HoloViewer/index.vue");

const HoloViewer = defineAsyncComponent(loadHoloViewer);

if (!isLowPowerDevice()) {
  void loadHoloViewer();
}

type Props = {
  model: ModelExtended;
};

const props = defineProps<Props>();

useHangarItems();
useWishlistItems();

const { t, toDollar } = useI18n();

const { updateMetaInfo } = useMetaInfo();

const { data: modulesData } = useModelModulesQuery(props.model.slug);

const modelModules = computed<ModelModule[]>(
  () => modulesData.value?.items || [],
);

const equippedModules = ref<Record<string, ModelModule | null>>({});

const setEquippedModule = (slotId: string, mod: ModelModule | null) => {
  equippedModules.value = { ...equippedModules.value, [slotId]: mod };
};

provide("modelModules", modelModules);
provide("equippedModules", equippedModules);
provide("setEquippedModule", setEquippedModule);

const moduleCargoHolds = computed(() => {
  return Object.values(equippedModules.value)
    .filter((mod): mod is ModelModule => mod !== null)
    .flatMap((mod) => mod.cargoHolds || []);
});

const combinedCargoHolds = computed(() => [
  ...(props.model.cargoHolds || []),
  ...moduleCargoHolds.value,
]);

const route = useRoute();

const sessionStore = useSessionStore();
const { isFeatureEnabled } = useFeatures();

// Who in the reader's circle flies this ship: there is no circle without an
// account, and it links into the vehicle overview the flag rolls out.
const ownersVisible = computed(
  () =>
    sessionStore.isAuthenticated &&
    isFeatureEnabled(FeatureFlagName.VEHICLE_OVERVIEW),
);

watch(
  () => props.model,
  () => updateTitle,
);

const updateTitle = () => {
  if (!props.model) {
    return;
  }

  updateMetaInfo({
    title: metaTitle.value,
    description: metaDescription.value,
    image: metaImage.value,
    type: "article",
  });
};

const mobile = useMobile();

// On a phone the description sits between the image and the key figures, so it
// is cut to a few lines until asked for.
const descriptionEl = ref<HTMLElement>();
const { expanded: descriptionExpanded, overflows: descriptionOverflows } =
  useClampedText(descriptionEl, () => [
    props.model?.slug,
    props.model?.description,
  ]);

const modelsStore = useModelsStore();

const { holoviewerVisible, modelState } = storeToRefs(modelsStore);

const { availableStates, holoStates, resolveState } = useModelStates(
  () => props.model,
);

// The selection is kept for the session and the next ship may not have the state
// it was left on, so what the page draws is the resolved one, never the raw
// store value.
const activeState = computed(() => resolveState(modelState.value));

const setModelState = (state: ModelStateEnum) => {
  modelsStore.setModelState(state);
};

const { supported: webpSupported } = useWebpCheck();

const storeImage = computed(() => {
  if (mobile.value && props.model?.media.storeImage?.mediumUrl) {
    return props.model?.media.storeImage?.mediumUrl;
  }

  if (props.model?.media.storeImage?.largeUrl) {
    return props.model?.media.storeImage?.largeUrl;
  }

  if (webpSupported) {
    return fallbackImage;
  }

  return fallbackImageJpg;
});

const manufacturerLogo = computed(() => {
  const { logo, icon } = props.model.manufacturer ?? {};

  return icon?.smallUrl || icon?.url || logo?.smallUrl || logo?.url;
});

const metaTitle = computed(() => {
  if (!props.model) {
    return undefined;
  }

  return t("title.ship", {
    name: props.model.name,
    manufacturer: props.model.manufacturer?.name,
  });
});

const metaDescription = computed(() => {
  if (!props.model || !props.model.description) {
    return undefined;
  }

  return props.model.description;
});

const metaImage = computed(() => {
  if (!props.model) {
    return undefined;
  }

  return props.model.media.storeImage?.largeUrl;
});

// Undefined rather than empty: the breadcrumb bar stays hidden until the model
// arrives instead of flashing a lone home crumb.
const crumbs = computed<Crumb[] | undefined>(() => {
  if (!props.model) {
    return undefined;
  }

  return [
    {
      to: {
        name: "ships",
        hash: `#${props.model.slug}`,
      },
      label: t("nav.ships.index"),
    },
  ];
});

const shareUrl = computed(() => window.location.href);

const wikiUrl = computed(() => {
  if (!props.model) {
    return undefined;
  }

  return `https://starcitizen.tools/${props.model.rsiName}`;
});

const price = computed(() => {
  if (!props.model) {
    return undefined;
  }

  return props.model.pledgePrice;
});

onMounted(() => {
  updateTitle();

  if (route.query.holoviewer) {
    modelsStore.holoviewerVisible = true;
  }
});

useScrollToHash();

// Quick Look converts the holo in the page, so no 3D view may hold a second copy
// meanwhile -- the inline preview included, which takes over the side column on
// a tablet as soon as the main view closes.
const quickLookOpen = ref(false);

const openingQuickLook = () => {
  quickLookOpen.value = true;
  modelsStore.holoviewerVisible = false;
};

const closedQuickLook = () => {
  quickLookOpen.value = false;
};

watch(
  () => props.model.slug,
  () => {
    quickLookOpen.value = false;
  },
);

const toggleHoloviewer = () => {
  modelsStore.toggleHoloviewer();
};

const lowPower = useLowPowerDevice();

// Decided once: `lowPower` follows the window width, and a resize across the
// breakpoint should change the render settings, not download the other file.
const preferLiteHolo = isLowPowerDevice();

const texturedHolo = ref(false);

// Only the flying pose has a painted export, so another state leaves the switch
// out rather than offering a button that changes nothing.
const texturedHoloAvailable = computed(
  () =>
    isFeatureEnabled(FeatureFlagName.HOLO_TEXTURED) &&
    activeState.value === ModelStateEnum.FLIGHT &&
    !!props.model.media.holoTextured,
);

const toggleTexturedHolo = () => {
  texturedHolo.value = !texturedHolo.value;
};

const holoModel = computed(() => {
  const textured = texturedHoloAvailable.value && texturedHolo.value;
  const holo = textured
    ? props.model.media.holoTextured
    : modelStateHolo(props.model, activeState.value, { lite: preferLiteHolo });
  const path = holo?.url;
  const length = modelStateMetrics(
    props.model,
    activeState.value,
  ).fleetchartLength;

  if (!path || !length) {
    return;
  }

  return {
    path,
    length,
    size: holo?.size,
    textured,
  };
});

// The side preview cannot ask before loading a holo too large for the device,
// so on such a device it stays the store image; the main 3D view still asks.
const inlinePreview = computed(
  () =>
    !!holoModel.value &&
    !mobile.value &&
    !(
      lowPower.value && (holoModel.value.size ?? 0) > LOW_POWER_HOLO_SIZE_LIMIT
    ),
);

const adiMap = computed(() => {
  if (!props.model.adiMap || !props.model.scIdentifier) {
    return;
  }

  return `https://maps.adi.sc/?ship=${props.model.scIdentifier}`;
});
</script>

<template>
  <div class="row">
    <div class="col-12">
      <div class="row">
        <div class="col-12">
          <BreadCrumbs :crumbs="crumbs" />
          <h1 class="headline" data-test="model-headline">
            {{ model.name }}
            <small class="text-muted manufacturer">
              <span class="manufacturer-prefix">from</span>
              <span>{{ model.manufacturer?.name }}</span>
              <img
                v-if="manufacturerLogo"
                :src="manufacturerLogo"
                class="manufacturer-logo"
                alt="manufacturer-logo"
              />
            </small>
          </h1>
        </div>
      </div>
      <div class="row ship-hero">
        <div class="col-12 col-lg-8 ship-detail-left-col">
          <div
            :class="{
              'image-wrapper-holoviewer': holoviewerVisible,
            }"
            class="image-wrapper"
          >
            <div v-if="holoStates.length" class="image-toolbar">
              <BtnGroup>
                <Btn
                  v-if="holoviewerVisible"
                  :to="{
                    name: 'ship-viewer',
                    params: {
                      slug: model.slug,
                    },
                  }"
                  v-tooltip="t('labels.openInNewWindow')"
                >
                  <i class="fa-light fa-external-link-alt" />
                </Btn>
                <Btn :active="holoviewerVisible" @click="toggleHoloviewer">
                  {{ t("labels.3dView") }}
                </Btn>

                <Btn
                  v-if="holoviewerVisible && texturedHoloAvailable"
                  :active="texturedHolo"
                  data-test="model-holo-textured"
                  @click="toggleTexturedHolo"
                >
                  {{ t("labels.texturedHolo") }}
                </Btn>

                <Btn v-if="adiMap" :href="adiMap">
                  <img :src="adiIcon" class="adi-icon" />
                  {{ t("labels.3dMap") }}
                </Btn>

                <ViewInArBtn
                  :model="model"
                  :active="holoviewerVisible"
                  :displayed-holo-url="holoModel?.path"
                  @quick-look="openingQuickLook"
                  @quick-look-end="closedQuickLook"
                />
              </BtnGroup>

              <!-- Earned by a second holo: a state that differs in the views
                   alone is switched where the views are. Once the switch is
                   here it offers every state the model has, so both switches
                   read the same -- one of them showing no selection at all
                   because the chosen state has no holo of its own is worse than
                   a segment that only moves the dimensions.
                   A phone has no inline preview, so there the switch waits for
                   the holo to open and folds into a menu beside the 3D group. -->
              <BtnDropdown
                v-if="holoStates.length > 1 && mobile && holoviewerVisible"
                data-test="model-holo-states-menu"
              >
                <template #label>
                  <span>{{ t(`labels.model.state.${activeState}`) }}</span>
                  <i class="fa-light fa-chevron-down" />
                </template>
                <Btn
                  v-for="holoState in availableStates"
                  :key="holoState"
                  :active="activeState === holoState"
                  :data-test="`model-holo-state-${holoState}`"
                  @click="setModelState(holoState)"
                >
                  {{ t(`labels.model.state.${holoState}`) }}
                </Btn>
              </BtnDropdown>
              <BtnGroup
                v-else-if="holoStates.length > 1 && !mobile"
                segmented
                data-test="model-holo-states"
              >
                <Btn
                  v-for="holoState in availableStates"
                  :key="holoState"
                  :active="activeState === holoState"
                  :data-test="`model-holo-state-${holoState}`"
                  @click="setModelState(holoState)"
                >
                  {{ t(`labels.model.state.${holoState}`) }}
                </Btn>
              </BtnGroup>
            </div>

            <HoloViewer
              v-if="holoviewerVisible && holoModel"
              :models="[holoModel]"
            />
            <LazyImage v-else :src="storeImage" class="image" />
          </div>
          <div class="row production-status">
            <div class="col-6">
              <template v-if="model.productionStatus">
                <h3 class="text-uppercase">
                  {{
                    t(`labels.model.productionStatus.${model.productionStatus}`)
                  }}
                </h3>
                <p>{{ model.productionNote }}</p>
              </template>
            </div>
            <div class="col-6">
              <template v-if="model.focus">
                <h3 class="text-uppercase text-right">
                  <small class="text-muted">{{ t("model.focus") }}:</small>
                  {{ model.focus }}
                </h3>
              </template>
            </div>
          </div>
          <blockquote class="description">
            <!-- eslint-disable-next-line vue/no-v-html -->
            <p
              ref="descriptionEl"
              :class="{
                'description-clamped': mobile && !descriptionExpanded,
              }"
              v-html="model.description"
            />
            <Btn
              v-if="mobile && (descriptionOverflows || descriptionExpanded)"
              :variant="BtnVariantsEnum.BARE"
              :size="BtnSizesEnum.SM"
              :aria-expanded="descriptionExpanded"
              class="description-toggle"
              @click="descriptionExpanded = !descriptionExpanded"
            >
              {{
                descriptionExpanded
                  ? t("actions.readLess")
                  : t("actions.readMore")
              }}
            </Btn>
          </blockquote>
        </div>
        <div class="col-12 col-lg-4 ship-hero__side">
          <template v-if="inlinePreview && holoModel">
            <LazyImage
              v-if="holoviewerVisible || quickLookOpen"
              :src="storeImage"
              class="side-image"
            />
            <HoloViewer
              v-else
              :models="[holoModel]"
              :controllable="false"
              inline
            />
          </template>
          <ModelBaseMetrics :model="model" :state="activeState" />
          <OwnersList v-if="ownersVisible" :model="model" />
          <div class="page-actions page-actions-block">
            <Btn
              v-if="model.onSale && price"
              :href="`${model.links?.storeUrl}#buying-options`"
              style="flex-grow: 3"
            >
              {{
                t("actions.model.onSale", {
                  price: toDollar(price),
                })
              }}
              <small class="price-info">
                {{ t("labels.taxExcluded") }}
              </small>
            </Btn>
            <Btn v-else :href="model.links?.storeUrl" style="flex-grow: 3">
              {{ t("actions.model.store") }}
            </Btn>

            <AddToHangar :model="model" :size="BtnSizesEnum.SM" />

            <ShareBtn
              v-if="!mobile"
              data-test="share"
              :url="shareUrl"
              :title="metaTitle || ''"
              :size="BtnSizesEnum.SM"
            />

            <BtnDropdown data-test="model-dropdown">
              <Btn
                v-if="model.hasImages"
                :to="{
                  name: 'ship-images',
                  params: { slug: model.slug },
                }"
              >
                <i class="fa fa-images" />
                <span>{{ t("nav.images") }}</span>
              </Btn>
              <Btn
                v-if="model.hasVideos"
                :to="{
                  name: 'ship-videos',
                  params: { slug: model.slug },
                }"
              >
                <i class="fa-light fa-video" />
                <span>{{ t("nav.videos") }}</span>
              </Btn>
              <Btn
                :to="{
                  name: 'ship-history',
                  params: { slug: model.slug },
                }"
              >
                <i class="fa-light fa-clock-rotate-left" />
                <span>{{ t("nav.shipHistory") }}</span>
              </Btn>
              <Btn
                v-if="model.media.brochure?.url"
                :href="model.media.brochure.url"
              >
                <i class="fa-light fa-download" />
                <span>{{ t("labels.model.brochure") }}</span>
              </Btn>
              <Btn
                :to="{
                  name: 'compare',
                  query: { models: [model.slug] },
                }"
                data-test="compare"
              >
                <i class="fa-light fa-code-compare" />
                <span>{{ t("actions.compare.ships") }}</span>
              </Btn>
              <ShareBtn
                v-if="mobile"
                data-test="share"
                :url="shareUrl"
                :title="metaTitle || ''"
                :size="BtnSizesEnum.SM"
              />
              <Btn
                v-if="model.links?.salesPageUrl"
                :href="model.links?.salesPageUrl"
              >
                <i class="fa-duotone fa-megaphone" />
                <span>{{ t("labels.model.salesPage") }}</span>
              </Btn>
              <Btn :href="wikiUrl">
                <img :src="starcitizenToolsLogo" alt="Starcitizen.tools" />
                <span>{{ t("labels.model.wiki") }}</span>
              </Btn>
            </BtnDropdown>
          </div>
        </div>
        <!-- Beside the hero once there is room for a third column, under it
             before. -->
        <div class="col-12 ship-hero__views">
          <FleetchartImages
            :model="model"
            :state="activeState"
            @update:state="setModelState"
          />
        </div>
      </div>
      <hr />
      <Hardpoints :model="model" :cargo-holds="combinedCargoHolds" />
      <CrewPositions :model="model" />
    </div>
  </div>

  <PaintsList :model-slug="model.slug" :model-name="model.name" />
  <ModulesList
    :model-slug="model.slug"
    :model-name="model.name"
    :modules="modelModules"
  />
  <UpgradesList :model-slug="model.slug" :model-name="model.name" />
  <CarriedByList :carried-by="model.carriedBy" />
  <LoanersList :model-slug="model.slug" :model-name="model.name" />
  <VariantsList :model-slug="model.slug" :model-name="model.name" />
</template>

<style lang="scss" scoped>
@import "index";
</style>
