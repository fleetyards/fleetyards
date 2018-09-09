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
        </div>
        <div class="row">
          <div class="col-xs-12 col-md-6">
            <Paginator
              v-if="!hangarPublicFleetchartVisible && vehicles.length"
              :page="currentPage"
              :total="totalPages"
            />
          </div>
          <div
            v-if="vehicles.length > 0"
            class="col-xs-12 col-md-6"
          >
            <div class="page-actions">
              <Btn
                v-if="hangarPublicFleetchartVisible"
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
                <template v-if="hangarPublicFleetchartVisible">
                  {{ t('actions.hideFleetchart') }}
                </template>
                <template v-else>{{ t('actions.showFleetchart') }}</template>
              </Btn>
            </div>
          </div>
        </div>
        <div
          v-if="hangarPublicFleetchartVisible && vehicles.length > 0"
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
          v-if="hangarPublicFleetchartVisible"
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
            class="col-xs-12 col-sm-6 col-lg-4 col-xlg-3 col-xxlg-2-4 fade-list-item"
          >
            <ModelPanel
              :model="vehicle.model"
              :vehicle="vehicle"
            />
          </div>
        </transition-group>
        <Loader
          :loading="loading"
          fixed
        />
      </div>
    </div>
    <div class="row">
      <div class="col-xs-12">
        <Paginator
          v-if="!hangarPublicFleetchartVisible && vehicles.length"
          :page="currentPage"
          :total="totalPages"
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
import Pagination from 'frontend/mixins/Pagination'
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
  mixins: [I18n, MetaInfo, Pagination],
  data() {
    return {
      loading: false,
      downloading: false,
      vehicles: [],
      fleetchartVehicles: [],
      vehiclesCount: null,
      scale: this.$store.state.hangarPublicFleetchartScale,
      scaleMax: 4,
      scaleMin: 0.5,
      scaleInterval: 0.1,
    }
  },
  computed: {
    ...mapGetters([
      'hangarPublicFleetchartVisible',
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
  },
  watch: {
    $route() {
      if (this.hangarPublicFleetchart) {
        this.fetch()
      } else {
        this.fetchFleetchart()
      }
    },
    scale(value) {
      this.$store.commit('setHangarPublicFleetchartScale', value)
    },
    hangarPublicFleetchart() {
      if (this.hangarPublicFleetchart) {
        this.fetchFleetchart()
      } else {
        this.fetch()
      }
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
    async fetch() {
      this.loading = true

      this.fetchCount()

      const response = await this.$api.get(`vehicles/${this.username}`, {
        page: this.$route.query.page,
      })
      this.loading = false

      if (!response.error) {
        this.vehicles = response.data
      }
      this.setPages(response.meta)
    },
    async fetchCount() {
      const response = await this.$api.get(`vehicles/${this.username}/count`, {})
      if (!response.error) {
        this.vehiclesCount = response.data
      }
    },
    async fetchFleetchart() {
      this.loading = true
      const response = await this.$api.get('vehicles/fleetchart', {
        q: this.$route.query.q,
      })
      this.loading = false
      if (!response.error) {
        this.fleetchartVehicles = response.data
      }
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
