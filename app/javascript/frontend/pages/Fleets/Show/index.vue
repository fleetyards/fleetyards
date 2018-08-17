<template>
  <section class="container">
    <div class="row">
      <div class="col-xs-12">
        <div class="row headlines">
          <div class="col-xs-12 col-md-8">
            <router-link
              :to="{ name: 'fleets' }"
              class="to-fleetyards"
            >
              <i class="fal fa-chevron-left" />
              <span class="brand">{{ t('app') }}</span>
            </router-link>
            <h1 v-if="fleet">
              <img :src="fleet.logo" >
              <a
                :href="`https://robertsspaceindustries.com/orgs/${fleet.sid}`"
                target="_blank"
                rel="noopener"
              >
                {{ fleetTitle }}
              </a>
              <span class="activities">
                <img
                  v-tooltip="fleet.mainActivity"
                  v-if="fleet"
                  :src="acitivtyIcons[fleet.mainActivity]"
                >
                <img
                  v-tooltip="fleet.secondaryActivity"
                  v-if="fleet"
                  :src="acitivtyIcons[fleet.secondaryActivity]"
                >
              </span>
            </h1>
            <h2 v-if="fleet">
              <span class="label label-success">
                {{ fleet.archetype }}
              </span>
              <span class="label label-danger">
                {{ fleet.commitment }}
              </span>
              <span
                v-if="fleet.rpg"
                class="label label-info"
              >
                {{ t('labels.fleet.rpg') }}
              </span>
              <span
                v-if="fleet.exclusive"
                class="label label-info"
              >
                {{ t('labels.fleet.exclusive') }}
              </span>
            </h2>
          </div>
          <div class="col-xs-12 col-md-4 text-right"/>
        </div>
        <div class="row">
          <ModelClassLabels
            v-if="fleetCount"
            :count-data="fleetCount"
            class="col-xs-12"
            filter-key="classificationIn"
          />
        </div>
        <div class="row">
          <div class="col-xs-12">
            <Box
              v-if="!isMember && myFleet && fleet"
              class="row"
              large
            >
              You seem to be a Member of {{ fleet.name }}.
              To be able to view Ships of this Fleet you need to verify your RSI Handle

              <div
                slot="footer"
                class="pull-right"
              >
                <InternalLink
                  :route="{name: 'settings-verify'}"
                >
                  Verify your RSI-Handle
                </InternalLink>
              </div>
            </Box>
          </div>
        </div>
        <div class="row">
          <div class="col-xs-12">
            <Paginator
              v-if="fleetModels.length"
              :page="currentPage"
              :total="totalPages"
            />
          </div>
        </div>
        <div
          v-if="isMember"
          class="row"
        >
          <div class="col-md-9 col-xlg-10">
            <transition-group
              name="fade-list"
              class="flex-row"
              tag="div"
              appear
            >
              <div
                v-for="fleetModel in fleetModels"
                :key="fleetModel.slug"
                class="fade-list-item col-xs-12 col-sm-6 col-lg-4 col-xlg-3"
              >
                <ModelPanel
                  :model="fleetModel"
                  :count="count(fleetModel.slug)"
                />
              </div>
            </transition-group>
            <Loader
              v-if="loading"
              fixed
            />
          </div>
          <div class="hidden-xs hidden-sm col-md-3 col-xlg-2">
            <ModelsFilterForm :filters="filters" />
          </div>
          <ModelsFilterModal
            ref="filterModal"
            :filters="filters"
          />
        </div>
        <div class="row">
          <div class="col-xs-12">
            <Paginator
              v-if="fleetModels.length"
              :page="currentPage"
              :total="totalPages"
            />
          </div>
        </div>
      </div>
    </div>
  </section>
</template>

