<template>
  <section class="container">
    <div class="row">
      <div
        v-if="model"
        class="col-xs-12"
      >
        <div class="row">
          <div class="col-xs-12">
            <h1>
              <router-link
                v-if="backRoute"
                :to="backRoute"
                class="back-button"
              >
                <i class="fal fa-chevron-left" />
              </router-link>
              {{ model.name }}
              <small class="manufacturer">
                <span class="manufacturer-prefix">
                  from
                </span>
                <span v-html="model.manufacturer.name" />
                <img
                  v-if="model.manufacturer && model.manufacturer.logo"
                  :src="model.manufacturer.logo"
                  class="manufacturer-logo"
                >
              </small>
            </h1>
          </div>
        </div>
        <div class="row">
          <div class="col-xs-12 col-md-8">
            <div class="image-wrapper">
              <Btn
                :active="show3d"
                class="toggle-3d"
                size="small"
                @click.native="toggle3d"
              >
                {{ t('labels.3dView') }}
              </Btn>
              <Btn
                v-if="show3d"
                :active="color3d"
                class="toggle-3d-color"
                size="small"
                @click.native="toggle3dColor"
              >
                {{ t('labels.3dColor') }}
              </Btn>
              <div
                v-if="show3d"
                class="embed-responsive embed-responsive-16by9"
              >
                <iframe
                  :src="starship42Url"
                  class="embed-responsive-item"
                  frameborder="0"
                />
              </div>
              <img
                v-else
                :src="model.storeImage"
                class="image"
                alt="model image"
              >
            </div>
            <div class="row production-status">
              <div class="col-xs-6">
                <template v-if="model.productionStatus">
                  <h3 class="text-uppercase">
                    {{ t(`labels.model.productionStatus.${model.productionStatus}`) }}
                  </h3>
                  <p>{{ model.productionNote }}</p>
                </template>
              </div>
              <div class="col-xs-6">
                <template v-if="model.focus">
                  <h3 class="text-uppercase text-right">
                    <small>{{ t('model.focus') }}:</small>
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
              <ul class="list-group">
                <li class="list-group-item">
                  <ModelBaseMetrics
                    :model="model"
                    title
                    detailed
                  />
                </li>
              </ul>
            </Panel>
            <Panel>
              <ul class="list-group">
                <li class="list-group-item">
                  <ModelCrewMetrics
                    :model="model"
                    title
                  />
                </li>
              </ul>
            </Panel>
            <Panel>
              <ul class="list-group">
                <li class="list-group-item">
                  <ModelSpeedMetrics
                    :model="model"
                    title
                  />
                </li>
              </ul>
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
                  {{ t('labels.model.brochure') }}
                  <i class="fal fa-download" />
                </Btn>
                <Btn :href="model.storeUrl">
                  {{ t('actions.model.store') }}
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
                {{ t('actions.model.onSale', { price: toDollar(model.pledgePrice) }) }}
                <small class="price-info">
                  {{ t('labels.taxExcluded') }}
                </small>
              </Btn>
            </div>
            <br>
          </div>
        </div>
        <div class="row components">
          <div class="col-xs-12">
            <ModelHardpoints :hardpoints="model.hardpoints" />
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
          {{ t('labels.model.modules') }}
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
          {{ t('labels.model.upgrades') }}
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
          {{ t('labels.model.variants') }}
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
import qs from 'qs'
import I18n from 'frontend/mixins/I18n'
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
  },
  mixins: [I18n, MetaInfo],
  data() {
    return {
      loading: false,
      loadingVariants: false,
      loadingModules: false,
      loadingUpgrades: false,
      show3d: false,
      color3d: false,
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
    ...mapGetters([
      'previousRoute',
      'overlayVisible',
    ]),
    ...mapGetters('models', [
      'backRoute',
    ]),
    starship42Url() {
      const data = { source: 'FleetYards', type: 'matrix', s: this.model.rsiName }
      if (this.color3d) {
        data.style = 'colored'
      }
      const startship42Params = qs.stringify(data)
      return `https://starship42.com/fleetview/single?${startship42Params}`
    },
    title() {
      if (!this.model) {
        return null
      }
      return this.t('title.model', {
        name: this.model.name,
        manufacturer: this.model.manufacturer.name,
      })
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

      this.setBackRoute()

      if (this.model.backgroundImage) {
        this.$store.commit('setBackgroundImage', this.model.backgroundImage)
      }
    },
  },
  created() {
    this.fetch()
    this.fetchModules()
    this.fetchUpgrades()
    this.fetchVariants()
  },
  methods: {
    setBackRoute() {
      if (this.backRoute && this.previousRoute
        && ['model-images', 'model-videos'].includes(this.previousRoute.name)) {
        return
      }

      const route = {
        name: 'models',
        hash: `#${this.model.slug}`,
      }

      if (this.previousRoute && ['models', 'fleet', 'hangar', 'shop'].includes(this.previousRoute.name)) {
        route.name = this.previousRoute.name
        route.params = this.previousRoute.params
        route.query = this.previousRoute.query
      }

      this.$store.commit('models/setBackRoute', route)
    },
    toggle3d() {
      this.show3d = !this.show3d
    },
    toggle3dColor() {
      this.color3d = !this.color3d
    },
    async fetch() {
      this.model = this.$dataPrefill('model')
      if (this.model) {
        return
      }

      this.loading = true
      const response = await this.$api.get(`models/${this.$route.params.slug}`, {
        without_images: true,
        without_videos: true,
      })
      this.loading = false
      if (!response.error) {
        this.model = response.data
      } else if (response.error.response && response.error.response.status === 404) {
        this.$router.replace({ name: '404' })
      }
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
  metaInfo() {
    return this.getMetaInfo({
      title: this.title,
    })
  },
}
</script>

<style lang="scss" scoped>
  @import './styles/index';
</style>
