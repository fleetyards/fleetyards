<template>
  <section class="container">
    <div class="row">
      <div class="col-xs-12">
        <h1 v-if="shop">
          <router-link
            :to="backRoute"
            class="back-button"
          >
            <i class="fal fa-chevron-left" />
          </router-link>
          {{ shop.name }}
          <small>
            {{ shop.station.name }}
          </small>
        </h1>
      </div>
    </div>
    <div class="row">
      <div
        v-if="shop"
        class="col-xs-12 col-md-8"
      >
        <blockquote
          v-if="shop.description"
          class="description"
        >
          <p v-html="shop.description" />
        </blockquote>
      </div>
      <div
        v-if="shop"
        class="col-xs-12 col-md-4"
      >
        <Panel>
          <ul class="list-group">
            <li class="list-group-item">
              <ShopBaseMetrics :shop="shop" />
            </li>
          </ul>
        </Panel>
      </div>
    </div>
    <div class="row">
      <div class="col-xs-12 col-md-8">
        <div class="page-actions page-actions-left">
          <Btn
            v-tooltip="toggleFiltersTooltip"
            :active="filterVisible"
            :aria-label="toggleFiltersTooltip"
            size="small"
            @click.native="toggleFilter"
          >
            <i
              v-if="isFilterSelected"
              class="fas fa-filter"
            />
            <i
              v-else
              class="far fa-filter"
            />
          </Btn>
          <template v-if="!mobile">
            <Btn
              v-for="item in subCategories"
              :key="item.value"
              size="small"
              :class="{
                active: (subCategory || []).includes(item.value)
              }"
              @click.native="toggleSubcategory(item.value)"
            >
              {{ item.name }}
            </Btn>
          </template>
        </div>
      </div>
      <div class="col-xs-12 col-md-4">
        <Paginator
          v-if="commodities.length"
          :page="currentPage"
          :total="totalPages"
          right
        />
      </div>
    </div>

    <div class="row">
      <transition
        name="slide"
        appear
        @before-enter="toggleFullscreen"
        @after-leave="toggleFullscreen"
      >
        <div
          v-show="filterVisible"
          class="col-xs-12 col-md-3 col-xlg-2"
        >
          <FilterForm />
        </div>
      </transition>
      <div
        :class="{
          'col-md-9 col-xlg-10': !fullscreen,
        }"
        class="col-xs-12 col-animated"
      >
        <Panel v-if="commodities.length && shop">
          <transition-group
            name="fade"
            class="flex-list"
            tag="div"
            appear
          >
            <div
              key="heading"
              class="fade-list-item col-xs-12 flex-list-heading"
            >
              <div class="flex-list-row">
                <div class="store-image" />
                <div class="description" />
                <div
                  v-if="shop.selling"
                  class="price"
                >
                  {{ $t('labels.shop.sellPrice') }}
                </div>
                <div
                  v-if="shop.buying"
                  class="price"
                >
                  {{ $t('labels.shop.buyPrice') }}
                </div>
                <div
                  v-if="shop.rental"
                  class="rent-price"
                >
                  {{ $t('labels.shop.rentPrice') }}
                </div>
              </div>
            </div>
            <div
              v-for="(commodity, index) in commodities"
              :key="`commodities-${index}`"
              class="fade-list-item col-xs-12 flex-list-item"
            >
              <ShopItemRow
                :commodity="commodity"
                :selling="shop.selling"
                :rental="shop.rental"
                :buying="shop.buying"
              />
            </div>
          </transition-group>
        </Panel>
        <Loader
          :loading="loading"
          fixed
        />
      </div>
    </div>
    <div class="row">
      <div class="col-xs-12">
        <Paginator
          v-if="commodities.length"
          :page="currentPage"
          :total="totalPages"
          right
        />
      </div>
    </div>
  </section>
</template>

<script>
import MetaInfo from 'frontend/mixins/MetaInfo'
import Loader from 'frontend/components/Loader'
import Hash from 'frontend/mixins/Hash'
import Panel from 'frontend/components/Panel'
import ShopBaseMetrics from 'frontend/partials/Shops/BaseMetrics'
import ShopItemRow from 'frontend/partials/Shops/ShopItemRow'
import FilterForm from 'frontend/partials/Shops/ShopItemFilterForm'
import Pagination from 'frontend/mixins/Pagination'
import Filters from 'frontend/mixins/Filters'
import Btn from 'frontend/components/Btn'
import { mapGetters } from 'vuex'

