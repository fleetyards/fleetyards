<template>
  <section class="container">
    <div class="row">
      <div class="col-12 col-md-8">
        <BreadCrumbs :crumbs="crumbs" />
        <h1 v-if="shop">
          {{ shop.name }}
          <small class="text-muted">{{ shop.location }}</small>
        </h1>
      </div>
      <div class="col-12 col-md-4">
        <div class="page-actions page-actions-right">
          <PriceModalBtn
            v-if="shop"
            :station-slug="shop.station.slug"
            :shop-id="shop.id"
          />
        </div>
      </div>
    </div>
    <div class="row">
      <div v-if="shop" class="col-12 col-lg-8">
        <blockquote v-if="shop.description" class="description">
          <p v-html="shop.description" />
        </blockquote>
      </div>
      <div v-if="shop" class="col-12 col-lg-4">
        <Panel>
          <ShopBaseMetrics :shop="shop" padding />
        </Panel>
      </div>
    </div>

    <FilteredList
      key="shop"
      :collection="collection"
      :name="$route.name"
      :route-query="$route.query"
      :params="$route.params"
      :hash="$route.hash"
      :paginated="true"
      :hide-empty-box="true"
      :hide-loading="true"
    >
      <FilterForm slot="filter" />

      <template v-if="!mobile" slot="actions">
        <Btn
          v-for="item in subCategories"
          :key="item.value"
          size="small"
          :class="{
            active: (subCategory || []).includes(item.value),
          }"
          @click.native="toggleSubcategory(item.value)"
        >
          {{ item.name }}
        </Btn>
      </template>

      <template #default="{ records, loading, emptyBoxVisible, primaryKey }">
        <FilteredTable
          :records="records"
          :primary-key="primaryKey"
          :columns="tableColumns"
          :loading="loading"
          :empty-box-visible="emptyBoxVisible"
        >
          <template #col-store_image="{ record }">
            <router-link
              v-if="record.category === 'model'"
              :to="{
                name: 'model',
                params: {
                  slug: record.slug,
                },
              }"
            >
              <div
                :key="record.storeImageSmall"
                v-lazy:background-image="record.storeImageSmall"
                class="image lazy"
                alt="storeImage"
              />
            </router-link>
            <div
              v-else
              :key="record.storeImageSmall"
              v-lazy:background-image="record.storeImageSmall"
              class="image lazy"
              alt="storeImage"
            />
          </template>
          <template #col-description="{ record }">
            <h2>
              <router-link v-if="link(record)" :to="link(record)">
                <span v-html="name(record)" />
              </router-link>
              <span v-else v-html="name(record)" />
              <small class="text-muted">{{ record.subCategoryLabel }}</small>
            </h2>
            <div class="row">
              <div class="col-12 col-lg-6">
                <ul class="list-unstyled">
                  <li v-if="record.item.grade">
                    <b>{{ $t('commodityItem.grade') }}:</b>
                    {{ record.item.grade }}
                  </li>
                  <li v-if="record.item.size">
                    <b>{{ $t('commodityItem.size') }}:</b>
                    {{ record.item.size }}
                  </li>
                  <li v-if="record.item.typeLabel">
                    <b>{{ $t('commodityItem.type') }}:</b>
                    {{ record.item.typeLabel }}
                  </li>
                  <li v-if="record.item.itemTypeLabel">
                    <b>{{ $t('commodityItem.itemType') }}:</b>
                    {{ record.item.itemTypeLabel }}
                  </li>
                  <li v-if="record.item.weaponClassLabel">
                    <b>{{ $t('commodityItem.weaponClass') }}:</b>
                    {{ record.item.weaponClassLabel }}
                  </li>
                  <li v-if="record.item.itemClassLabel">
                    <b>{{ $t('commodityItem.itemClass') }}:</b>
                    {{ record.item.itemClassLabel }}
                  </li>
                </ul>
              </div>
              <div class="col-12 col-lg-6">
                <ul class="list-unstyled">
                  <li v-if="record.item.range">
                    <b>{{ $t('commodityItem.range') }}:</b>
                    {{ $toNumber(record.item.range, 'distance') }}
                  </li>
                  <li v-if="record.item.damageReduction">
                    <b>{{ $t('commodityItem.damageReduction') }}:</b>
                    {{ $toNumber(record.item.damageReduction, 'percent') }}
                  </li>
                  <li v-if="record.item.rateOfFire">
                    <b>{{ $t('commodityItem.rateOfFire') }}:</b>
                    {{ $toNumber(record.item.rateOfFire, 'rateOfFire') }}
                  </li>
                  <li v-if="record.item.extras">
                    {{ record.item.extras }}
                  </li>
                </ul>
              </div>
            </div>
            {{ record.description }}
          </template>
          <template #col-buy_price="{ record }">
            <span v-if="mobile" class="price-label">
              {{ $t('labels.shopCommodity.prices.buyPrice') }}:&nbsp;
            </span>
            <b v-html="$toUEC(record.buyPrice)" />
          </template>
          <template #col-sell_price="{ record }">
            <span v-if="mobile" class="price-label">
              {{ $t('labels.shopCommodity.prices.sellPrice') }}:&nbsp;
            </span>
            <b v-html="$toUEC(record.sellPrice)" />
          </template>
          <template #col-rental_price="{ record }">
            <span v-if="mobile" class="price-label">
              {{ $t('labels.shopCommodity.prices.rentalPrice') }}:&nbsp;
            </span>
            <ul class="list-unstyled">
              <li v-if="record.rentalPrice1Day">
                {{ $t('labels.shopCommodity.prices.rentalPrice1Day') }}
                <b v-html="$toUEC(record.rentalPrice1Day)" />
              </li>
              <li v-if="record.rentalPrice3Days">
                {{ $t('labels.shopCommodity.prices.rentalPrice3Days') }}
                <b v-html="$toUEC(record.rentalPrice3Days)" />
              </li>
              <li v-if="record.rentalPrice7Days">
                {{ $t('labels.shopCommodity.prices.rentalPrice7Days') }}
                <b v-html="$toUEC(record.rentalPrice7Days)" />
              </li>
              <li v-if="record.rentalPrice30Days">
                {{ $t('labels.shopCommodity.prices.rentalPrice30Days') }}
                <b v-html="$toUEC(record.rentalPrice30Days)" />
              </li>
            </ul>
          </template>
          <template #col-actions="{ record }">
            <AddToCartBtn
              :item="record.item"
              :type="record.commodityItemType"
            />
          </template>
        </FilteredTable>
      </template>
    </FilteredList>
  </section>