<script>
import { mapGetters } from 'vuex'
import Loader from 'frontend/components/Loader'
import InternalLink from 'frontend/components/InternalLink'
import Box from 'frontend/components/Box'
import ModelPanel from 'frontend/partials/Models/Panel'
import I18n from 'frontend/mixins/I18n'
import Pagination from 'frontend/mixins/Pagination'
import MetaInfo from 'frontend/mixins/MetaInfo'
import ModelsFilterForm from 'frontend/partials/Models/FilterForm'
import ModelsFilterModal from 'frontend/partials/Models/FilterModal'
import ModelClassLabels from 'frontend/partials/Models/ClassLabels'

export default {
  components: {
    ModelPanel,
    Loader,
    ModelsFilterForm,
    ModelsFilterModal,
    ModelClassLabels,
    InternalLink,
    Box,
  },
  mixins: [I18n, MetaInfo, Pagination],
  data() {
    return {
      loading: false,
      fleetCount: null,
      fleet: null,
      fleetModels: [],
      filters: [],
      acitivtyIcons: {
        /* eslint-disable global-require */
        BountyHunting: require('images/org-icons/bountyhunting.png'),
        Freelancing: require('images/org-icons/freelancing.png'),
        Trading: require('images/org-icons/trade.png'),
        Social: require('images/org-icons/social.png'),
        Engineering: require('images/org-icons/engineering.png'),
        Piracy: require('images/org-icons/piracy.png'),
        Infiltration: require('images/org-icons/infiltration.png'),
        Exploration: require('images/org-icons/exploration.png'),
        Resources: require('images/org-icons/resources.png'),
        Scouting: require('images/org-icons/scouting.png'),
        Security: require('images/org-icons/security.png'),
        Smuggling: require('images/org-icons/smuggling.png'),
        Transport: require('images/org-icons/transport.png'),
        /* eslint-enable global-require */
      },
    }
  },
  computed: {
    ...mapGetters([
      'currentUser',
    ]),
    fleetTitle() {
      if (!this.fleet) {
        return ''
      }
      return `${this.fleet.name} (${this.fleet.sid.toUpperCase()})`
    },
    myFleet() {
      if (!this.currentUser) {
        return false
      }
      return (this.currentUser.fleets || []).includes(this.$route.params.sid.toUpperCase())
    },
    isMember() {
      if (!this.currentUser) {
        return false
      }

      return this.myFleet && this.currentUser.rsiVerified
    },
  },
  watch: {
    $route() {
      this.fetchModels()
    },
    currentUser() {
      if (this.isMember) {
        this.fetchModels()
        this.fetchFilters()
        this.fetchCount()
      }
    },
  },
  created() {
    this.fetch()
    if (this.isMember) {
      this.fetchModels()
      this.fetchFilters()
      this.fetchCount()
    }
  },
  methods: {
    count(slug) {
      if (!this.fleetCount) {
        return null
      }
      return this.fleetCount.models[slug]
    },
    async fetch() {
      const response = await this.$api.get(`fleets/${this.$route.params.sid}`, {})
      this.loading = false
      if (!response.error) {
        this.fleet = response.data
        if (response.data.background) {
          this.$store.commit('setBackgroundImage', response.data.background)
        }
      }
    },
    async fetchModels() {
      this.loading = true
      const response = await this.$api.get(`fleets/${this.$route.params.sid}/models`, {
        q: this.$route.query.q,
        page: this.$route.query.page,
      })
      this.loading = false
      if (!response.error) {
        this.fleetModels = response.data
      }
      this.setPages(response.meta)
    },
    async fetchCount() {
      const response = await this.$api.get(`fleets/${this.$route.params.sid}/count`, {})
      if (!response.error) {
        this.fleetCount = response.data
      }
    },
    async fetchFilters() {
      const response = await this.$api.get('models/filters', {})
      if (!response.error) {
        this.filters = response.data
      }
    },
  },
  metaInfo() {
    return this.getMetaInfo({
      title: this.fleetTitle,
    })
  },
}
</script>

<style lang="scss" scoped>
  @import "./styles/index";
</style>
