<template>
  <AsyncData :async-status="asyncStatus">
    <template #resolved>
      <div v-if="model" class="row">
        <div class="col-12">
          <div class="row">
            <div class="col-12">
              <BreadCrumbs :crumbs="crumbs" />
              <h1>
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
                <Btn
                  :active="holoviewerVisible"
                  class="toggle-3d"
                  size="small"
                  @click="toggleHoloviewer"
                >
                  {{ t("labels.3dView") }}
                </Btn>
                <a
                  v-show="holoviewerVisible"
                  :href="starship42Url"
                  class="starship42-link"
                  target="_blank"
                  rel="noopener"
                >
                  {{ t("labels.poweredByStarship42") }}
                </a>
                <HoloViewer
                  v-if="holoviewerVisible && model.holo"
                  :holo="model.holo"
                />
                <iframe
                  v-else-if="holoviewerVisible"
                  class="holoviewer"
                  :src="starship42IframeUrl"
                  frameborder="0"
                />
                <LazyImage
                  v-else-if="storeImage"
                  :src="storeImage"
                  class="image"
                />
              </div>
              <div class="row production-status">
                <div class="col-6">
                  <template v-if="model.productionStatus">
                    <h3 class="text-uppercase">
                      {{
                        t(
                          `labels.model.productionStatus.${model.productionStatus}`,
                        )
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
                <p v-html="model.description" />
              </blockquote>
            </div>
            <div class="col-12 col-lg-4">
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
                  v-if="
                    model.onSale && (model.pledgePrice || model.lastPledgePrice)
                  "
                  :href="`${model.storeUrl}#buying-options`"
                  style="flex-grow: 3"
                >
                  {{
                    t("actions.model.onSale", {
                      price: toDollar(
                        model.pledgePrice || model.lastPledgePrice,
                      ),
                    })
                  }}
                  <small class="price-info">
                    {{ t("labels.taxExcluded") }}
                  </small>
                </Btn>
                <Btn v-else :href="model.storeUrl" style="flex-grow: 3">
                  {{ t("actions.model.store") }}
                </Btn>

                <AddToHangar :model="model" />

                <ShareBtn
                  v-if="!mobile"
                  data-test="share"
                  :url="shareUrl"
                  :title="metaTitle || ''"
                />

                <BtnDropdown data-test="model-dropdown">
                  <Btn
                    v-if="model.hasImages"
                    :to="{
                      name: 'model-images',
                      params: { slug: model.slug },
                    }"
                    variant="dropdown"
                  >
                    <i class="fa fa-images" />
                    <span>{{ t("nav.images") }}</span>
                  </Btn>
                  <Btn
                    v-if="model.hasVideos"
                    :to="{
                      name: 'model-videos',
                      params: { slug: model.slug },
                    }"
                    variant="dropdown"
                  >
                    <i class="fal fa-video" />
                    <span>{{ t("nav.videos") }}</span>
                  </Btn>
                  <Btn
                    v-if="model.brochure"
                    :href="model.brochure"
                    variant="dropdown"
                  >
                    <i class="fal fa-download" />
                    <span>{{ t("labels.model.brochure") }}</span>
                  </Btn>
                  <Btn
                    :to="{
                      name: 'models-compare',
                      query: { models: [model.slug] },
                    }"
                    data-test="compare"
                    variant="dropdown"
                  >
                    <i class="fal fa-code-compare" />
                    <span>{{ t("actions.compare.models") }}</span>
                  </Btn>
                  <ShareBtn
                    v-if="mobile"
                    data-test="share"
                    variant="dropdown"
                    :url="shareUrl"
                    :title="metaTitle || ''"
                  />
                  <Btn
                    v-if="model.salesPageUrl"
                    :href="model.salesPageUrl"
                    variant="dropdown"
                  >
                    <i class="fad fa-megaphone" />
                    <span>{{ t("labels.model.salesPage") }}</span>
                  </Btn>
                </BtnDropdown>
              </div>
            </div>
          </div>
          <div class="row">
            <div class="col-12">
              <div class="fleetchart-views">
                <div>
                  <img
                    v-if="fleetchartImageAngled"
                    :src="fleetchartImageAngled"
                  />
                </div>
                <div>
                  <img v-if="fleetchartImageTop" :src="fleetchartImageTop" />
                </div>
                <div class="small">
                  <img
                    v-if="fleetchartImageFront"
                    :src="fleetchartImageFront"
                  />
                </div>
                <div>
                  <img v-if="fleetchartImageSide" :src="fleetchartImageSide" />
                </div>
              </div>
            </div>
          </div>
          <hr />
          <div class="row components">
            <div class="col-12">
              <Hardpoints :model="model" />
            </div>
          </div>
        </div>
      </div>

      <PaintsList v-if="model" :model-slug="model.slug" />
      <ModulesList v-if="model" :model-slug="model.slug" />
      <UpgradesList v-if="model" :model-slug="model.slug" />
      <VariantsList v-if="model" :model-slug="model.slug" />
      <LoanersList v-if="model" :model-slug="model.slug" />
    </template>
  </AsyncData>
</template>

