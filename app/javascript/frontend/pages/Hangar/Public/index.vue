<template>
  <section class="container hangar">
    <div v-if="user" class="row">
      <div class="col-xs-12 col-md-12">
        <div class="row">
          <div class="col-xs-12" />
        </div>
        <div class="row">
          <div class="col-xs-12 col-md-8">
            <h1>
              <Avatar :avatar="user.avatar" />
              <span>
                {{ $t('headlines.hangar.public', { user: usernamePlural }) }}
              </span>
            </h1>
          </div>
          <div class="col-xs-12 col-md-4 hangar-profile-links">
            <a
              v-if="user.homepage"
              v-tooltip="$t('labels.homepage')"
              :href="user.homepage"
              target="_blank"
              rel="noopener"
            >
              <i class="fad fa-home" />
            </a>
            <a
              v-if="user.rsiHandle"
              v-tooltip="$t('nav.rsiProfile')"
              :href="
                `https://robertsspaceindustries.com/citizens/${user.rsiHandle}`
              "
              target="_blank"
              rel="noopener"
            >
              <i class="icon icon-rsi" />
            </a>
            <a
              v-if="user.guilded"
              v-tooltip="$t('labels.guilded')"
              :href="user.guilded"
              target="_blank"
              rel="noopener"
            >
              <i class="icon icon-guilded" />
            </a>
            <a
              v-if="user.discord"
              v-tooltip="$t('labels.discord')"
              :href="user.discord"
              target="_blank"
              rel="noopener"
            >
              <i class="fab fa-discord" />
            </a>
            <a
              v-if="user.youtube"
              v-tooltip="$t('labels.youtube')"
              :href="user.youtube"
              target="_blank"
              rel="noopener"
            >
              <i class="fab fa-youtube" />
            </a>
            <a
              v-if="user.twitch"
              v-tooltip="$t('labels.twitch')"
              :href="user.twitch"
              target="_blank"
              rel="noopener"
            >
              <i class="fab fa-twitch" />
            </a>
          </div>
        </div>
        <div class="row">
          <div class="col-xs-12 col-md-9">
            <ModelClassLabels
              v-if="vehiclesCount"
              :label="$t('labels.hangar')"
              :count-data="vehiclesCount.classifications"
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
              <Btn size="small" @click.native="toggleFleetchart">
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
        <transition name="fade" appear>
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

        <FleetchartList
          v-if="publicFleetchartVisible"
          :items="fleetchartVehicles"
          :on-addons="showAddonsModal"
          :scale="publicFleetchartScale"
        />

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
              :on-addons="showAddonsModal"
            />
          </div>
        </transition-group>
        <Loader :loading="loading" fixed />
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

    <AddonsModal ref="addonsModal" />
  </section>
</template>

<script>
import { mapGetters } from 'vuex'
import Btn from 'frontend/components/Btn'
import Loader from 'frontend/components/Loader'
import DownloadScreenshotBtn from 'frontend/components/DownloadScreenshotBtn'
import ModelPanel from 'frontend/components/Models/Panel'
import FleetchartList from 'frontend/partials/Fleetchart/List'
import FleetchartSlider from 'frontend/partials/Fleetchart/Slider'
import ModelClassLabels from 'frontend/partials/Models/ClassLabels'
import MetaInfo from 'frontend/mixins/MetaInfo'
import Pagination from 'frontend/mixins/Pagination'
import AddonsModal from 'frontend/partials/Vehicles/AddonsModal'
import Avatar from 'frontend/components/Avatar'

export default {
  name: 'PublicHangar',

  components: {
    Btn,
    AddonsModal,
    Loader,
    DownloadScreenshotBtn,
    ModelPanel,
    FleetchartList,
    ModelClassLabels,
    FleetchartSlider,
    Avatar,
  },

  mixins: [MetaInfo, Pagination],

  data() {
    return {
      loading: false,
      vehicles: [],
      user: null,
      fleetchartVehicles: [],
      vehiclesCount: null,
    }
  },

  computed: {
    ...mapGetters('hangar', [
      'publicFleetchartVisible',
      'publicFleetchartScale',
    ]),

    metaTitle() {
      return this.$t('title.hangar.public', { user: this.usernamePlural })
    },

    username() {
      return this.$route.params.user
    },

    usernamePlural() {
      if (
        this.userTitle.endsWith('s') ||
        this.userTitle.endsWith('x') ||
        this.userTitle.endsWith('z')
      ) {
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
    showAddonsModal(vehicle) {
      this.$refs.addonsModal.open(vehicle)
    },

    updateScale(value) {
      this.$store.commit('hangar/setPublicFleetchartScale', value)
    },

    toggleFleetchart() {
      this.$store.dispatch('hangar/togglePublicFleetchart')
    },

    fetch() {
      this.fetchUser()
      this.fetchFleetchart()
      this.fetchVehicles()
      this.fetchCount()
    },

    async fetchUser() {
      const response = await this.$api.get(`users/${this.username}`)

      if (!response.error) {
        this.user = response.data
      } else if (
        response.error.response &&
        response.error.response.status === 404
      ) {
        this.$router.replace({ name: '404' })
      }
    },

    async fetchVehicles() {
      this.loading = true

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
      const response = await this.$api.get(
        `vehicles/${this.username}/quick-stats`,
      )

      if (!response.error) {
        this.vehiclesCount = response.data
      }
    },

    async fetchFleetchart() {
      this.loading = true

      const response = await this.$api.get(
        `vehicles/${this.username}/fleetchart`,
      )

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
