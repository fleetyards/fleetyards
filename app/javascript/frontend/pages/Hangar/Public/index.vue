<template>
  <section class="container hangar">
    <div class="row">
      <div class="col-xs-12 col-md-12">
        <div class="row">
          <div class="col-xs-12"/>
        </div>
        <div class="row">
          <div class="col-xs-12">
            <h1>{{ t('headlines.hangarPublic', { user: usernamePlural }) }}</h1>
            <router-link
              class="to-fleetyards"
              to="/"
            >
              <i class="fal fa-chevron-left" />
              <span class="brand">{{ t('app') }}</span>
            </router-link>
          </div>
        </div>
        <div class="row">
          <div class="col-xs-12 col-md-9">
            <ModelClassLabels
              v-if="vehiclesCount"
              :label="t('labels.hangar')"
              :count-data="vehiclesCount"
            />
          </div>
          <div
            v-if="vehicles.length > 0"
            class="col-xs-12 col-md-3"
          >
            <div class="page-actions">
              <Btn
                v-if="hangarPublicFleetchart"
                :disabled="downloading"
                small
                @click.native="download"
              >
                {{ t('actions.saveScreenshot') }}
              </Btn>
              <Btn
                small
                @click.native="toggleFleetchart"
              >
                <template v-if="hangarPublicFleetchart">{{ t('actions.hideFleetchart') }}</template>
                <template v-else>{{ t('actions.showFleetchart') }}</template>
              </Btn>
            </div>
          </div>
        </div>
        <div
          v-if="hangarPublicFleetchart && vehicles.length > 0"
          class="row"
        >
          <div class="col-xs-12 col-md-4 col-md-offset-4 fleetchart-slider">
            <vue-slider
              ref="slider"
              v-model="scale"
              :min="scaleMin"
              :max="scaleMax"
              :interval="scaleInterval"
              formatter="{value}x"
              tooltip="hover"
            />
          </div>
        </div>
        <transition-group
          v-if="hangarPublicFleetchart"
          id="fleetchart"
          name="fade-list"
          class="flex-row fleetchart"
          tag="div"
          appear
        >
          <router-link
            v-for="vehicle in fleetchartVehicles"
            :key="vehicle.id"
            :to="{
              name: 'model',
              params: {
                slug: vehicle.model.slug,
              },
            }"
            class="fleetchart-item fade-list-item"
          >
            <img
              v-if="vehicle.model.fleetchartImage"
              :style="{
                height: `${vehicle.model.length * lengthMultiplicator}px`,
              }"
              :src="vehicle.model.fleetchartImage"
              :alt="vehicle.model.slug"
            >
            <span v-else>
              <i class="fal fa-question-circle" />
              <p>{{ vehicle.model.name }}</p>
            </span>
          </router-link>
        </transition-group>
        <transition-group
          v-else
          name="fade-list"
          class="flex-row"
          tag="div"
          appear
        >
          <div
            v-for="vehicle in vehicles"
            :key="vehicle.id"
            class="col-xs-12 col-sm-6 col-lg-4 col-xlg-3 fade-list-item"
          >
            <ModelPanel
              :model="vehicle.model"
              :vehicle="vehicle"
            />
          </div>
        </transition-group>
        <Loader
          v-if="loading"
          fixed
        />
      </div>
    </div>
  </section>
</template>

<script>
import Loader from 'frontend/components/Loader'
import ModelPanel from 'frontend/partials/Models/Panel'
import I18n from 'frontend/mixins/I18n'
import MetaInfo from 'frontend/mixins/MetaInfo'
import ModelClassLabels from 'frontend/partials/Models/ClassLabels'
import vueSlider from 'vue-slider-component'
import Btn from 'frontend/components/Btn'
import { mapGetters } from 'vuex'
import html2canvas from 'html2canvas'
import download from 'downloadjs'

export default {
  components: {
    ModelPanel,
    Loader,
    Btn,
    vueSlider,
    ModelClassLabels,
  },
  mixins: [I18n, MetaInfo],
  data() {
    return {
      loading: false,
      downloading: false,
      vehicles: [],
      vehiclesCount: null,
      scale: this.$store.state.hangarPublicFleetchartScale,
      scaleMax: 4,
      scaleMin: 0.5,
      scaleInterval: 0.1,
    }
  },
  computed: {
    ...mapGetters([
      'hangarPublicFleetchart',
    ]),
    lengthMultiplicator() {
      return this.scale * 4
    },
    username() {
      return this.$route.params.user
    },
    usernamePlural() {
      if (this.user.endsWith('s') || this.user.endsWith('x') || this.user.endsWith('z')) {
        return this.user
      }
      return `${this.user}'s`
    },
    user() {
      return this.username[0].toUpperCase() + this.username.slice(1)
    },
    fleetchartVehicles() {
      const fleetchartVehicles = this.vehicles.concat()
      return fleetchartVehicles.sort((a, b) => {
        if (a.model.length > b.model.length) {
          return -1
        }
        if (a.model.length < b.model.length) {
          return 1
        }
        return 0
      })
    },
  },
  watch: {
    $route() {
      this.fetch()
    },
    scale(value) {
      this.$store.commit('setHangarPublicFleetchartScale', value)
    },
    hangarPublicFleetchart() {
      this.fetch()
    },
  },
  created() {
    this.fetch()
  },
  methods: {
    toggleFleetchart() {
      this.$store.commit('toggleHangarPublicFleetchart')
    },
    download() {
      this.downloading = true
      html2canvas(document.querySelector('#fleetchart'), {
        backgroundColor: null,
        useCORS: true,
      }).then((canvas) => {
        this.downloading = false
        download(canvas.toDataURL(), 'fleetchart.png')
      })
    },
    fetch() {
      this.loading = true

      this.fetchCount()

      this.$api.get(`vehicles/${this.username}`, {}, (args) => {
        this.loading = false

        if (this.$refs.infiniteLoading) {
          this.$refs.infiniteLoading.$emit('$InfiniteLoading:reset')
        }

        if (!args.error) {
          this.vehicles = args.data
        }
      })
    },
    fetchCount() {
      this.$api.get(`vehicles/${this.username}/count`, {}, (args) => {
        if (!args.error) {
          this.vehiclesCount = args.data
        }
      })
    },
  },
  metaInfo() {
    return this.getMetaInfo({
      title: this.t('title.hangarPublic', { user: this.usernamePlural }),
    })
  },
}
</script>

<style lang="scss" scoped>
  @import "./styles/index";
</style>
