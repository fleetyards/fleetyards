<template>
  <section class="container">
    <div class="row">
      <div class="col-xs-12">
        <BreadCrumbs :crumbs="crumbs" />
        <h1 v-if="shop">
          {{ shop.name }}
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
          <ShopBaseMetrics
            :shop="shop"
            padding
          />
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
            <span v-show="isFilterSelected">
              <i class="fas fa-filter" />
            </span>
            <span v-show="!isFilterSelected">
              <i class="far fa-filter" />
            </span>
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
        <Panel v-if="shop">
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
              v-if="!loading && !commodities.length"
              key="empty"
              class="fade-list-item col-xs-12 flex-list-item"
            >
              <div class="flex-list-row">
                <div class="empty">
                  {{ $t('labels.blank.shopCommodities') }}
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
import BreadCrumbs from 'frontend/components/BreadCrumbs'
import { mapGetters } from 'vuex'

export default {
  components: {
    Loader,
    Panel,
    ShopBaseMetrics,
    ShopItemRow,
    FilterForm,
    Btn,
    BreadCrumbs,
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
      'mobile',
    ]),

    ...mapGetters('shop', [
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

    station() {
      return this.shop.station
    },

    crumbs() {
      if (!this.shop) {
        return null
      }

      const crumbs = [{
        to: {
          name: 'starsystems',
          hash: `#${this.shop.celestialObject.starsystem.slug}`,
        },
        label: this.$t('nav.starsystems'),
      }, {
        to: {
          name: 'starsystem',
          params: {
            slug: this.shop.celestialObject.starsystem.slug,
          },
          hash: `#${this.shop.celestialObject.slug}`,
        },
        label: this.shop.celestialObject.starsystem.name,
      }]

      if (this.shop.celestialObject.parent) {
        crumbs.push({
          to: {
            name: 'celestial-object',
            params: {
              starsystem: this.shop.celestialObject.starsystem.slug,
              slug: this.shop.celestialObject.parent.slug,
            },
          },
          label: this.shop.celestialObject.parent.name,
        })
      }

      crumbs.push({
        to: {
          name: 'celestial-object',
          params: {
            starsystem: this.shop.celestialObject.starsystem.slug,
            slug: this.shop.celestialObject.slug,
          },
          hash: `#${this.station.slug}`,
        },
        label: this.shop.celestialObject.name,
      })

      crumbs.push({
        to: {
          name: 'station',
          params: {
            slug: this.station.slug,
          },
        },
        label: this.station.name,
      })

      return crumbs
    },
  },

  watch: {
    $route() {
      this.fetchCommodities()
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
