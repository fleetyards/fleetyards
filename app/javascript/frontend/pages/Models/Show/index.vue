<template>
  <section class="container">
    <div class="row">
      <div
        v-if="model"
        class="col-xs-12"
      >
        <div class="row">
          <div class="col-xs-12">
            <BreadCrumbs :crumbs="crumbs" />
            <h1>
              {{ model.name }}
              <small class="manufacturer">
                <span class="manufacturer-prefix">
                  from
                </span>
                <span v-html="model.manufacturer.name" />
                <img
                  v-if="model.manufacturer && model.manufacturer.logo"
                  v-lazy="model.manufacturer.logo"
                  class="manufacturer-logo"
                >
              </small>
            </h1>
          </div>
        </div>
        <div class="row">
          <div class="col-xs-12 col-md-8">
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
              <img
                v-lazy="model.storeImage"
                class="image"
                :class="{
                  'image-hidden': holoviewerVisible,
                }"
                alt="model image"
              >
            </div>
            <div class="row production-status">
              <div class="col-xs-6">
                <template v-if="model.productionStatus">
                  <h3 class="text-uppercase">
                    {{ $t(`labels.model.productionStatus.${model.productionStatus}`) }}
                  </h3>
                  <p>{{ model.productionNote }}</p>
                </template>
              </div>
              <div class="col-xs-6">
                <template v-if="model.focus">
                  <h3 class="text-uppercase text-right">
                    <small>{{ $t('model.focus') }}:</small>
                    {{ model.focus }}
                  </h3>
                </template>
              </div>
            </div>
            <blockquote class="description">
              <p v-html="model.description" />
            </blockquote>
          </div>
          <div class="col-xs-12 col-md-4">
            <Panel>
              <ModelBaseMetrics
                :model="model"
                title
                detailed
                padding
              />
            </Panel>
            <Panel>
              <ModelCrewMetrics
                :model="model"
                title
                padding
              />
            </Panel>
            <Panel>
              <ModelSpeedMetrics
                :model="model"
                title
                padding
              />
            </Panel>
            <div class="text-right">
              <div class="page-actions">
                <Btn
                  v-if="model.hasImages"
                  :to="{ name: 'model-images', params: { slug: model.slug }}"
                >
                  <i class="fa fa-images" />
                </Btn>
                <Btn
                  v-if="model.hasVideos"
                  :to="{ name: 'model-videos', params: { slug: model.slug }}"
                >
                  <i class="fal fa-video" />
                </Btn>
                <Btn
                  v-if="model.brochure"
                  :href="model.brochure"
                >
                  {{ $t('labels.model.brochure') }}
                  <i class="fal fa-download" />
                </Btn>
                <Btn :to="{ name: 'compare-models', query: { models: [model.slug] }}">
                  {{ $t('actions.compare.models') }}
                </Btn>
                <Btn :href="model.storeUrl">
                  {{ $t('actions.model.store') }}
                </Btn>
                <AddToHangar :model="model" />
              </div>
            </div>
            <br>
            <div
              v-if="model.onSale"
              class="text-center"
            >
              <Btn
                :href="`${model.storeUrl}#buying-options`"
                class="sale-button"
                size="large"
              >
                {{ $t('actions.model.onSale', { price: $toDollar(model.pledgePrice) }) }}
                <small class="price-info">
                  {{ $t('labels.taxExcluded') }}
                </small>
              </Btn>
            </div>
            <br>
          </div>
        </div>
        <div class="row components">
          <div class="col-xs-12">
            <ModelHardpoints
              :hardpoints="model.hardpoints"
              :erkul-url="erkulUrl"
            />
          </div>
        </div>
      </div>
      <Loader :loading="loading" />
    </div>
    <div class="row">
      <div class="col-xs-12 modules">
        <h2
          v-if="modules.length"
          class="text-uppercase"
        >
          {{ $t('labels.model.modules') }}
        </h2>
        <div
          v-if="modules.length"
          class="flex-row"
        >
          <div
            v-for="module in modules"
            :key="module.id"
            class="col-xs-12 col-sm-6 col-xlg-4 col-xxlg-2-4"
          >
            <TeaserPanel :item="module" />
          </div>
        </div>
        <Loader
          :loading="loadingModules"
          fixed
        />
      </div>
    </div>
    <div class="row">
      <div class="col-xs-12 upgrades">
        <h2
          v-if="upgrades.length"
          class="text-uppercase"
        >
          {{ $t('labels.model.upgrades') }}
        </h2>
        <div
          v-if="upgrades.length"
          class="flex-row"
        >
          <div
            v-for="upgrade in upgrades"
            :key="upgrade.id"
            class="col-xs-12 col-sm-6 col-xlg-4 col-xxlg-2-4"
          >
            <TeaserPanel :item="upgrade" />
          </div>
        </div>
        <Loader
          :loading="loadingUpgrades"
          fixed
        />
      </div>
    </div>
    <div class="row">
      <div class="col-xs-12 variants">
        <h2
          v-if="variants.length"
          class="text-uppercase"
        >
          {{ $t('labels.model.variants') }}
        </h2>
        <transition-group
          v-if="variants.length"
          name="fade-list"
          class="flex-row"
          tag="div"
          appear
        >
          <div
            v-for="variant in variants"
            :key="variant.slug"
            class="col-xs-12 col-sm-6 col-xlg-4 col-xxlg-2-4 fade-list-item"
          >
            <ModelPanel
              :model="variant"
              details
            />
          </div>
        </transition-group>
        <Loader
          :loading="loadingVariants"
          fixed
        />
      </div>
    </div>
  </section>
