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
          {{ record.item.name }}
          <small>
            {{ record.item.typeLabel }}
            {{ record.item.itemTypeLabel }}
          </small>
        </template>
        <template #col-shop="{ record }">
          {{ record.shop.name }}
          <br />
          <small>{{ record.shop.locationLabel }}</small>
        </template>
        <template #col-submitter="{ record }">
          {{ record.submitter.username }}
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
import shopCommodityConfirmationsCollection from '@/admin/api/collections/ShopCommodityConfirmations'
import { displayConfirm } from '@/frontend/lib/Noty'

export default {
  name: 'AdminShopCommodities',

  components: {
    Btn,
    BtnGroup,
    FilteredList,
    FilteredTable,
  },

  data() {
    return {
      collection: shopCommodityConfirmationsCollection,
      deleting: false,
      tableColumns: [
        {
          label: this.$t('labels.shopCommodity.item'),
          name: 'item',
          width: '20%',
        },
        {
          label: this.$t('labels.shopCommodity.shop'),
          name: 'shop',
          width: '20%',
        },
        {
          label: this.$t('labels.shopCommodity.submittedBy'),
          name: 'submitter',
          width: '20%',
        },
        { label: this.$t('labels.actions'), name: 'actions', width: '12%' },
      ],
    }
  },

  methods: {
    async confirm(shopCommodity) {
      if (await this.collection.confirm(shopCommodity.id)) {
        this.fetch()
      }

      this.deleting = false
    },

    async destroy(shopCommodity) {
      if (await this.collection.destroy(shopCommodity.id)) {
        this.fetch()
      }

      this.deleting = false
    },

    async fetch() {
      await this.collection.refresh()
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