export default {
  components: {
    Loader,
    Panel,
    ShopBaseMetrics,
    ShopItemRow,
    FilterForm,
    Btn,
  },

  mixins: [
    MetaInfo,
    Filters,
    Hash,
    Pagination,
  ],

  data() {
    return {
      loading: false,
      shop: null,
      commodities: [],
      subCategories: [],
      fullscreen: false,
    }
  },

  computed: {
    ...mapGetters([
      'previousRoute',
      'mobile',
    ]),

    ...mapGetters('shop', [
      'backRoute',
      'filterVisible',
    ]),

    toggleFiltersTooltip() {
      if (this.filterVisible) {
        return this.$t('actions.hideFilter')
      }
      return this.$t('actions.showFilter')
    },

    title() {
      if (!this.shop) {
        return ''
      }
      return this.$t('title.shop', { shop: this.shop.name, station: this.shop.station.name })
    },

    subCategory() {
      if (!this.$route.query || !this.$route.query.q || !this.$route.query.q.subCategoryIn) {
        return null
      }

      return this.$route.query.q.subCategoryIn
    },
  },

  watch: {
    $route() {
      this.fetchCommodities()
    },

    shop() {
      this.setBackRoute()
    },
  },

  async mounted() {
    if (this.mobile) {
      this.$store.commit('shop/setFilterVisible', false)
    }

    await this.fetch()

    this.toggleFullscreen()
  },

  methods: {
    setBackRoute() {
      if (this.shopBackRoute && this.previousRoute
        && ['model'].includes(this.previousRoute.name)) {
        return
      }

      const route = {
        name: 'shops',
        hash: `#${this.shop.station.slug}-${this.shop.slug}`,
      }

      if (this.previousRoute && ['shops', 'station', 'celestialObject'].includes(this.previousRoute.name)) {
        route.name = this.previousRoute.name
        route.params = this.previousRoute.params
        route.query = this.previousRoute.query
      }

      this.$store.commit('shop/setBackRoute', route)
    },

    toggleFullscreen() {
      this.fullscreen = !this.filterVisible
    },

    toggleFilter() {
      this.$store.dispatch('shop/toggleFilter')
    },

    toggleSubcategory(value) {
      if ((this.subCategory || []).includes(value)) {
        const q = {
          ...JSON.parse(JSON.stringify(this.$route.query.q)),
        }

        delete q.subCategoryIn

        this.$router.replace({
          name: this.$route.name,
          query: {
            ...this.$route.query,
            q: {
              ...q,
            },
          },
        }).catch((_err) => {})
      } else {
        this.$router.replace({
          name: this.$route.name,
          query: {
            ...this.$route.query,
            q: {
              ...this.$route.query.q,
              subCategoryIn: [value],
            },
          },
        }).catch((_err) => {})
      }
    },

    async fetchSubCategories() {
      const response = await this.$api.get('filters/shop-commodities/sub-categories', {
        stationSlug: this.shop.station.slug,
        shopSlug: this.shop.slug,
      })

      if (!response.error) {
        this.subCategories = response.data
        await this.fetchCommodities()
      }
    },

    async fetch() {
      const response = await this.$api.get(`stations/${this.$route.params.station}/shops/${this.$route.params.slug}`)
      if (!response.error) {
        this.shop = response.data
        await this.fetchSubCategories()
      }
    },

    async fetchCommodities() {
      this.loading = true
      const response = await this.$api.get(`stations/${this.$route.params.station}/shops/${this.$route.params.slug}/shop-commodities`, {
        q: {
          ...this.$route.query.q,
          subCategoryIn: this.subCategory,
        },
        page: this.$route.query.page,
      })
      this.loading = false
      if (!response.error) {
        this.commodities = response.data
        this.scrollToAnchor()
      }
      this.setPages(response.meta)
    },
  },
}
</script>