</template>

<script>
import MetaInfo from 'frontend/mixins/MetaInfo'
import Loader from 'frontend/components/Loader'
import AddToHangar from 'frontend/partials/Models/AddToHangar'
import TeaserPanel from 'frontend/components/TeaserPanel'
import Panel from 'frontend/components/Panel'
import Btn from 'frontend/components/Btn'
import ModelHardpoints from 'frontend/partials/Models/Hardpoints'
import ModelBaseMetrics from 'frontend/partials/Models/BaseMetrics'
import ModelCrewMetrics from 'frontend/partials/Models/CrewMetrics'
import ModelSpeedMetrics from 'frontend/partials/Models/SpeedMetrics'
import ModelPanel from 'frontend/components/Models/Panel'
import BreadCrumbs from 'frontend/components/BreadCrumbs'
import { mapGetters } from 'vuex'

export default {
  components: {
    Loader,
    AddToHangar,
    Panel,
    TeaserPanel,
    Btn,
    ModelHardpoints,
    ModelBaseMetrics,
    ModelCrewMetrics,
    ModelSpeedMetrics,
    ModelPanel,
    BreadCrumbs,
  },

  mixins: [
    MetaInfo,
  ],

  data() {
    return {
      loading: false,
      loadingVariants: false,
      loadingModules: false,
      loadingUpgrades: false,
      show3d: false,
      model: null,
      variants: [],
      modules: [],
      upgrades: [],
      attributes: [
        'length', 'beam', 'height', 'mass', 'cargo', 'minCrew', 'maxCrew', 'scmSpeed', 'afterburnerSpeed',
      ],
    }
  },

  computed: {
    ...mapGetters('app', [
      'overlayVisible',
    ]),

    ...mapGetters('models', [
      'holoviewerVisible',
    ]),

    starship42Url() {
      return `https://starship42.com/inverse/?ship=${this.model.name}&mode=color`
    },

    starship42IframeUrl() {
      return `https://starship42.com/fleetview/fleetyards/?s=${this.model.rsiName}&type=matrix`
    },

    erkulUrl() {
      if (!this.model || this.model.productionStatus !== 'flight-ready') {
        return null
      }

      return `https://www.erkul.games/calculator/fleetyardsnet/${this.model.erkulsSlug}`
    },

    metaTitle() {
      if (!this.model) {
        return null
      }

      return this.$t('title.model', {
        name: this.model.name,
        manufacturer: this.model.manufacturer.name,
      })
    },

    crumbs() {
      if (!this.model) {
        return null
      }

      return [{
        to: {
          name: 'models',
          hash: `#${this.model.slug}`,
        },
        label: this.$t('nav.models'),
      }]
    },
  },

  watch: {
    $route() {
      this.fetch()
      this.fetchModules()
      this.fetchUpgrades()
      this.fetchVariants()
    },

    model() {
      if (!this.model) {
        return
      }

      if (this.model.backgroundImage) {
        this.$store.commit('setBackgroundImage', this.model.backgroundImage)
      }
    },
  },

  created() {
    this.fetch()
  },

  mounted() {
    if (this.$route.query.holoviewer) {
      this.$store.dispatch('models/enableHoloviewer')
    }
  },

  methods: {
    toggleHoloviewer() {
      this.$store.dispatch('models/toggleHoloviewer')
    },

    async fetch() {
      this.model = this.$prefetch('model')
      if (this.model) {
        return
      }

      this.loading = true

      const response = await this.$api.get(`models/${this.$route.params.slug}`, {
        withoutImages: true,
        withoutVideos: true,
      })

      this.loading = false

      if (!response.error) {
        this.model = response.data
        this.fetchExtras()
      } else if (response.error.response && response.error.response.status === 404) {
        this.$router.replace({ name: '404' })
      }
    },

    fetchExtras() {
      this.fetchModules()
      this.fetchUpgrades()
      this.fetchVariants()
    },

    async fetchModules() {
      this.loadingModules = true
      const response = await this.$api.get(`models/${this.$route.params.slug}/modules`)
      this.loadingModules = false
      if (!response.error) {
        this.modules = response.data
      }
    },

    async fetchUpgrades() {
      this.loadingUpgrades = true
      const response = await this.$api.get(`models/${this.$route.params.slug}/upgrades`)
      this.loadingUpgrades = false
      if (!response.error) {
        this.upgrades = response.data
      }
    },

    async fetchVariants() {
      this.loadingVariants = true
      const response = await this.$api.get(`models/${this.$route.params.slug}/variants`)
      this.loadingVariants = false
      if (!response.error) {
        this.variants = response.data
      }
    },
  },
}
</script>

<style lang="scss" scoped>
  @import 'index';
</style>
