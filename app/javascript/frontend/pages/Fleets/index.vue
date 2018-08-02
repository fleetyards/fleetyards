<template>
  <section class="container">
    <div class="row">
      <div class="col-xs-12">
        <div class="row">
          <div class="col-xs-12">
            <h1 class="sr-only">{{ t('headlines.fleets') }}</h1>
          </div>
        </div>
        <div
          v-if="isAuthenticated"
          class="row"
        >
          <div class="col-xs-12">
            <h2 class="text-center">- My Fleets -</h2>
            <transition-group
              name="fade-list"
              class="flex-row"
              appear
            >
              <div
                v-for="fleet in myFleets"
                :key="fleet.sid"
                class="col-xs-12 col-sm-6 col-md-4 fade-list-item"
              >
                <FleetPanel
                  :fleet="fleet"
                />
              </div>
            </transition-group>
            <div class="text-center">
              <Btn
                large
                @click.native="create"
              >
                {{ t('actions.fleet.create') }}
              </Btn>
            </div>
            <br>
          </div>
        </div>

        <h2
          v-if="isAuthenticated"
          class="text-center"
        >
          - Other Fleets -
        </h2>
        <transition-group
          name="fade-list"
          class="flex-row"
          tag="div"
          appear
        >
          <div
            v-for="fleet in fleets"
            :key="fleet.sid"
            class="col-xs-12 col-sm-6 col-md-4 fade-list-item"
          >
            <FleetPanel
              :fleet="fleet"
            />
          </div>
        </transition-group>
        <InfiniteLoading
          v-if="fleets && fleets.length >= limit"
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
      </div>
    </div>
    <FleetModal
      ref="fleetModal"
      :callback="refetch"
    />
  </section>
</template>

<script>
import I18n from 'frontend/mixins/I18n'
import MetaInfo from 'frontend/mixins/MetaInfo'
import FleetModal from 'frontend/partials/Fleets/Modal'
import FleetPanel from 'frontend/partials/Fleets/Panel'
import Loader from 'frontend/components/Loader'
import Btn from 'frontend/components/Btn'
import { mapGetters } from 'vuex'

export default {
  components: {
    FleetModal,
    FleetPanel,
    Loader,
    Btn,
  },
  mixins: [I18n, MetaInfo],
  data() {
    return {
      fetchMoreQuery: 'fleets',
      limit: 30,
      loading: false,
      fleets: [],
      myFleets: [],
    }
  },
  computed: {
    ...mapGetters([
      'isAuthenticated',
    ]),
  },
  watch: {
    isAuthenticated() {
      this.refetch()
    },
  },
  created() {
    this.fetch()
    if (this.isAuthenticated) {
      this.fetchMyFleets()
    }
  },
  methods: {
    refetch() {
      this.$comlink.$emit('userUpdate')
      this.fetch()
      if (this.isAuthenticated) {
        this.fetchMyFleets()
      }
    },
    create() {
      this.$refs.fleetModal.open()
    },
    fetch() {
      this.loading = true
      this.$api.get('fleets', {
        limit: this.limit,
      }, (args) => {
        this.loading = false
        if (!args.error) {
          this.fleets = args.data
        }
      })
    },
    fetchMore($state) {
      this.loading = true
      this.offset += this.limit
      this.$api.get('fleets', {
        limit: this.limit,
        offset: this.offset,
      }, (args) => {
        this.loading = false
        $state.loaded()
        if (!args.error) {
          if (args.data.length === 0 || args.data.length < this.limit) {
            $state.complete()
          }

          args.data.forEach((fleet) => {
            this.fleets.push(fleet)
          })
        }
      })
    },
    fetchMyFleets() {
      this.$api.get('fleets/my', {}, (args) => {
        if (!args.error) {
          this.myFleets = args.data
        }
      })
    },
  },
  metaInfo() {
    return this.getMetaInfo({
      title: this.t('title.fleets'),
    })
  },
}
</script>

<style lang="scss" scoped>
  @import "./styles/index";
</style>
