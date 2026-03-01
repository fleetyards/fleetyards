<script lang="ts">
export default {
  name: "ShipPage",
};
</script>

<script lang="ts" setup>
import AddToHangar from "@/frontend/components/Models/AddToHangar/index.vue";
import Btn from "@/shared/components/base/Btn/index.vue";
import BtnGroup from "@/shared/components/base/BtnGroup/index.vue";
import BtnDropdown from "@/shared/components/base/BtnDropdown/index.vue";
import Hardpoints from "@/frontend/components/Models/Hardpoints/index.vue";
import PaintsList from "@/frontend/components/Models/PaintsList/index.vue";
import LoanersList from "@/frontend/components/Models/LoanersList/index.vue";
import VariantsList from "@/frontend/components/Models/VariantsList/index.vue";
import UpgradesList from "@/frontend/components/Models/UpgradesList/index.vue";
import ModulesList from "@/frontend/components/Models/ModulesList/index.vue";
import FleetchartImages from "@/frontend/components/Models/FleetchartImages/index.vue";
import ModelBaseMetrics from "@/frontend/components/Models/BaseMetrics/index.vue";
import ModelCrewMetrics from "@/frontend/components/Models/CrewMetrics/index.vue";
import ModelSpeedMetrics from "@/frontend/components/Models/SpeedMetrics/index.vue";
import BreadCrumbs from "@/shared/components/BreadCrumbs/index.vue";
import HoloViewer, {
  HoloModel,
} from "@/shared/components/HoloViewer/index.vue";
import ShareBtn from "@/frontend/components/ShareBtn/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import { useHangarItems } from "@/frontend/composables/useHangarItems";
import { useWishlistItems } from "@/frontend/composables/useWishlistItems";
import { useMetaInfo } from "@/shared/composables/useMetaInfo";
import Panel from "@/shared/components/base/Panel/index.vue";
import LazyImage from "@/shared/components/LazyImage/index.vue";
import { useMobile } from "@/shared/composables/useMobile";
import { useModelsStore } from "@/frontend/stores/models";
import { storeToRefs } from "pinia";
import fallbackImageJpg from "@/images/fallback/store_image.jpg";
import fallbackImage from "@/images/fallback/store_image.webp";
import { useWebpCheck } from "@/shared/composables/useWebpCheck";
import { type Model } from "@/services/fyApi";
import { BtnSizesEnum } from "@/shared/components/base/Btn/types";
import starcitizenToolsLogo from "@/images/icons/starcitizentools.svg";
import { useComlink } from "@/shared/composables/useComlink";
import adiIcon from "@/images/adi_icon.png";

type Props = {
  model: Model;
};

const props = defineProps<Props>();

useHangarItems();
useWishlistItems();

const { t, toDollar } = useI18n();

const { updateMetaInfo } = useMetaInfo();

const route = useRoute();

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

const modelsStore = useModelsStore();

const { holoviewerVisible } = storeToRefs(modelsStore);

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

const crumbs = computed(() => {
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

  setTimeout(() => {
    scrollToHash();
  }, 500);
});

const scrollToHash = () => {
  if (!route.hash) {
    return;
  }

  const el = document.querySelector(route.hash);

  if (!el) {
    return;
  }

  el.scrollIntoView({
    behavior: "instant",
    block: "start",
  });
};

const toggleHoloviewer = () => {
  modelsStore.toggleHoloviewer();
};

const comlink = useComlink();

const openHoloviewerModal = () => {
  modelsStore.toggleHoloviewer();

  comlink.emit("open-modal", {
    component: () => import("@/shared/components/HoloViewer/Modal/index.vue"),
    fullscreen: true,
    props: {
      paths: [props.model.media.holo?.url],
    },
  });
};