</template>

<script lang="ts">
import Vue from 'vue'
import { Component } from 'vue-property-decorator'
import MetaInfo from 'frontend/mixins/MetaInfo'
import Panel from 'frontend/core/components/Panel'
import ShopBaseMetrics from 'frontend/components/Shops/BaseMetrics'
import PriceModalBtn from 'frontend/components/ShopCommodities/PriceModalBtn'
import FilterForm from 'frontend/components/Shops/ShopItemFilterForm'
import Btn from 'frontend/core/components/Btn'
import FilteredList from 'frontend/core/components/FilteredList'
import FilteredTable from 'frontend/core/components/FilteredTable'
import BreadCrumbs from 'frontend/core/components/BreadCrumbs'
import { Getter } from 'vuex-class'
import shopCommoditiesCollection from 'frontend/api/collections/ShopCommodities'
import shopsCollection from 'frontend/api/collections/Shops'
import AddToCartBtn from 'frontend/core/components/AppShoppingCart/AddToCartBtn'
import { shopRouteGuard } from 'frontend/utils/RouteGuards'

@Component<Shop>({
  beforeRouteEnter: shopRouteGuard,
  components: {
    ShopBaseMetrics,
    FilterForm,
    Btn,
    Panel,
    PriceModalBtn,
    BreadCrumbs,
    FilteredList,
    FilteredTable,
    AddToCartBtn,
  },

  mixins: [MetaInfo],
})
export default class Shop extends Vue {
  collection: ShopCommoditiesCollection = shopCommoditiesCollection

