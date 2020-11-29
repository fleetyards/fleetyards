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
                <span class="manufacturer-prefix">
                  from
                </span>
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
                {{ $t('labels.3dView') }}
              </Btn>
              <a
                v-show="holoviewerVisible"
                :href="starship42Url"
                class="starship42-link"
                target="_blank"
                rel="noopener"
              >
                {{ $t('labels.poweredByStarship42') }}
              </a>
              <iframe
                v-if="holoviewerVisible"
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
                      $t(
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
                    <small class="text-muted">{{ $t('model.focus') }}:</small>
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
                style="flex-grow: 3;"
              >
                {{
                  $t('actions.model.onSale', {
                    price: $toDollar(model.pledgePrice),
                  })
                }}
                <small class="price-info">
                  {{ $t('labels.taxExcluded') }}
                </small>
              </Btn>
              <Btn v-else :href="model.storeUrl" style="flex-grow: 3;">
                {{ $t('actions.model.store') }}
              </Btn>

              <AddToHangar :model="model" />

              <BtnDropdown data-test="model-dropdown">
                <Btn
                  v-if="model.hasImages"
                  :to="{ name: 'model-images', params: { slug: model.slug } }"
                  variant="dropdown"
                >
                  <i class="fa fa-images" />
                  {{ $t('nav.images') }}
                </Btn>
                <Btn
                  v-if="model.hasVideos"
                  :to="{ name: 'model-videos', params: { slug: model.slug } }"
                  variant="dropdown"
                >
                  <i class="fal fa-video" />
                  {{ $t('nav.videos') }}
                </Btn>
                <Btn
                  v-if="model.brochure"
                  :href="model.brochure"
                  variant="dropdown"
                >
                  <i class="fal fa-download" />
                  {{ $t('labels.model.brochure') }}
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
                  {{ $t('actions.compare.models') }}
                </Btn>
              </BtnDropdown>
            </div>
          </div>
        </div>
        <hr />
        <div class="row components">
          <div class="col-12">
            <ModelHardpoints
              :hardpoints="model.hardpoints"
              :erkul-url="erkulUrl"
            />
          </div>
        </div>
      </div>
      <Loader :loading="loading" />
    </div>
    <hr v-if="paints.length" />
    <div class="row">
      <div class="col-12 paints">
        <h2 v-if="paints.length" class="text-uppercase">
          {{ $t('labels.model.paints') }}
        </h2>
        <transition-group
          v-if="paints.length"
          name="fade-list"
          class="row"
          tag="div"
          appear
        >
          <div
            v-for="paint in paints"
            :key="`paint-${paint.slug}`"
            class="col-12 col-md-6 col-xxl-4 col-xxlg-2-4 fade-list-item"
          >
            <TeaserPanel :item="paint" :fullscreen="true" />
          </div>
        </transition-group>
        <Loader :loading="loadingPaints" :fixed="true" />
      </div>
    </div>
    <hr v-if="modules.length" />
    <div class="row">
      <div class="col-12 modules">
        <h2 v-if="modules.length" class="text-uppercase">
          {{ $t('labels.model.modules') }}
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
          {{ $t('labels.model.upgrades') }}
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
          {{ $t('labels.model.variants') }}
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
          {{ $t('labels.model.loaners') }}
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

<script lang="ts">
import Vue from 'vue'
import { Component } from 'vue-property-decorator'
import { Getter } from 'vuex-class'
import MetaInfo from 'frontend/mixins/MetaInfo'
import Loader from 'frontend/core/components/Loader'
import LazyImage from 'frontend/core/components/LazyImage'
import AddToHangar from 'frontend/components/Models/AddToHangar'
import TeaserPanel from 'frontend/core/components/TeaserPanel'
import Panel from 'frontend/core/components/Panel'
import Btn from 'frontend/core/components/Btn'
import BtnDropdown from 'frontend/core/components/BtnDropdown'
import ModelHardpoints from 'frontend/components/Models/Hardpoints'
import ModelBaseMetrics from 'frontend/components/Models/BaseMetrics'
import ModelCrewMetrics from 'frontend/components/Models/CrewMetrics'
import ModelSpeedMetrics from 'frontend/components/Models/SpeedMetrics'
import ModelPanel from 'frontend/components/Models/Panel'
import BreadCrumbs from 'frontend/core/components/BreadCrumbs'
import HangarItemsMixin from 'frontend/mixins/HangarItems'
import { modelRouteGuard } from 'frontend/utils/RouteGuards'
import modelsCollection from 'frontend/api/collections/Models'

@Component<ModelDetail>({
  components: {
    Loader,
    LazyImage,
    AddToHangar,
    Panel,
    TeaserPanel,
    Btn,
    BtnDropdown,
    ModelHardpoints,
    ModelBaseMetrics,
    ModelCrewMetrics,
    ModelSpeedMetrics,
    ModelPanel,
    BreadCrumbs,
  },
  mixins: [MetaInfo, HangarItemsMixin],
  beforeRouteEnter: modelRouteGuard,
})
export default class ModelDetail extends Vue {
  loading: boolean = false

  loadingVariants: boolean = false

  loadingLoaners: boolean = false

  loadingPaints: boolean = false

  loadingModules: boolean = false

  loadingUpgrades: boolean = false

  show3d: boolean = false

  variants: Model[] = []

  paints: ModelPaint[] = []

  loaners: ModelLoaner[] = []

  modules: ModelModule[] = []

  upgrades: ModelUpgrade[] = []

  model: Model | null = null

  attributes: string[] = [
    'length',
    'beam',
    'height',
    'mass',
    'cargo',
    'minCrew',
    'maxCrew',
    'scmSpeed',
    'afterburnerSpeed',
  ]

  @Getter('overlayVisible', { namespace: 'app' }) overlayVisible

  @Getter('holoviewerVisible', { namespace: 'models' }) holoviewerVisible

  get storeImage() {
    if (this.mobile) {
      return this.model.storeImageMedium
    }

    return this.model.storeImageLarge
  }

  get starship42Url(): string {
    return `https://starship42.com/inverse/?ship=${this.model.name}&mode=color`
  }

  get starship42IframeUrl(): string {
    return `https://starship42.com/fleetview/fleetyards/?s=${this.model.rsiName}&type=matrix`
  }

  get erkulUrl(): string | null {
    if (!this.model || this.model.productionStatus !== 'flight-ready') {
      return null
    }

    return `https://www.erkul.games/ship/${this.model.dataSlug}`
  }

  get metaTitle() {
    if (!this.model) {
      return null
    }

    return this.$t('title.model', {
      name: this.model.name,
      manufacturer: this.model.manufacturer.name,
    })
  }

  get crumbs() {
    if (!this.model) {
      return null
    }

    return [
      {
        to: {
          name: 'models',
          hash: `#${this.model.slug}`,
        },
        label: this.$t('nav.models.index'),
      },
    ]
  }

  mounted() {
    this.fetch()
    this.fetchExtras()

    if (this.$route.query.holoviewer) {
      this.$store.dispatch('models/enableHoloviewer')
    }
  }

  toggleHoloviewer() {
    this.$store.dispatch('models/toggleHoloviewer')
  }

  fetchExtras() {
    this.fetchModules()
    this.fetchUpgrades()
    this.fetchPaints()
    this.fetchVariants()
    this.fetchLoaners()
  }

  async fetchModules() {
    this.loadingModules = true
    const response = await this.$api.get(
      `models/${this.$route.params.slug}/modules`,
    )
    this.loadingModules = false
    if (!response.error) {
      this.modules = response.data
    }
  }

  async fetchUpgrades() {
    this.loadingUpgrades = true
    const response = await this.$api.get(
      `models/${this.$route.params.slug}/upgrades`,
    )
    this.loadingUpgrades = false
    if (!response.error) {
      this.upgrades = response.data
    }
  }

  async fetchPaints() {
    this.loadingPaints = true
    const response = await this.$api.get(
      `models/${this.$route.params.slug}/paints`,
    )
    this.loadingPaints = false
    if (!response.error) {
      this.paints = response.data
    }
  }

  async fetchVariants() {
    this.loadingVariants = true
    const response = await this.$api.get(
      `models/${this.$route.params.slug}/variants`,
    )
    this.loadingVariants = false
    if (!response.error) {
      this.variants = response.data
    }
  }

  async fetchLoaners() {
    this.loadingLoaners = true
    const response = await this.$api.get(
      `models/${this.$route.params.slug}/loaners`,
    )
    this.loadingLoaners = false
    if (!response.error) {
      this.loaners = response.data
    }
  }

  async fetch() {
    this.loading = true
    this.model = await modelsCollection.findBySlug(this.$route.params.slug)
    this.loading = false
  }
}
</script>

<style lang="scss" scoped>
@import 'index';
</style>
