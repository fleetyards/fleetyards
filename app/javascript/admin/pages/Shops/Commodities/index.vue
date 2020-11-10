<template>
  <FilteredList
    :collection="collection"
    :name="$route.name"
    :route-query="$route.query"
    :hash="$route.hash"
    :params="routeParams"
    :paginated="true"
  >
    <template #actions>
      <Btn @click.native="openAddModal">
        {{ $t('actions.add') }}
      </Btn>
    </template>
    <template #default="{ records, primaryKey }">
      <FilteredTable
        :records="records"
        :primary-key="primaryKey"
        :columns="tableColumns"
      >
        <template #col-item="{ record }">
          {{ record.item.name }}
          <small>
            {{ record.item.typeLabel }}
            {{ record.item.itemTypeLabel }}
          </small>
        </template>
        <template #col-prices="{ record }">
          <div class="d-flex flex-column">
            <div
              v-for="price in prices"
              :key="`price-${records[primaryKey]}-${price}`"
            >
              <div v-if="record[price]" class="d-flex justify-content-between">
                {{ $t(`labels.shopCommodity.prices.${price}`) }}:
                <span>{{ $toUEC(record[price]) }}</span>
              </div>
            </div>
          </div>
        </template>
        <template #col-confirmed="{ record }">
          <i v-if="record.confirmed" class="fal fa-check" />
          <i v-else class="fal fa-times" />
        </template>
        <template #col-actions="{ record }">
          <BtnGroup :inline="true">
            <Btn
              size="small"
              variant="link"
              :inline="true"
              @click.native="openEditModal(record)"
            >
              {{ $t('actions.edit') }}
            </Btn>
            <BtnDropdown :inline="true" size="small" variant="link">
              <Btn
                size="small"
                variant="dropdown"
                @click.native="openSellPricesModal(record)"
              >
                <i class="fal fa-list" />
                {{ $t('labels.shopCommodity.sellPrices') }}
              </Btn>
              <Btn
                size="small"
                variant="dropdown"
                @click.native="openBuyPricesModal(record)"
              >
                <i class="fal fa-list" />
                {{ $t('labels.shopCommodity.buyPrices') }}
              </Btn>
              <Btn
                size="small"
                variant="dropdown"
                @click.native="openRentalPricesModal(record)"
              >
                <i class="fal fa-list" />
                {{ $t('labels.shopCommodity.rentalPrices') }}
              </Btn>
              <Btn
                size="small"
                variant="dropdown"
                :disabled="deleting"
                data-test="shopCommodity-delete"
                @click.native="remove(record)"
              >
                <i class="fal fa-trash" />
                {{ $t('actions.remove') }}
              </Btn>
            </BtnDropdown>
          </BtnGroup>
        </template>
      </FilteredTable>
    </template>
  </FilteredList>
</template>

<script lang="ts">
import Vue from 'vue'
import { Component } from 'vue-property-decorator'
import FilteredList from 'frontend/core/components/FilteredList'
import FilteredTable from 'frontend/core/components/FilteredTable'
import BtnGroup from 'frontend/core/components/BtnGroup'
import BtnDropdown from 'frontend/core/components/BtnDropdown'
import Btn from 'frontend/core/components/Btn'
import shopCommoditiesCollection from 'admin/api/collections/ShopCommodities'
import { displayConfirm } from 'frontend/lib/Noty'

@Component<AdminStationImages>({
  components: {
    FilteredList,
    FilteredTable,
    BtnGroup,
    BtnDropdown,
    Btn,
  },
})
export default class AdminStationImages extends Vue {
  collection: ShopCommoditiesCollection = shopCommoditiesCollection

  deleting: boolean = false

  tableColumns = [
    { name: 'item', label: this.$t('labels.shopCommodity.item'), width: '30%' },
    {
      name: 'prices',
      label: this.$t('labels.shopCommodity.prices.label'),
      width: '20%',
    },
    {
      name: 'confirmed',
      label: this.$t('labels.shopCommodity.confirmed'),
      width: '10%',
    },
    { name: 'actions', label: this.$t('labels.actions'), width: '10%' },
  ]

  prices = [
    'buyPrice',
    'averageBuyPrice',
    'sellPrice',
    'averageSellPrice',
    'rentalPrice1Day',
    'averageRentalPrice1Day',
    'rentalPrice3Days',
    'averageRentalPrice3Days',
    'rentalPrice7Days',
    'averageRentalPrice7Days',
    'rentalPrice30Days',
    'averageRentalPrice30Days',
  ]

  get routeParams() {
    return {
      shopId: this.$route.params.shopId,
    }
  }

  mounted() {
    this.$comlink.$on('prices-update', this.fetch)
  }

  beforeDestroy() {
    this.$comlink.$off('prices-update')
  }

  async fetch() {
    await this.collection.refresh()
  }

  openEditModal(shopCommodity) {
    this.$comlink.$emit('open-modal', {
      component: () => import('admin/components/ShopCommodities/Modal'),
      props: {
        shopId: this.routeParams.shopId,
        shopCommodity,
      },
    })
  }

  openSellPricesModal(shopCommodity) {
    this.$comlink.$emit('open-modal', {
      component: () => import('admin/components/ShopCommodities/PricesModal'),
      props: {
        path: 'sell',
        shopId: this.routeParams.shopId,
        shopCommodity,
      },
    })
  }

  openBuyPricesModal(shopCommodity) {
    this.$comlink.$emit('open-modal', {
      component: () => import('admin/components/ShopCommodities/PricesModal'),
      props: {
        path: 'buy',
        shopId: this.routeParams.shopId,
        shopCommodity,
      },
    })
  }

  openRentalPricesModal(shopCommodity) {
    this.$comlink.$emit('open-modal', {
      component: () => import('admin/components/ShopCommodities/PricesModal'),
      props: {
        path: 'rental',
        shopId: this.routeParams.shopId,
        shopCommodity,
      },
    })
  }

  openAddModal() {
    this.$comlink.$emit('open-modal', {
      component: () => import('admin/components/ShopCommodities/Modal'),
      props: {
        shopId: this.routeParams.shopId,
      },
    })
  }

  remove(shopCommodity) {
    this.deleting = true
    displayConfirm({
      text: this.$t('messages.confirm.shopCommodity.destroy'),
      onConfirm: () => {
        this.destroy(shopCommodity)
      },
      onClose: () => {
        this.deleting = false
      },
    })
  }

  async destroy(shopCommodity) {
    if (
      await this.collection.destroy(this.routeParams.shopId, shopCommodity.id)
    ) {
      this.fetch()
    }

    this.deleting = false
  }
}
</script>
