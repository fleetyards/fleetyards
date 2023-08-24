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
              in-group
              @click.native="confirm(record)"
            >
              {{ $t("actions.confirm") }}
            </Btn>
            <Btn
              v-tooltip="$t('actions.remove')"
              size="small"
              variant="dropdown"
              :disabled="deleting"
              data-test="shopCommodity-delete"
              in-group
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
import Vue from "vue";
import { Component } from "vue-property-decorator";
import Btn from "@/frontend/core/components/Btn/index.vue";
import shopCommodityConfirmationsCollection from "@/admin/api/collections/ShopCommodityConfirmations";
import { displayConfirm } from "@/frontend/lib/Noty";
import FilteredList from "@/frontend/core/components/FilteredList/index.vue";
import FilteredTable from "@/frontend/core/components/FilteredTable/index.vue";
import BtnGroup from "@/frontend/core/components/BtnGroup/index.vue";

@Component<AdminShopCommodities>({
  components: {
    FilteredList,
    FilteredTable,
    BtnGroup,
    Btn,
  },
})
export default class AdminShopCommodities extends Vue {
  collection: ShopCommodityConfirmationsCollection =
    shopCommodityConfirmationsCollection;

  deleting = false;

  tableColumns = [
    { name: "item", label: this.$t("labels.shopCommodity.item"), width: "20%" },
    { name: "shop", label: this.$t("labels.shopCommodity.shop"), width: "20%" },
    {
      name: "submitter",
      label: this.$t("labels.shopCommodity.submittedBy"),
      width: "20%",
    },
    { name: "actions", label: this.$t("labels.actions"), width: "12%" },
  ];

  async fetch() {
    await this.collection.refresh();
  }

  async confirm(shopCommodity) {
    if (await this.collection.confirm(shopCommodity.id)) {
      this.fetch();
    }

    this.deleting = false;
  }

  remove(shopCommodity) {
    this.deleting = true;
    displayConfirm({
      text: this.$t("messages.confirm.shopCommodity.destroy"),
      onConfirm: () => {
        this.destroy(shopCommodity);
      },
      onClose: () => {
        this.deleting = false;
      },
    });
  }

  async destroy(shopCommodity) {
    if (await this.collection.destroy(shopCommodity.id)) {
      this.fetch();
    }

    this.deleting = false;
  }
}
</script>
