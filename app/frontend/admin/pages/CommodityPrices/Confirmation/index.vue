<template>
  <FilteredList
    :collection="collection"
    :name="$route.name"
    :route-query="$route.query"
    :hash="$route.hash"
    :params="$route.params"
    :paginated="true"
    :hide-empty-box="true"
    :hide-loading="true"
  >
    <template #default="{ records, loading, emptyBoxVisible, primaryKey }">
      <FilteredTable
        :records="records"
        :primary-key="primaryKey"
        :columns="tableColumns"
        :loading="loading"
        :empty-box-visible="emptyBoxVisible"
      >
        <template #col-item="{ record }">
          <template v-if="record.shopCommodity">
            {{ record.shopCommodity.item.name }}
            <small>
              {{ record.shopCommodity.item.typeLabel }}
              {{ record.shopCommodity.item.itemTypeLabel }}
            </small>
          </template>
        </template>
        <template #col-shop="{ record }">
          {{ record.shopCommodity.shop.name }}
          <br />
          <small>{{ record.shopCommodity.shop.locationLabel }}</small>
        </template>
        <template #col-submitters="{ record }">
          <ul>
            <li v-for="submitter in record.submitters" :key="submitter.id">
              {{ submitter.username }}
            </li>
          </ul>
        </template>
        <template #col-price="{ record }">
          <span v-html="$toUEC(record.price)" />
        </template>
        <template #col-actions="{ record }">
          <BtnGroup :inline="true">
            <Btn
              size="small"
              variant="dropdown"
              :inline="true"
              @click.native="confirm(record)"
            >
              {{ $t('actions.confirm') }}
            </Btn>
            <Btn
              v-tooltip="$t('actions.remove')"
              size="small"
              variant="dropdown"
              :disabled="deleting"
              data-test="shopCommodity-delete"
              @click.native="remove(record)"
            >
              <i class="fal fa-trash" />
            </Btn>
          </BtnGroup>
        </template>
      </FilteredTable>
    </template>
  </FilteredList>
</template>

<script>
import FilteredList from '@/frontend/core/components/FilteredList/index.vue'
import FilteredTable from '@/frontend/core/components/FilteredTable/index.vue'
import BtnGroup from '@/frontend/core/components/BtnGroup/index.vue'
import Btn from '@/frontend/core/components/Btn/index.vue'
import commodityPriceConfirmationsCollection from '@/admin/api/collections/CommodityPriceConfirmations'
import { displayConfirm } from '@/frontend/lib/Noty'

export default {
  name: 'AdminCommodityPrices',

  components: {
    Btn,
    BtnGroup,
    FilteredList,
    FilteredTable,
  },

  data() {
    return {
      collection: commodityPriceConfirmationsCollection,
      deleting: false,
      tableColumns: [
        {
          label: this.$t('labels.commodityPrice.item'),
          name: 'item',
          width: '30%',
        },
        {
          label: this.$t('labels.shopCommodity.shop'),
          name: 'shop',
          width: '20%',
        },
        {
          label: this.$t('labels.commodityPrice.type'),
          name: 'type',
          width: '15%',
        },
        {
          label: this.$t('labels.commodityPrice.submittedBy'),
          name: 'submitters',
          width: '20%',
        },
        {
          label: this.$t('labels.commodityPrice.price'),
          name: 'price',
          width: '20%',
        },
        { label: this.$t('labels.actions'), name: 'actions', width: '12%' },
      ],
    }
  },

  methods: {
    async confirm(commodityPrice) {
      if (await this.collection.confirm(commodityPrice.id)) {
        this.fetch()
      }

      this.deleting = false
    },

    async destroy(commodityPrice) {
      if (await this.collection.destroy(commodityPrice.id)) {
        this.fetch()
      }

      this.deleting = false
    },

    async fetch() {
      await this.collection.refresh()
    },

    remove(commodityPrice) {
      this.deleting = true
      displayConfirm({
        onClose: () => {
          this.deleting = false
        },
        onConfirm: () => {
          this.destroy(commodityPrice)
        },
        text: this.$t('messages.confirm.commodityPrice.destroy'),
      })
    },
  },
}
</script>
