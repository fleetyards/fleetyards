<template>
  <section class="container">
    <div class="row">
      <div
        v-if="model"
        class="col-xs-12"
      >
        <div class="row">
          <div class="col-xs-12">
            <h1 class="back-button">
              {{ model.name }}
              <small class="manufacturer">
                <span class="manufacturer-prefix">from</span>
                <span v-html="model.manufacturer.name" />
                <img
                  v-if="model.manufacturer && model.manufacturer.logo"
                  :src="model.manufacturer.logo"
                  class="manufacturer-logo"
                >
              </small>
              <router-link
                v-if="modelBackRoute"
                :to="modelBackRoute"
                class="btn btn-link"
              >
                <i class="fal fa-chevron-left" />
              </router-link>
            </h1>
          </div>
        </div>
        <div class="row">
          <div class="col-xs-12 col-md-8">
            <Btn
              :active="show3d"
              class="toggle-3d"
              small
              @click.native="toggle3d"
            >
              {{ t('labels.3dView') }}
            </Btn>
            <Btn
              v-if="show3d"
              :active="color3d"
              class="toggle-3d-color"
              small
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
                <InternalLink
                  v-if="model.hasImages"
                  :route="{ name: 'model-images', params: { slug: model.slug }}"
                >
                  <i class="fa fa-image" />
                </InternalLink>
                <InternalLink
                  v-if="model.hasVideos"
                  :route="{ name: 'model-videos', params: { slug: model.slug }}"
                >
                  <i class="fal fa-video" />
                </InternalLink>
                <ExternalLink
                  v-if="model.brochure"
                  :url="model.brochure"
                >
                  {{ t('labels.model.brochure') }}
                  <i class="fal fa-download" />
                </ExternalLink>
                <ExternalLink :url="model.storeUrl">
                  {{ t('actions.model.store') }}
                </ExternalLink>
                <AddToHangar :model="model" />
              </div>
            </div>
            <br>
            <div
              v-if="model.onSale"
              class="text-center"
            >
              <ExternalLink
                :url="`${model.storeUrl}#buying-options`"
                class="sale-button"
                large
              >
                {{ t('actions.model.onSale', { price: toDollar(model.pledgePrice) }) }}
                <small class="price-info">{{ t('labels.taxExcluded') }}</small>
              </ExternalLink>
            </div>
            <br >
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
  </section>
</template>

<script>
import qs from 'qs'
import I18n from 'frontend/mixins/I18n'
import MetaInfo from 'frontend/mixins/MetaInfo'
import Loader from 'frontend/components/Loader'
import AddToHangar from 'frontend/components/AddToHangar'
import Panel from 'frontend/components/Panel'
import Btn from 'frontend/components/Btn'
import ExternalLink from 'frontend/components/ExternalLink'
import InternalLink from 'frontend/components/InternalLink'
import ModelHardpoints from 'frontend/partials/Models/Hardpoints'
import ModelBaseMetrics from 'frontend/partials/Models/BaseMetrics'
import ModelCrewMetrics from 'frontend/partials/Models/CrewMetrics'
import ModelSpeedMetrics from 'frontend/partials/Models/SpeedMetrics'
import { mapGetters } from 'vuex'

export default {
  components: {
    Loader,
    AddToHangar,
    Panel,
    Btn,
    ExternalLink,
    InternalLink,
    ModelHardpoints,
    ModelBaseMetrics,
    ModelCrewMetrics,
    ModelSpeedMetrics,
  },
  mixins: [I18n, MetaInfo],
  data() {
    return {
      title: null,
      loading: false,
      show3d: false,
      color3d: false,
      model: null,
      attributes: [
        'length', 'beam', 'height', 'mass', 'cargo', 'minCrew', 'maxCrew', 'scmSpeed', 'afterburnerSpeed',
      ],
    }
  },
  computed: {
    ...mapGetters([
      'previousRoute',
      'overlayVisible',
      'modelBackRoute',
    ]),
    starship42Url() {
      const data = { source: 'FleetYards', type: 'matrix', s: this.model.rsiName }
      if (this.color3d) {
        data.style = 'colored'
      }
      const startship42Params = qs.stringify(data)
      return `https://starship42.fleetyards.net/fleetview/single?${startship42Params}`
    },
  },
  watch: {
    $route() {
      this.fetch()
    },
    model() {
      this.setBackRoute()

      this.title = this.t('title.model', {
        name: this.model.name,
        manufacturer: this.model.manufacturer.name,
      })
      if (this.model.backgroundImage) {
        this.$store.commit('setBackgroundImage', this.model.backgroundImage)
      }
    },
  },
  created() {
    this.fetch()
  },
  methods: {
    setBackRoute() {
      if (this.modelBackRoute && this.previousRoute
        && ['model-images', 'model-videos'].includes(this.previousRoute.name)) {
        return
      }

      const route = {
        name: 'models',
        hash: `#${this.model.slug}`,
      }

      if (this.previousRoute && ['models', 'fleet', 'hangar'].includes(this.previousRoute.name)) {
        route.name = this.previousRoute.name
        route.params = this.previousRoute.params
        route.query = this.previousRoute.query
      }

      this.$store.commit('setModelBackRoute', route)
    },
    toggle3d() {
      this.show3d = !this.show3d
    },
    toggle3dColor() {
      this.color3d = !this.color3d
    },
    async fetch() {
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
  },
  metaInfo() {
    return this.getMetaInfo({
      title: this.title,
    })
  },
}
</script>

<style lang="scss" scoped>
  @import "./styles/index";
</style>
