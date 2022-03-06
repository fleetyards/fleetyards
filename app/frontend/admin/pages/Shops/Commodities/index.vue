<template>
  <FilteredList
    :collection="collection"
    :name="$route.name"
    :route-query="$route.query"
    route-filter-name="filters"
    :hash="$route.hash"
    :params="routeParams"
    :paginated="true"
    :always-filter-visible="true"
    :hide-empty-box="true"
    :hide-loading="true"
  >
    <FilterForm slot="filter" />

    <template #actions>
      <Btn @click.native="openAddModal('Commodity')">
        {{ $t('actions.add') }} Commodity
      </Btn>
      <Btn @click.native="openComponentModal">
        {{ $t('actions.add') }} Component
      </Btn>
      <Btn @click.native="openAddModal('Equipment')">
        {{ $t('actions.add') }} Equipment
      </Btn>
      <Btn @click.native="openAddModal('Model')">
        {{ $t('actions.add') }} Model
      </Btn>
      <Btn @click.native="openAddModal('ModelPaint')">
        {{ $t('actions.add') }} ModelPaint
      </Btn>
      <Btn @click.native="openAddModal('ModelModule')">
        {{ $t('actions.add') }} ModelModule
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
                <span v-html="$toUEC(record[price])" />
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
                <span>{{ $t('labels.shopCommodity.sellPrices') }}</span>
              </Btn>
              <Btn
                size="small"
                variant="dropdown"
                @click.native="openBuyPricesModal(record)"
              >
                <i class="fal fa-list" />
                <span>{{ $t('labels.shopCommodity.buyPrices') }}</span>
              </Btn>
              <Btn
                size="small"
                variant="dropdown"
                @click.native="openRentalPricesModal(record)"
              >
                <i class="fal fa-list" />
                <span>{{ $t('labels.shopCommodity.rentalPrices') }}</span>
              </Btn>
              <Btn
                size="small"
                variant="dropdown"
                :disabled="deleting"
                data-test="shopCommodity-delete"
                @click.native="remove(record)"
              >
                <i class="fal fa-trash" />
                <span>{{ $t('actions.remove') }}</span>
              </Btn>
            </BtnDropdown>
          </BtnGroup>
        </template>
      </FilteredTable>
    </template>
  </FilteredList>
</template>

<script>
import FilteredList from '@/frontend/core/components/FilteredList/index.vue'
import FilteredTable from '@/frontend/core/components/FilteredTable/index.vue'
import FilterForm from '@/admin/components/ShopCommodities/FilterForm/index.vue'
import BtnGroup from '@/frontend/core/components/BtnGroup/index.vue'
import BtnDropdown from '@/frontend/core/components/BtnDropdown/index.vue'
import Btn from '@/frontend/core/components/Btn/index.vue'
import shopCommoditiesCollection from '@/admin/api/collections/ShopCommodities'
import { displayConfirm } from '@/frontend/lib/Noty'

export default {
  name: 'AdminStationImages',

  components: {
    Btn,
    BtnDropdown,
    BtnGroup,
    FilteredList,
    FilteredTable,
    FilterForm,
  },

  data() {
    return {
      collection: shopCommoditiesCollection,
      deleting: false,
      prices: [
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
      ],
      tableColumns: [
        {
          label: this.$t('labels.shopCommodity.item'),
          name: 'item',
          width: '30%',
        },
        {
          label: this.$t('labels.shopCommodity.prices.label'),
          name: 'prices',
          width: '20%',
        },
        {
          label: this.$t('labels.shopCommodity.confirmed'),
          name: 'confirmed',
          width: '10%',
        },
        {
          class: 'actions',
          label: this.$t('labels.actions'),
          name: 'actions',
          width: '10%',
        },
      ],
    }
  },

  computed: {
    routeParams() {
      return {
        shopId: this.$route.params.shopId,
      }
    },
  },

  beforeDestroy() {
    this.$comlink.$off('prices-update')
    this.$comlink.$off('commodities-update')
  },

  mounted() {
    this.$comlink.$on('prices-update', this.fetch)
    this.$comlink.$on('commodities-update', this.fetch)
  },

  methods: {
    async destroy(shopCommodity) {
      if (
        await this.collection.destroy(this.routeParams.shopId, shopCommodity.id)
      ) {
        this.fetch()
      }

      this.deleting = false
    },

    async fetch() {
      await this.collection.refresh()
    },

    openAddModal(commodityItemType) {
      this.$comlink.$emit('open-modal', {
        component: () =>
          import('@/admin/components/ShopCommodities/NewModal/index.vue'),
        props: {
          commodityItemType,
          shopId: this.routeParams.shopId,
        },
      })
    },

    openBuyPricesModal(shopCommodity) {
      this.$comlink.$emit('open-modal', {
        component: () =>
          import('@/admin/components/ShopCommodities/PricesModal/index.vue'),
        props: {
          path: 'buy',
          shopCommodity,
          shopId: this.routeParams.shopId,
        },
      })
    },

    openComponentModal() {
      this.$comlink.$emit('open-modal', {
        component: () =>
          import('@/admin/components/ShopCommodities/NewModal/index.vue'),
        props: {
          commodityItemType: 'Component',
          itemTypeFilter: (this.$route.query.filters?.component_item_type ||
            [])[0],
          shopId: this.routeParams.shopId,
        },
      })
    },

    openEditModal(shopCommodity) {
      this.$comlink.$emit('open-modal', {
        component: () =>
          import('@/admin/components/ShopCommodities/Modal/index.vue'),
        props: {
          shopCommodity,
          shopId: this.routeParams.shopId,
        },
      })
    },

    openRentalPricesModal(shopCommodity) {
      this.$comlink.$emit('open-modal', {
        component: () =>
          import('@/admin/components/ShopCommodities/PricesModal/index.vue'),
        props: {
          path: 'rental',
          shopCommodity,
          shopId: this.routeParams.shopId,
        },
      })
    },

    openSellPricesModal(shopCommodity) {
      this.$comlink.$emit('open-modal', {
        component: () =>
          import('@/admin/components/ShopCommodities/PricesModal/index.vue'),
        props: {
          path: 'sell',
          shopCommodity,
          shopId: this.routeParams.shopId,
        },
      })
    },

    remove(shopCommodity) {
      this.deleting = true
      displayConfirm({
        onClose: () => {
          this.deleting = false
        },
        onConfirm: () => {
          this.destroy(shopCommodity)
        },
        text: this.$t('messages.confirm.shopCommodity.destroy'),
      })
    },
  },
}
</script>