<script lang="ts" setup>
import AsyncData from "@/shared/components/AsyncData.vue";
import AddToHangar from "@/frontend/components/Models/AddToHangar/index.vue";
import Btn from "@/shared/components/base/Btn/index.vue";
import BtnDropdown from "@/shared/components/base/BtnDropdown/index.vue";
import Hardpoints from "@/frontend/components/Models/Hardpoints/index.vue";
import PaintsList from "@/frontend/components/Models/PaintsList/index.vue";
import LoanersList from "@/frontend/components/Models/LoanersList/index.vue";
import VariantsList from "@/frontend/components/Models/VariantsList/index.vue";
import UpgradesList from "@/frontend/components/Models/UpgradesList/index.vue";
import ModulesList from "@/frontend/components/Models/ModulesList/index.vue";
import ModelBaseMetrics from "@/frontend/components/Models/BaseMetrics/index.vue";
import ModelCrewMetrics from "@/frontend/components/Models/CrewMetrics/index.vue";
import ModelSpeedMetrics from "@/frontend/components/Models/SpeedMetrics/index.vue";
import BreadCrumbs from "@/shared/components/BreadCrumbs/index.vue";
import HoloViewer from "@/frontend/components/core/HoloViewer/index.vue";
import ShareBtn from "@/frontend/components/ShareBtn/index.vue";
import { useI18n } from "@/frontend/composables/useI18n";
import { useHangarItems } from "@/frontend/composables/useHangarItems";
import { useWishlistItems } from "@/frontend/composables/useWishlistItems";
import { useMetaInfo } from "@/shared/composables/useMetaInfo";
import Panel from "@/shared/components/Panel/index.vue";
import LazyImage from "@/shared/components/LazyImage/index.vue";
import { useMobile } from "@/shared/composables/useMobile";
import { useModelsStore } from "@/frontend/stores/models";
import { storeToRefs } from "pinia";
import { useQuery } from "@tanstack/vue-query";
import { useApiClient } from "@/frontend/composables/useApiClient";
import fallbackImageJpg from "@/images/fallback/store_image.jpg";
import fallbackImage from "@/images/fallback/store_image.webp";
import { useWebpCheck } from "@/shared/composables/useWebpCheck";

useHangarItems();
useWishlistItems();

const { models: modelsService } = useApiClient();

const route = useRoute();

const slug = computed(() => route.params.slug as string);

const { data: model, ...asyncStatus } = useQuery({
  queryKey: ["models", slug.value],
  queryFn: () =>
    modelsService.model({
      slug: slug.value,
    }),
  retry: false,
});

watch(
  () => model.value,
  () => {
    if (!model.value) {
      return;
    }

    updateMetaInfo({
      title: metaTitle.value,
      description: metaDescription.value,
      image: metaImage.value,
      type: "article",
    });
  },
);

const mobile = useMobile();

const modelsStore = useModelsStore();

const { holoviewerVisible } = storeToRefs(modelsStore);

const { supported: webpSupported } = useWebpCheck();

const storeImage = computed(() => {
  if (mobile.value && model.value?.media.storeImage?.medium) {
    return model.value?.media.storeImage?.medium;
  }

  if (model.value?.media.storeImage?.large) {
    return model.value?.media.storeImage?.large;
  }

  if (webpSupported) {
    return fallbackImage;
  }

  return fallbackImageJpg;
});

const fleetchartImageAngled = computed(() => {
  if (model.value?.media.angledViewColored) {
    if (mobile.value) {
      return model.value?.media.angledViewColored.medium;
    }

    return model.value?.media.angledViewColored.large;
  }

  if (mobile.value && model.value?.media.angledView) {
    return model.value?.media.angledView.medium;
  }

  return model.value?.media.angledView?.large;
});

const fleetchartImageFront = computed(() => {
  if (model.value?.media.frontViewColored) {
    if (mobile.value) {
      return model.value?.media.frontViewColored.medium;
    }

    return model.value?.media.frontViewColored.large;
  }

  if (mobile.value && model.value?.media.frontView) {
    return model.value?.media.frontView.medium;
  }

  return model.value?.media.frontView?.large;
});

const fleetchartImageTop = computed(() => {
  if (model.value?.media.topViewColored) {
    if (mobile.value) {
      return model.value?.media.topViewColored.medium;
    }

    return model.value?.media.topViewColored.large;
  }

  if (mobile.value && model.value?.media.topView) {
    return model.value?.media.topView.medium;
  }

  return model.value?.media.topView?.large;
});

const fleetchartImageSide = computed(() => {
  if (model.value?.media.sideViewColored) {
    if (mobile.value) {
      return model.value?.media.sideViewColored.medium;
    }

    return model.value?.media.sideViewColored.large;
  }

  if (mobile.value && model.value?.media.sideView?.medium) {
    return model.value?.media.sideView.medium;
  }

  return model.value?.media.sideView?.large;
});

const starship42Url = computed(
  () => `https://starship42.com/inverse/?ship=${model.value?.name}&mode=color`,
);

const starship42IframeUrl = computed(
  () =>
    `https://starship42.com/fleetview/fleetyards/?s=${model.value?.rsiName}&type=matrix`,
);

const { t, toDollar } = useI18n();

const metaTitle = computed(() => {
  if (!model.value) {
    return undefined;
  }

  return t("title.model", {
    name: model.value.name,
    manufacturer: model.value.manufacturer?.name,
  });
});

const metaDescription = computed(() => {
  if (!model.value || !model.value.description) {
    return undefined;
  }

  return model.value.description;
});

const metaImage = computed(() => {
  if (!model.value) {
    return undefined;
  }

  return model.value.media.storeImage?.large;
});

const { updateMetaInfo } = useMetaInfo(t);

const crumbs = computed(() => {
  if (!model.value) {
    return undefined;
  }

  return [
    {
      to: {
        name: "models",
        hash: `#${model.value.slug}`,
      },
      label: t("nav.models.index"),
    },
  ];
});

const shareUrl = computed(() => window.location.href);

onMounted(() => {
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
</script>

<script lang="ts">
export default {
  name: "ModelDetail",
};
</script>

<style lang="scss" scoped>
@import "index";
</style>
