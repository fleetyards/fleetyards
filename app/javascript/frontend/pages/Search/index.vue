<template>
  <section class="container search">
    <div class="row">
      <div class="col-xs-12">
        <h1 class="sr-only">
          {{ $t('headlines.search') }}
        </h1>
      </div>
    </div>
    <div class="row">
      <div class="col-xs-12">
        <div class="row">
          <div class="col-xs-12 col-md-6 col-md-push-3">
            <form @submit.prevent="filter">
              <FormInput
                v-model="form.search"
                :placeholder="$t('placeholders.search')"
                :aria-label="$t('placeholders.search')"
                size="large"
                autofocus
              />
              <br>
            </form>
          </div>
        </div>
      </div>
    </div>
    <div class="row">
      <div class="col-xs-12">
        <Paginator
          v-if="results.length"
          :page="currentPage"
          :total="totalPages"
          right
        />
      </div>
    </div>
    <div class="row">
      <div class="col-xs-12">
        <transition-group
          name="fade-list"
          class="flex-row"
          tag="div"
          appear
        >
          <div
            v-for="result in results"
            :key="`${result.resultType}-${result.id}`"
            class="col-xs-12 col-sm-6 col-xlg-4 col-xxlg-2-4 fade-list-item"
          >
            <ModelPanel
              v-if="result.resultType === 'model'"
              :model="result"
              details
            />
            <CelestialObjectsPanel
              v-else-if="['celestial_object', 'starsystem'].includes(result.resultType)"
              :item="result"
            />
            <ShopCommodityPanel
              v-else-if="result.resultType === 'shop_commodity'"
              :item="result"
            />
            <SearchPanel
              v-else
              :item="result"
            />
          </div>
        </transition-group>

        <EmptyBox
          v-if="emptyBoxVisible"
          ignore-filter
        />

        <SearchHistory
          v-if="historyVisible"
          @restore="restoreSearch"
        >
<Loader
            :loading="loading"
            fixed
          />
        </searchhistory>
</div>
    </div>
    <div class="row">
      <div class="col-xs-12">
        <Paginator
          v-if="results.length"
          :page="currentPage"
          :total="totalPages"
          right
        />
      </div>
    </div>
  </section>
</template>

<script>
import Filters from 'frontend/mixins/Filters'
import MetaInfo from 'frontend/mixins/MetaInfo'
import FormInput from 'frontend/components/Form/FormInput'
import Loader from 'frontend/components/Loader'
import ModelPanel from 'frontend/components/Models/Panel'
import SearchPanel from 'frontend/components/Search/Panel'
import CelestialObjectsPanel from 'frontend/components/CelestialObjects/Panel'
import ShopCommodityPanel from 'frontend/components/ShopCommodities/Panel'
import EmptyBox from 'frontend/partials/EmptyBox'
import SearchHistory from 'frontend/partials/Search/History'
import Pagination from 'frontend/mixins/Pagination'

export default {
  name: 'Search',

  components: {
    Loader,
    EmptyBox,
    ModelPanel,
    SearchPanel,
    CelestialObjectsPanel,
    ShopCommodityPanel,
    FormInput,
    SearchHistory,
  },

  mixins: [
    MetaInfo,
    Filters,
    Pagination,
  ],

  data() {
    const query = this.$route.query.q || {}
    return {
      form: {
        search: query.search,
      },
      results: [],
      loading: false,
      emptyBoxVisible: false,
    }
  },

  computed: {
    historyVisible() {
      return !this.loading && !this.results.length && !this.form.search
    },
  },

  watch: {
    $route() {
      const query = this.$route.query.q || {}
      this.form = {
        search: query.search,
      }
      this.fetch()
    },

    form: {
      handler() {
        if (!this.form.search) {
          this.emptyBoxVisible = false
        }

        this.filter()
      },
      deep: true,
    },

    results() {
      this.emptyBoxVisible = !this.loading && !this.results.length && this.form.search
    },
  },

  mounted() {
    this.fetch()
  },

  methods: {
    routeForResult(result) {
      switch (result.resultType) {
        case 'celestial_object':
          return {
            name: 'celestialObject',
            params: {
              slug: result.slug,
            },
          }
        case 'shop':
          return {
            name: 'shop',
            params: {
              station: result.station.slug,
              slug: result.slug,
            },
          }
        case 'starsystem':
          return {
            name: 'starsystem',
            params: {
              slug: result.slug,
            },
          }
        default:
          return null
      }
    },

    restoreSearch(search) {
      this.form.search = search
    },

    async fetch() {
      this.loading = true

      const response = await this.$api.get('search', {
        q: this.$route.query.q,
        page: this.$route.query.page,
      })

      this.loading = false

      if (!response.error) {
        this.results = response.data

        if (this.form.search) {
          this.$store.dispatch('search/save', { search: this.form.search, createdAt: new Date() })
        }
      }

      this.setPages(response.meta)
    },
  },
}
</script>
