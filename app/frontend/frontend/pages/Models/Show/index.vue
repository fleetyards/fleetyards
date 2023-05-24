<template>
  <section class="container">
    <div class="row">
      <div v-if="!loading && model" class="col-12">
        <div class="row">
          <div class="col-12">
            <BreadCrumbs :crumbs="crumbs" />
            <h1>
              {{ model.name }}
              <small class="text-muted manufacturer">
                <span class="manufacturer-prefix">from</span>
                <span v-html="model.manufacturer.name" />
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
                @click.native="toggleHoloviewer"
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
              <LazyImage v-else :src="storeImage" class="image" />
            </div>
            <div class="row production-status">
              <div class="col-6">
                <template v-if="model.productionStatus">
                  <h3 class="text-uppercase">
                    {{
                      t(
                        `labels.model.productionStatus.${model.productionStatus}`
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
            <Panel>
              <ModelBaseMetrics :model="model" />
            </Panel>
            <Panel>
              <ModelCrewMetrics :model="model" />
            </Panel>
            <Panel>
              <ModelSpeedMetrics :model="model" />
            </Panel>
            <div class="page-actions page-actions-block">
              <Btn
                v-if="model.onSale"
                :href="`${model.storeUrl}#buying-options`"
                style="flex-grow: 3"
              >
                {{
                  t("actions.model.onSale", {
                    price: toDollar(model.pledgePrice),
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
                  :to="{ name: 'model-images', params: { slug: model.slug } }"
                  variant="dropdown"
                >
                  <i class="fa fa-images" />
                  <span>{{ t("nav.images") }}</span>
                </Btn>
                <Btn
                  v-if="model.hasVideos"
                  :to="{ name: 'model-videos', params: { slug: model.slug } }"
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
                  <i class="fal fa-exchange" />
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
        <div class="fleetchart-views">
          <div class="fleetchart-views-items">
            <div v-if="fleetchartImageAngled" class="big">
              <img :src="fleetchartImageAngled" />
            </div>
            <div v-if="fleetchartImageTop">
              <img :src="fleetchartImageTop" />
            </div>
          </div>
          <div class="fleetchart-views-items">
            <div v-if="fleetchartImageFront" class="small">
              <img :src="fleetchartImageFront" />
            </div>
            <div v-if="fleetchartImageSide">
              <img :src="fleetchartImageSide" />
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
      <Loader :loading="loading" />
    </div>
    <Paints :model="model" />

    <hr v-if="modules.length" />
    <div class="row">
      <div class="col-12 modules">
        <h2 v-if="modules.length" class="text-uppercase">
          {{ t("labels.model.modules") }}
        </h2>
        <div v-if="modules.length" class="row">
          <div
            v-for="module in modules"
            :key="module.id"
            class="col-12 col-md-6 col-xxl-4 col-xxlg-2-4"
          >
            <TeaserPanel :item="module" />
          </div>
        </div>
        <Loader :loading="loadingModules" :fixed="true" />
      </div>
    </div>
    <hr v-if="upgrades.length" />
    <div class="row">
      <div class="col-12 upgrades">
        <h2 v-if="upgrades.length" class="text-uppercase">
          {{ t("labels.model.upgrades") }}
        </h2>
        <div v-if="upgrades.length" class="row">
          <div
            v-for="upgrade in upgrades"
            :key="upgrade.id"
            class="col-12 col-md-6 col-xxl-4 col-xxlg-2-4"
          >
            <TeaserPanel :item="upgrade" />
          </div>
        </div>
        <Loader :loading="loadingUpgrades" :fixed="true" />
      </div>
    </div>
    <hr v-if="variants.length" />
    <div class="row">
      <div class="col-12 variants">
        <h2 v-if="variants.length" class="text-uppercase">
          {{ t("labels.model.variants") }}
        </h2>
        <transition-group
          v-if="variants.length"
          name="fade-list"
          class="row"
          tag="div"
          appear
        >
          <div
            v-for="variant in variants"
            :key="`variant-${variant.slug}`"
            class="col-12 col-md-6 col-xxl-4 col-xxlg-2-4 fade-list-item"
          >
            <ModelPanel :model="variant" :details="true" />
          </div>
        </transition-group>
        <Loader :loading="loadingVariants" :fixed="true" />
      </div>
    </div>
    <hr v-if="loaners.length" />
    <div class="row">
      <div class="col-12 loaners">
        <h2 v-if="loaners.length" class="text-uppercase">
          {{ t("labels.model.loaners") }}
        </h2>
        <transition-group
          v-if="loaners.length"
          name="fade-list"
          class="row"
          tag="div"
          appear
        >
          <div
            v-for="loaner in loaners"
            :key="`loaner-${loaner.slug}`"
            class="col-12 col-md-6 col-xxl-4 col-xxlg-2-4 fade-list-item"
          >
            <ModelPanel :model="loaner" />
          </div>
        </transition-group>
        <Loader :loading="loadingLoaners" :fixed="true" />
      </div>
    </div>
  </section>
</template>

<script lang="ts" setup>
import { useRoute } from "vue-router/composables";
import Loader from "@/frontend/core/components/Loader/index.vue";
import LazyImage from "@/frontend/core/components/LazyImage/index.vue";
import AddToHangar from "@/frontend/components/Models/AddToHangar/index.vue";
import TeaserPanel from "@/frontend/core/components/TeaserPanel/index.vue";
import Panel from "@/frontend/core/components/Panel/index.vue";
import Btn from "@/frontend/core/components/Btn/index.vue";
import BtnDropdown from "@/frontend/core/components/BtnDropdown/index.vue";
import Hardpoints from "@/frontend/components/Models/Hardpoints/index.vue";
import Paints from "@/frontend/components/Models/PaintsList/index.vue";
import ModelBaseMetrics from "@/frontend/components/Models/BaseMetrics/index.vue";
import ModelCrewMetrics from "@/frontend/components/Models/CrewMetrics/index.vue";
import ModelSpeedMetrics from "@/frontend/components/Models/SpeedMetrics/index.vue";
import ModelPanel from "@/frontend/components/Models/Panel/index.vue";
import BreadCrumbs from "@/frontend/core/components/BreadCrumbs/index.vue";
import HoloViewer from "@/frontend/core/components/HoloViewer/index.vue";
import { modelRouteGuard } from "@/frontend/utils/RouteGuards/Models";
import modelsCollection from "@/frontend/api/collections/Models";
import modelModulesCollection from "@/frontend/api/collections/ModelModules";
import modelUpgradesCollection from "@/frontend/api/collections/ModelUpgrades";
import modelVariantsCollection from "@/frontend/api/collections/ModelVariants";
import modelLoanersCollection from "@/frontend/api/collections/ModelLoaners";
import ShareBtn from "@/frontend/components/ShareBtn/index.vue";
import { useI18n } from "@/frontend/composables/useI18n";
import { useHangarItems } from "@/frontend/composables/useHangarItems";
import { useWishlistItems } from "@/frontend/composables/useWishlistItems";
import { useMetaInfo } from "@/frontend/composables/useMetaInfo";
import Store from "@/frontend/lib/Store";

useHangarItems();
useWishlistItems();

const loading = ref(false);

const loadingVariants = ref(false);

const loadingLoaners = ref(false);

const loadingModules = ref(false);

const loadingUpgrades = ref(false);

const variants = ref<Model[]>([]);

const loaners = ref<ModelLoaner[]>([]);

const modules = ref<ModelModule[]>([]);

const upgrades = ref<ModelUpgrade[]>([]);

const model = ref<Model | null>(null);

const mobile = computed(() => Store.getters.mobile);

const holoviewerVisible = computed(
  () => Store.getters["models/holoviewerVisible"]
);

const route = useRoute();

const modelSlug = computed(() => route.params.slug);

const storeImage = computed(() => {
  if (mobile.value) {
    return model.value?.media.storeImage?.medium;
  }

  return model.value?.media.storeImage?.large;
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
  () => `https://starship42.com/inverse/?ship=${model.value?.name}&mode=color`
);

const starship42IframeUrl = computed(
  () =>
    `https://starship42.com/fleetview/fleetyards/?s=${model.value?.rsiName}&type=matrix`
);

const { t, toDollar } = useI18n();

const metaTitle = computed(() => {
  if (!model.value) {
    return undefined;
  }

  return t("title.model", {
    name: model.value.name,
    manufacturer: model.value.manufacturer.name,
  });
});

const metaDescription = computed(() => {
  if (!model.value) {
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

const { updateMetaInfo } = useMetaInfo();

const crumbs = computed(() => {
  if (!model.value) {
    return null;
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
  fetch();
  fetchExtras();

  if (route.query.holoviewer) {
    Store.dispatch("models/enableHoloviewer");
  }
});

const toggleHoloviewer = () => {
  Store.dispatch("models/toggleHoloviewer");
};

const fetchExtras = () => {
  fetchModules();
  fetchUpgrades();
  fetchVariants();
  fetchLoaners();
};

const fetchModules = async () => {
  loadingModules.value = true;

  modules.value = await modelModulesCollection.findAll(modelSlug.value);

  loadingModules.value = false;
};

const fetchUpgrades = async () => {
  loadingUpgrades.value = true;

  upgrades.value = await modelUpgradesCollection.findAll(modelSlug.value);

  loadingUpgrades.value = false;
};

const fetchVariants = async () => {
  loadingVariants.value = true;

  variants.value = await modelVariantsCollection.findAll(modelSlug.value);

  loadingVariants.value = false;
};

const fetchLoaners = async () => {
  loadingLoaners.value = true;

  loaners.value = await modelLoanersCollection.findAll(modelSlug.value);

  loadingLoaners.value = false;
};

const fetch = async () => {
  loading.value = true;

  model.value = await modelsCollection.findBySlug(route.params.slug);

  updateMetaInfo(
    metaTitle.value,
    metaDescription.value,
    metaImage.value,
    "article"
  );

  loading.value = false;
};
</script>

<script lang="ts">
export default {
  name: "ModelDetail",
  beforeRouteEnter: modelRouteGuard,
};
</script>

<style lang="scss" scoped>
@import "index";
</style>
