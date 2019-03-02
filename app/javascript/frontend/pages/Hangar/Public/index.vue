<template>
  <section class="container hangar">
    <div class="row">
      <div class="col-xs-12 col-md-12">
        <div class="row">
          <div class="col-xs-12" />
        </div>
        <div class="row">
          <div class="col-xs-12">
            <h1>{{ t('headlines.hangarPublic', { user: usernamePlural }) }}</h1>
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
            v-if="vehicles.length > 0 || fleetchartVehicles.length > 0"
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
                <template v-else>
                  {{ t('actions.showFleetchart') }}
                </template>
              </Btn>
            </div>
          </div>
        </div>
        <transition
          name="fade"
          appear
        >
          <div
            v-if="hangarPublicFleetchartVisible && fleetchartVehicles.length > 0"
            class="row"
          >
            <div class="col-xs-12 col-md-4 col-md-offset-4 fleetchart-slider">
              <FleetchartSlider
                ref="fleetchartSlider"
                scale-key="HangarPublicFleetchartScale"
              />
            </div>
          </div>
        </transition>
        <div
          v-if="hangarPublicFleetchartVisible"
          class="row"
        >
          <div class="col-xs-12 fleetchart-wrapper">
            <transition-group
              id="fleetchart"
              name="fade-list"
              class="flex-row fleetchart"
              tag="div"
              appear
            >
              <FleetchartItem
                v-for="vehicle in fleetchartVehicles"
                :key="vehicle.id"
                :model="vehicle.model"
                :scale="HangarPublicFleetchartScale"
              />
            </transition-group>
          </div>
        </div>
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
            class="col-xs-12 col-sm-6 col-lg-4 col-xxlg-2-4 fade-list-item"
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
import FleetchartItem from 'frontend/partials/Models/FleetchartItem'
import I18n from 'frontend/mixins/I18n'
import MetaInfo from 'frontend/mixins/MetaInfo'
import Pagination from 'frontend/mixins/Pagination'
import ModelClassLabels from 'frontend/partials/Models/ClassLabels'
import Btn from 'frontend/components/Btn'
import { mapGetters } from 'vuex'
import html2canvas from 'html2canvas'
import download from 'downloadjs'
import FleetchartSlider from 'frontend/partials/FleetchartSlider'

export default {
  components: {
    ModelPanel,
    Loader,
    Btn,
    ModelClassLabels,
    FleetchartItem,
    FleetchartSlider,
  },
  mixins: [I18n, MetaInfo, Pagination],
  data() {
    return {
      loading: false,
      downloading: false,
      vehicles: [],
      fleetchartVehicles: [],
      vehiclesCount: null,
    }
  },
  computed: {
    ...mapGetters([
      'hangarPublicFleetchartVisible',
      'HangarPublicFleetchartScale',
    ]),
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
      this.fetch()
    },
    hangarPublicFleetchartVisible() {
      this.fetch()
    },
  },
  created() {
    this.fetch()
  },
  methods: {
    toggleFleetchart() {
      this.$store.dispatch('toggleHangarPublicFleetchart')
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
      if (this.hangarPublicFleetchartVisible) {
        this.fetchFleetchart()
      } else {
        this.fetchVehicles()
      }
    },
    async fetchVehicles() {
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
      const response = await this.$api.get(`vehicles/${this.username}/count`)
      if (!response.error) {
        this.vehiclesCount = response.data
      }
    },
    async fetchFleetchart() {
      this.loading = true
      const response = await this.$api.get(`vehicles/${this.username}/fleetchart`)
      this.loading = false
      this.$nextTick(() => {
        if (this.$refs.fleetchartSlider) {
          this.$refs.fleetchartSlider.refresh()
        }
      })
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
