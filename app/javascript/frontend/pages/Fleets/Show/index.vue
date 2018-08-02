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
          <div
            :class="{
              'col-md-9 col-xlg-10': myFleet,
            }"
            class="col-xs-12"
          >
            <transition-group
              name="fade-list"
              class="flex-row"
              tag="div"
              appear
            >
              <div
                v-for="fleetModel in fleetModels"
                :key="fleetModel.model.id"
                :class="{
                  'col-sm-6 col-md-4 col-lg-3 col-xlg-2': !myFleet,
                  'col-sm-6 col-lg-4 col-xlg-3': myFleet,
                }"
                class="fade-list-item col-xs-12"
              >
                <ModelPanel
                  :model="fleetModel.model"
                  :count="fleetModel.count"
                />
              </div>
            </transition-group>
            <InfiniteLoading
              v-if="fleetModels && fleetModels.length >= limit"
              ref="infiniteLoading"
              :distance="500"
              @infinite="fetchMore"
            >
              <span slot="no-more" />
              <span slot="spinner">
                <Loader
                  v-if="loading"
                  static />
              </span>
            </InfiniteLoading>
            <Loader
              v-if="loading"
              fixed
            />
          </div>
          <div
            v-if="myFleet"
            class="hidden-xs hidden-sm col-md-3 col-xlg-2"
          >
            <ModelsFilterForm />
          </div>
          <ModelsFilterModal
            ref="filterModal"
          />
        </div>
      </div>
    </div>
  </section>
</template>

<script>
import { mapGetters } from 'vuex'
import Loader from 'frontend/components/Loader'
import Btn from 'frontend/components/Btn'
import ModelPanel from 'frontend/partials/Models/Panel'
import I18n from 'frontend/mixins/I18n'
import MetaInfo from 'frontend/mixins/MetaInfo'
import ModelsFilterForm from 'frontend/partials/Models/FilterForm'
import ModelsFilterModal from 'frontend/partials/Models/FilterModal'
import ModelClassLabels from 'frontend/partials/Models/ClassLabels'
import InfiniteLoading from 'vue-infinite-loading'

export default {
  components: {
    ModelPanel,
    Loader,
    ModelsFilterForm,
    ModelsFilterModal,
    ModelClassLabels,
    InfiniteLoading,
    Btn,
  },
  mixins: [I18n, MetaInfo],
  data() {
    return {
      loading: false,
      limit: 30,
      offset: 0,
      fleetCount: null,
      fleet: null,
      fleetModels: [],
      acitivtyIcons: {
        /* eslint-disable global-require */
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
      return (this.currentUser.fleets || []).includes(this.$route.params.sid)
    },
  },
  watch: {
    $route() {
      this.fetchModels()
    },
    currentUser() {
      if (this.myFleet) {
        this.fetchModels()
        this.fetchCount()
      }
    },
  },
  created() {
    this.fetch()
    if (this.myFleet) {
      this.fetchModels()
      this.fetchCount()
    }
  },
  methods: {
    fetch() {
      this.$api.get(`fleets/${this.$route.params.sid}`, {}, (args) => {
        this.loading = false
        if (!args.error) {
          this.fleet = args.data
        }
      })
    },
    fetchModels() {
      this.loading = true
      this.$api.get(`fleets/${this.$route.params.sid}/models`, {
        q: this.$route.query.q,
        limit: this.limit,
      }, (args) => {
        this.loading = false

        this.offset = 0
        if (this.$refs.infiniteLoading) {
          this.$refs.infiniteLoading.$emit('$InfiniteLoading:reset')
        }

        if (!args.error) {
          this.fleetModels = args.data
        }
      })
    },
    fetchMore($state) {
      this.loading = true
      this.offset += this.limit
      this.$api.get(`fleets/${this.$route.params.sid}/models`, {
        q: this.$route.query.q,
        limit: this.limit,
        offset: this.offset,
      }, (args) => {
        this.loading = false
        $state.loaded()
        if (!args.error) {
          if (args.data.length === 0 || args.data.length < this.limit) {
            $state.complete()
          }

          args.data.forEach((model) => {
            this.fleetModels.push(model)
          })
        }
      })
    },
    fetchCount() {
      this.$api.get(`fleets/${this.$route.params.sid}/count`, {}, (args) => {
        if (!args.error) {
          this.fleetCount = args.data
        }
      })
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