const holoModel = computed(() => {
  if (!props.model.media.holo || !props.model.metrics.fleetchartOffsetLength) {
    return;
  }

  return {
    path: props.model.media.holo?.url,
    length: props.model.metrics.fleetchartOffsetLength,
  };
});

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
          <h1 class="headline">
            {{ model.name }}
            <small class="text-muted manufacturer">
              <span class="manufacturer-prefix">from</span>
              <span>{{ model.manufacturer?.name }}</span>
              <img
                v-if="model.manufacturer && model.manufacturer.logo"
                v-lazy="model.manufacturer.logo"
                class="manufacturer-logo"
                alt="manufacturer-logo"
              />
            </small>
          </h1>
        </div>
      </div>
      <div class="row">
        <div class="col-12 col-lg-8 ship-detail-left-col">
          <div
            :class="{
              'image-wrapper-holoviewer': holoviewerVisible,
            }"
            class="image-wrapper"
          >
            <BtnGroup class="toggle-3d" v-if="model.media.holo">
              <Btn
                v-if="holoviewerVisible"
                :size="BtnSizesEnum.SMALL"
                :to="{
                  name: 'ship-viewer',
                  params: {
                    slug: model.slug,
                  },
                }"
                v-tooltip="t('labels.openInNewWindow')"
              >
                <i class="fal fa-external-link-alt" />
              </Btn>
              <Btn
                :active="holoviewerVisible"
                :size="BtnSizesEnum.SMALL"
                @click="toggleHoloviewer"
              >
                {{ t("labels.3dView") }}
              </Btn>

              <Btn v-if="adiMap" :size="BtnSizesEnum.SMALL" :href="adiMap">
                <img :src="adiIcon" class="adi-icon" />
                {{ t("labels.3dMap") }}
              </Btn>
            </BtnGroup>

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
            <p v-html="model.description" />
          </blockquote>
        </div>
        <div class="col-12 col-lg-4">
          <template v-if="holoModel && !mobile">
            <LazyImage
              v-if="holoviewerVisible"
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
          <Panel slim>
            <ModelBaseMetrics :model="model" />
          </Panel>
          <Panel slim>
            <ModelCrewMetrics :model="model" />
          </Panel>
          <Panel slim>
            <ModelSpeedMetrics :model="model" />
          </Panel>
          <div class="page-actions page-actions-block">
            <Btn
              v-if="model.onSale && price"
              :href="`${model.links.storeUrl}#buying-options`"
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
            <Btn v-else :href="model.links.storeUrl" style="flex-grow: 3">
              {{ t("actions.model.store") }}
            </Btn>

            <AddToHangar :model="model" :size="BtnSizesEnum.SMALL" />

            <ShareBtn
              v-if="!mobile"
              data-test="share"
              :url="shareUrl"
              :title="metaTitle || ''"
              :size="BtnSizesEnum.SMALL"
            />

            <BtnDropdown data-test="model-dropdown" :size="BtnSizesEnum.SMALL">
              <Btn
                v-if="model.hasImages"
                :to="{
                  name: 'ship-images',
                  params: { slug: model.slug },
                }"
                :size="BtnSizesEnum.SMALL"
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
                :size="BtnSizesEnum.SMALL"
              >
                <i class="fal fa-video" />
                <span>{{ t("nav.videos") }}</span>
              </Btn>
              <Btn
                v-if="model.media.brochure?.url"
                :href="model.media.brochure.url"
                :size="BtnSizesEnum.SMALL"
              >
                <i class="fal fa-download" />
                <span>{{ t("labels.model.brochure") }}</span>
              </Btn>
              <Btn
                :to="{
                  name: 'compare',
                  query: { models: [model.slug] },
                }"
                data-test="compare"
                :size="BtnSizesEnum.SMALL"
              >
                <i class="fal fa-code-compare" />
                <span>{{ t("actions.compare.ships") }}</span>
              </Btn>
              <ShareBtn
                v-if="mobile"
                data-test="share"
                :url="shareUrl"
                :title="metaTitle || ''"
                :size="BtnSizesEnum.SMALL"
              />
              <Btn
                v-if="model.links.salesPageUrl"
                :href="model.links.salesPageUrl"
                :size="BtnSizesEnum.SMALL"
              >
                <i class="fad fa-megaphone" />
                <span>{{ t("labels.model.salesPage") }}</span>
              </Btn>
              <Btn :href="wikiUrl" :size="BtnSizesEnum.SMALL">
                <img :src="starcitizenToolsLogo" alt="Starcitizen.tools" />
                <span>{{ t("labels.model.wiki") }}</span>
              </Btn>
            </BtnDropdown>
          </div>
        </div>
      </div>
      <FleetchartImages :model="model" />
      <hr />
      <Hardpoints :model="model" />
    </div>
  </div>

  <PaintsList :model-slug="model.slug" />
  <ModulesList :model-slug="model.slug" />
  <UpgradesList :model-slug="model.slug" />
  <VariantsList :model-slug="model.slug" />
  <LoanersList :model-slug="model.slug" />
</template>

<style lang="scss" scoped>
@import "index";
</style>