  subCategories = []

  @Getter('mobile') mobile

  get shop() {
    return shopsCollection.record
  }

  get tableColumns() {
    const columns = [
      { name: 'store_image', class: 'store-image' },
      { name: 'description', class: 'description' },
    ]

    if (this.shop.buying) {
      columns.push({
        name: 'buy_price',
        label: this.$t('labels.shop.buyPrice'),
        class: 'price',
      })
    }

    if (this.shop.selling) {
      columns.push({
        name: 'sell_price',
        label: this.$t('labels.shop.sellPrice'),
        class: 'price',
      })
    }

    if (this.shop.rental) {
      columns.push({
        name: 'rental_price',
        label: this.$t('labels.shop.rentalPrice'),
        class: 'rent-price',
      })
    }

    columns.push({ name: 'actions', class: 'actions actions-1x' })

    return columns
  }

  get title() {
    if (!this.shop) {
      return ''
    }
    return this.$t('title.shop', {
      shop: this.shop.name,
      station: this.shop.station.name,
    })
  }

  get subCategory() {
    if (
      !this.$route.query ||
      !this.$route.query.q ||
      !this.$route.query.q.subCategoryIn
    ) {
      return null
    }

    return this.$route.query.q.subCategoryIn
  }

  get station() {
    return this.shop.station
  }

  get crumbs() {
    if (!this.shop) {
      return null
    }

    const crumbs = [
      {
        to: {
          name: 'starsystems',
          hash: `#${this.shop.celestialObject.starsystem.slug}`,
        },
        label: this.$t('nav.starsystems'),
      },
      {
        to: {
          name: 'starsystem',
          params: {
            slug: this.shop.celestialObject.starsystem.slug,
          },
          hash: `#${this.shop.celestialObject.slug}`,
        },
        label: this.shop.celestialObject.starsystem.name,
      },
    ]

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
  }

  mounted() {
    if (this.shop) {
      this.fetchSubCategories()
    }
  }

  manufacturer(record) {
    if (!record.item || !record.item.manufacturer) {
      return null
    }

    return record.item.manufacturer
  }

  name(record) {
    if (this.manufacturer(record)) {
      if (this.manufacturer(record).code) {
        return `${this.manufacturer(record).code} ${record.name}`
      }
      return `${this.manufacturer(record).name} ${record.name}`
    }

    return record.name
  }

  link(record) {
    if (record.category !== 'model') {
      return null
    }

    return {
      name: 'model',
      params: {
        slug: record.slug,
      },
    }
  }

  toggleSubcategory(value) {
    if ((this.subCategory || []).includes(value)) {
      const q = {
        ...JSON.parse(JSON.stringify(this.$route.query.q)),
      }

      delete q.subCategoryIn

      this.$router
        .replace({
          name: this.$route.name,
          query: {
            ...this.$route.query,
            q: {
              ...q,
            },
          },
        })
        .catch(err => {
          console.info(err)
        })
    } else {
      this.$router
        .replace({
          name: this.$route.name,
          query: {
            ...this.$route.query,
            q: {
              ...this.$route.query.q,
              subCategoryIn: [value],
            },
          },
        })
        .catch(err => {
          console.info(err)
        })
    }
  }

  async fetchSubCategories() {
    const response = await this.$api.get(
      'filters/shop-commodities/sub-categories',
      {
        stationSlug: this.shop.station.slug,
        shopSlug: this.shop.slug,
      },
    )

    if (!response.error) {
      this.subCategories = response.data
    }
  }
}
</script>
