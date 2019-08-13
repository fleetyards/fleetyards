<template>
  <section class="container hangar">
    <div class="row">
      <div class="col-xs-12 col-md-12">
        <div class="row">
          <div class="col-xs-12" />
        </div>
        <div class="row">
          <div class="col-xs-12">
            <h1>
              <div class="avatar">
                <img
                  v-if="citizen && citizen.avatar"
                  :src="citizen.avatar"
                  alt="avatar"
                  width="36"
                  height="36"
                >
                <div
                  v-else
                  class="no-avatar"
                >
                  <i class="fa fa-user" />
                </div>
              </div>
              <template v-if="user && user.rsiHandle">
                <a
                  :href="`https://robertsspaceindustries.com/citizens/${user.rsiHandle}`"
                  target="_blank"
                  rel="noopener"
                >
                  {{ $t('headlines.hangar.public', { user: usernamePlural }) }}
                </a>
              </template>
              <template v-else>
                {{ $t('headlines.hangar.public', { user: usernamePlural }) }}
              </template>
            </h1>
          </div>
        </div>
        <div class="row">
          <div class="col-xs-12 col-md-9">
            <ModelClassLabels
              v-if="vehiclesCount"
              :label="$t('labels.hangar')"
              :count-data="vehiclesCount"
            />
          </div>
        </div>
        <div class="row">
          <div class="col-xs-12 col-md-6">
            <Paginator
              v-if="!publicFleetchartVisible && vehicles.length"
              :page="currentPage"
              :total="totalPages"
            />
          </div>
          <div
            v-if="vehicles.length > 0 || fleetchartVehicles.length > 0"
            class="col-xs-12 col-md-6"
          >
            <div class="page-actions">
              <DownloadScreenshotBtn
                v-if="publicFleetchartVisible"
                element="#fleetchart"
                :filename="`${username}-hangar-fleetchart`"
              />
              <Btn
                size="small"
                @click.native="toggleFleetchart"
              >
                <template v-if="publicFleetchartVisible">
                  {{ $t('actions.hideFleetchart') }}
                </template>
                <template v-else>
                  {{ $t('actions.showFleetchart') }}
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
            v-if="publicFleetchartVisible && fleetchartVehicles.length > 0"
            class="row"
          >
            <div class="col-xs-12 col-md-4 col-md-offset-4 fleetchart-slider">
              <FleetchartSlider
                :initial-scale="publicFleetchartScale"
                @change="updateScale"
              />
            </div>
          </div>
        </transition>
        <div
          v-if="publicFleetchartVisible"
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
                :scale="publicFleetchartScale"
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
          v-if="!publicFleetchartVisible && vehicles.length"
          :page="currentPage"
          :total="totalPages"
        />
      </div>
    </div>
  </section>
</template>

<script>
import { mapGetters } from 'vuex'
import Btn from 'frontend/components/Btn'
import Loader from 'frontend/components/Loader'
import DownloadScreenshotBtn from 'frontend/components/DownloadScreenshotBtn'
import ModelPanel from 'frontend/components/Models/Panel'
import FleetchartItem from 'frontend/partials/Models/FleetchartItem'
import ModelClassLabels from 'frontend/partials/Models/ClassLabels'
import FleetchartSlider from 'frontend/partials/FleetchartSlider'
import MetaInfo from 'frontend/mixins/MetaInfo'
import Pagination from 'frontend/mixins/Pagination'

export default {
  name: 'PublicHangar',

  components: {
    Btn,
    Loader,
    DownloadScreenshotBtn,
    ModelPanel,
    FleetchartItem,
    ModelClassLabels,
    FleetchartSlider,
  },

  mixins: [
    MetaInfo,
    Pagination,
  ],

  data() {
    return {
      loading: false,
      vehicles: [],
      user: null,
      citizen: null,
      fleetchartVehicles: [],
      vehiclesCount: null,
    }
  },

  computed: {
    ...mapGetters('hangar', [
      'publicFleetchartVisible',
      'publicFleetchartScale',
    ]),

    ...mapGetters('session', [
      'currentUser',
    ]),

    metaTitle() {
      return this.$t('title.hangar.public', { user: this.usernamePlural })
    },

    username() {
      return this.$route.params.user
    },

    usernamePlural() {
      if (this.userTitle.endsWith('s') || this.userTitle.endsWith('x') || this.userTitle.endsWith('z')) {
        return this.userTitle
      }

      return `${this.userTitle}'s`
    },

    userTitle() {
      return this.username[0].toUpperCase() + this.username.slice(1)
    },
  },

  watch: {
    $route() {
      this.fetch()
    },

    publicFleetchartVisible() {
      this.fetch()
    },
  },

  created() {
    if (this.$route.query.fleetchart && !this.publicFleetchartVisible) {
      this.$store.dispatch('hangar/togglePublicFleetchart')
    }

    this.fetch()
  },

  methods: {
    updateScale(value) {
      this.$store.commit('hangar/setPublicFleetchartScale', value)
    },

    toggleFleetchart() {
      this.$store.dispatch('hangar/togglePublicFleetchart')
    },

    fetch() {
      this.fetchUser()
      if (this.publicFleetchartVisible) {
        this.fetchFleetchart()
      } else {
        this.fetchVehicles()
      }
    },

    async fetchUser() {
      const response = await this.$api.get(`users/${this.username}`)

      if (!response.error) {
        this.user = response.data
        this.fetchCitizen()
      }
    },

    async fetchCitizen() {
      if (!this.user.rsiHandle) {
        return
      }

      const response = await this.$api.get(`rsi/citizens/${this.user.rsiHandle}`)
      if (!response.error) {
        this.citizen = response.data
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
      const response = await this.$api.get(`vehicles/${this.username}/quick-stats`)
      if (!response.error) {
        this.vehiclesCount = response.data
      }
    },

    async fetchFleetchart() {
      this.loading = true
      const response = await this.$api.get(`vehicles/${this.username}/fleetchart`)
      this.loading = false
      if (!response.error) {
        this.fleetchartVehicles = response.data
      }
    },
  },
}
</script>

<style lang="scss" scoped>
  @import 'index';
</style>
