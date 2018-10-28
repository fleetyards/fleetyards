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
            :to="{
              name: 'station',
              params: {
                slug: shop.station.slug,
              },
              hash: `#${shop.slug}`,
            }"
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
    <div class="row">
      <div class="col-xs-12">
        <Panel v-if="commodities.length">
          <div class="table-responsive">
            <table class="table table-hover table-striped">
              <thead>
                <tr>
                  <th colspan="2" />
                  <th v-if="shop.selling">{{ t('labels.shop.sellPrice') }}</th>
                  <th v-if="shop.buying">{{ t('labels.shop.buyPrice') }}</th>
                  <th v-if="shop.rental">{{ t('labels.shop.rentPrice') }}</th>
                </tr>
              </thead>
              <transition-group
                name="fade"
                tag="tbody"
                appear
              >
                <tr
                  v-for="(commodity, index) in commodities"
                  :key="index"
                  :id="commodity.slug"
                  class="fade-item"
                >
                  <td class="store-image">
                    <router-link
                      v-if="link(commodity.commodityItem)"
                      :to="link(commodity.commodityItem)"
                    >
                      <div
                        v-lazy:background-image="commodity.commodityItem.storeImage"
                        :key="commodity.commodityItem.storeImage"
                        class="image"
                        alt="storeImage"
                      />
                    </router-link>
                    <div
                      v-lazy:background-image="commodity.commodityItem.storeImage"
                      v-else
                      :key="commodity.commodityItem.storeImage"
                      class="image"
                      alt="storeImage"
                    />
                  </td>
                  <td class="description">
                    <h2>
                      <router-link
                        v-if="link(commodity.commodityItem)"
                        :to="link(commodity.commodityItem)"
                      >
                        {{ commodity.commodityItem.name }}
                      </router-link>
                      <span v-else>
                        {{ commodity.commodityItem.type }}
                      </span>
                    </h2>
                    {{ commodity.commodityItem.description }}
                  </td>
                  <td
                    v-if="shop.selling"
                    class="price"
                  >
                    {{ toUEC(commodity.sellPrice) }}
                  </td>
                  <td
                    v-if="shop.buying"
                    class="price"
                  >
                    {{ toUEC(commodity.buyPrice) }}
                  </td>
                  <td
                    v-if="shop.rental"
                    class="price"
                  >
                    {{ t('shop.rentalPrice', { price: toUEC(commodity.rentPrice) }) }}
                  </td>
                </tr>
              </transition-group>
            </table>
          </div>
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
import EmptyBox from 'frontend/partials/EmptyBox'
import Pagination from 'frontend/mixins/Pagination'

export default {
  components: {
    Loader,
    EmptyBox,
    Panel,
    ShopBaseMetrics,
  },
  mixins: [I18n, MetaInfo, Hash, Pagination],
  data() {
    return {
      loading: false,
      shop: null,
      commodities: [],
    }
  },
  computed: {
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
      this.fetch()
      this.fetchCommodities()
    },
    shop() {
      if (this.shop.storeImage) {
        this.$store.commit('setBackgroundImage', this.shop.storeImage)
      }
    },
  },
  created() {
    this.fetch()
    this.fetchCommodities()
  },
  methods: {
    link(item) {
      if (item.type !== 'Model') {
        return null
      }
      return {
        name: 'model',
        params: {
          slug: item.slug,
        },
      }
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
