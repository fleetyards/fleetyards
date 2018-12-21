<template>
  <section class="container">
    <div class="row">
      <div class="col-xs-12">
        <h1
          v-if="shop"
          class="back-button"
        >
          {{ shop.name }}
          <small>
            {{ shop.station.name }}
          </small>
          <router-link
            :to="shopBackRoute"
            class="btn btn-link"
          >
            <i class="fal fa-chevron-left" />
          </router-link>
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
      <div class="col-xs-12 col-md-6">
        <div class="page-actions page-actions-left">
          <Btn
            v-tooltip="toggleFiltersTooltip"
            :active="shopFilterVisible"
            :aria-label="toggleFiltersTooltip"
            small
            @click.native="toggleFilter"
          >
            <i
              v-if="isFilterSelected"
              class="fas fa-filter"
            />
            <i
              v-else
              class="fal fa-filter"
            />
          </Btn>
        </div>
      </div>
      <div class="col-xs-12 col-md-6">
        <div class="pull-right">
          <Paginator
            v-if="commodities.length"
            :page="currentPage"
            :total="totalPages"
          />
        </div>
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
          v-show="shopFilterVisible"
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
            name="fade-list"
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
                  {{ t('labels.shop.sellPrice') }}
                </div>
                <div
                  v-if="shop.buying"
                  class="price"
                >
                  {{ t('labels.shop.buyPrice') }}
                </div>
                <div
                  v-if="shop.rental"
                  class="rent-price"
                >
                  {{ t('labels.shop.rentPrice') }}
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
        <EmptyBox v-if="emptyBoxVisible" />
        <Loader
          :loading="loading"
          fixed
        />
      </div>
    </div>
    <div class="row">
      <div class="col-xs-12">
        <div class="pull-right">
          <Paginator
            v-if="commodities.length"
            :page="currentPage"
            :total="totalPages"
          />
        </div>
      </div>
    </div>
  </section>
</template>

<script>
import I18n from 'frontend/mixins/I18n'
import MetaInfo from 'frontend/mixins/MetaInfo'
import Loader from 'frontend/components/Loader'
import Hash from 'frontend/mixins/Hash'
import Panel from 'frontend/components/Panel'
import ShopBaseMetrics from 'frontend/partials/Shops/BaseMetrics'
import ShopItemRow from 'frontend/partials/Shops/ShopItemRow'
import FilterForm from 'frontend/partials/Shops/ShopItemFilterForm'
import EmptyBox from 'frontend/partials/EmptyBox'
import Pagination from 'frontend/mixins/Pagination'
import Filters from 'frontend/mixins/Filters'
import Btn from 'frontend/components/Btn'
import { mapGetters } from 'vuex'

export default {
  components: {
    Loader,
    EmptyBox,
    Panel,
    ShopBaseMetrics,
    ShopItemRow,
    FilterForm,
    Btn,
  },
  mixins: [I18n, MetaInfo, Filters, Hash, Pagination],
  data() {
    return {
      loading: false,
      shop: null,
      commodities: [],
      fullscreen: false,
    }
  },
  computed: {
    ...mapGetters([
      'previousRoute',
      'shopBackRoute',
      'shopFilterVisible',
      'mobile',
    ]),
    toggleFiltersTooltip() {
      if (this.shopFilterVisible) {
        return this.t('actions.hideFilter')
      }
      return this.t('actions.showFilter')
    },
    emptyBoxVisible() {
      return !this.loading && this.commodities.length === 0
    },
    title() {
      if (!this.shop) {
        return ''
      }
      return this.t('title.shop', { shop: this.shop.name, station: this.shop.station.name })
    },
  },
  watch: {
    $route() {
      this.fetchCommodities()
    },
    shop() {
      this.setBackRoute()
      if (this.shop.storeImage) {
        this.$store.commit('setBackgroundImage', this.shop.storeImage)
      }
    },
  },
  created() {
    this.fetch()
    if (this.mobile) {
      this.$store.commit('setShopFilterVisible', false)
    }
    this.fetchCommodities()
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

      this.$store.commit('setShopBackRoute', route)
    },
    toggleFullscreen() {
      this.fullscreen = !this.shopFilterVisible
    },
    toggleFilter() {
      this.$store.dispatch('toggleShopFilter')
    },
    async fetch() {
      const response = await this.$api.get(`stations/${this.$route.params.station}/shops/${this.$route.params.slug}`)
      if (!response.error) {
        this.shop = response.data
      }
    },
    async fetchCommodities() {
      this.loading = true
      const response = await this.$api.get(`stations/${this.$route.params.station}/shops/${this.$route.params.slug}/shop-commodities`, {
        q: this.$route.query.q,
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
  metaInfo() {
    return this.getMetaInfo({
      title: this.title,
    })
  },
}
</script>

<style>

</style>
