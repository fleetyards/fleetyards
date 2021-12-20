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

<script lang="ts">
import Vue from 'vue'
import { Component } from 'vue-property-decorator'
import FilteredList from 'frontend/core/components/FilteredList'
import FilteredTable from 'frontend/core/components/FilteredTable'
import BtnGroup from 'frontend/core/components/BtnGroup'
import Btn from 'frontend/core/components/Btn'
import commodityPriceConfirmationsCollection from 'admin/api/collections/CommodityPriceConfirmations'
import { displayConfirm } from 'frontend/lib/Noty'

@Component<AdminCommodityPrices>({
  components: {
    FilteredList,
    FilteredTable,
    BtnGroup,
    Btn,
  },
})
export default class AdminCommodityPrices extends Vue {
  collection: CommodityPriceConfirmationsCollection =
    commodityPriceConfirmationsCollection

  deleting: boolean = false

  tableColumns = [
    {
      name: 'item',
      label: this.$t('labels.commodityPrice.item'),
      width: '30%',
    },
    { name: 'shop', label: this.$t('labels.shopCommodity.shop'), width: '20%' },
    {
      name: 'type',
      label: this.$t('labels.commodityPrice.type'),
      width: '15%',
    },
    {
      name: 'submitters',
      label: this.$t('labels.commodityPrice.submittedBy'),
      width: '20%',
    },
    {
      name: 'price',
      label: this.$t('labels.commodityPrice.price'),
      width: '20%',
    },
    { name: 'actions', label: this.$t('labels.actions'), width: '12%' },
  ]

  async fetch() {
    await this.collection.refresh()
  }

  async confirm(commodityPrice) {
    if (await this.collection.confirm(commodityPrice.id)) {
      this.fetch()
    }

    this.deleting = false
  }

  remove(commodityPrice) {
    this.deleting = true
    displayConfirm({
      text: this.$t('messages.confirm.commodityPrice.destroy'),
      onConfirm: () => {
        this.destroy(commodityPrice)
      },
      onClose: () => {
        this.deleting = false
      },
    })
  }

  async destroy(commodityPrice) {
    if (await this.collection.destroy(commodityPrice.id)) {
      this.fetch()
    }

    this.deleting = false
  }
}
</script>
