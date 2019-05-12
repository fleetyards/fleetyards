<template>
  <section class="container">
    <div class="row">
      <div class="col-xs-12">
        <div class="row">
          <div class="col-xs-12">
            <h1 class="sr-only">
              {{ t('headlines.fleets') }}
            </h1>
          </div>
        </div>
        <div
          v-if="isAuthenticated"
          class="row"
        >
          <div class="col-xs-12">
            <h2 class="text-center">
              - My Fleets -
            </h2>
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
                size="large"
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
        <div class="row">
          <div class="col-xs-12">
            <Paginator
              v-if="fleets.length"
              :page="currentPage"
              :total="totalPages"
            />
          </div>
        </div>
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
        <EmptyBox v-if="!loading && !fleets.length" />
        <div class="row">
          <div class="col-xs-12">
            <Paginator
              v-if="fleets.length"
              :page="currentPage"
              :total="totalPages"
            />
          </div>
        </div>
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
import Pagination from 'frontend/mixins/Pagination'
import FleetModal from 'frontend/partials/Fleets/Modal'
import FleetPanel from 'frontend/partials/Fleets/Panel'
import EmptyBox from 'frontend/partials/EmptyBox'
import Btn from 'frontend/components/Btn'
import { mapGetters } from 'vuex'

export default {
  components: {
    FleetModal,
    FleetPanel,
    Btn,
    EmptyBox,
  },
  mixins: [I18n, MetaInfo, Pagination],
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
    ...mapGetters('session', [
      'isAuthenticated',
    ]),
  },
  watch: {
    isAuthenticated() {
      this.refetch()
    },
    $route() {
      this.fetch()
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
      this.fetch()
      if (this.isAuthenticated) {
        this.fetchMyFleets()
      }
    },
    create() {
      this.$refs.fleetModal.open()
    },
    async fetch() {
      this.loading = true
      const response = await this.$api.get('fleets', {
        page: this.$route.query.page,
      })
      this.loading = false
      if (!response.error) {
        this.fleets = response.data
      }
      this.setPages(response.meta)
    },
    async fetchMyFleets() {
      const response = await this.$api.get('fleets/my')
      if (!response.error) {
        this.myFleets = response.data
      }
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
  @import './styles/index';
</style>
