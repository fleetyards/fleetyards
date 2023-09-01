<template>
  <FilteredList
    id="shopCommodities"
    name="shopCommodities"
    :records="data?.items || []"
    :loading="isLoading || isFetching"
    primary-key="id"
    class="shop-commodities"
  >
    <!-- <FilteredList
    :collection="collection"
    :name="route.name"
    :route-query="route.query"
    :hash="route.hash"
    :params="route.params"
    :paginated="true"
    :hide-empty-box="true"
    :hide-loading="true"
  > -->
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
              @click="confirm(record)"
            >
              {{ t("actions.confirm") }}
            </Btn>
            <Btn
              v-tooltip="t('actions.remove')"
              size="small"
              variant="dropdown"
              :disabled="deleting"
              data-test="shopCommodity-delete"
              in-group
              @click="remove(record)"
            >
              <i class="fal fa-trash" />
            </Btn>
          </BtnGroup>
        </template>
      </FilteredTable>
    </template>
  </FilteredList>
</template>

<script lang="ts" setup>
import Btn from "@/shared/components/base/Btn/index.vue";
import FilteredList from "@/shared/components/FilteredList/index.vue";
import FilteredTable from "@/shared/components/FilteredTable/index.vue";
import BtnGroup from "@/shared/components/base/BtnGroup/index.vue";
import { useI18n } from "@/frontend/composables/useI18n";
import { useNoty } from "@/shared/composables/useNoty";
import { useQuery } from "@tanstack/vue-query";
import { usePagination } from "@/shared/composables/usePagination";
import { useApiClient } from "@/admin/composables/useApiClient";

const { t } = useI18n();

const { displayConfirm } = useNoty(t);

// collection: ShopCommodityConfirmationsCollection =
//   shopCommodityConfirmationsCollection;

const route = useRoute();

const deleting = ref(false);

const tableColumns = [
  { name: "item", label: t("labels.shopCommodity.item"), width: "20%" },
  { name: "shop", label: t("labels.shopCommodity.shop"), width: "20%" },
  {
    name: "submitter",
    label: t("labels.shopCommodity.submittedBy"),
    width: "20%",
  },
  { name: "actions", label: t("labels.actions"), width: "12%" },
];

const { shopCommodities: shopCommoditiesService } = useApiClient();

const { isLoading, isFetching, data, refetch } = useQuery({
  queryKey: ["shopCommodities"],
  queryFn: () =>
    shopCommoditiesService.list({
      page: page.value,
      perPage: perPage.value,
    }),
});

watch(
  () => route.query,
  () => {
    refetch();
  },
  { deep: true },
);

const { perPage, page, pagination, updatePerPage } = usePagination(
  "shopCommodities",
  data as Ref<BaseList>,
  refetch,
);

const fetch = async () => {
  await this.collection.refresh();
};

const confirm = async (shopCommodity) => {
  if (await this.collection.confirm(shopCommodity.id)) {
    this.fetch();
  }

  this.deleting = false;
};

const remove = (shopCommodity) => {
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
};

const destroy = async (shopCommodity) => {
  if (await collection.destroy(shopCommodity.id)) {
    this.fetch();
  }

  deleting.value = false;
};
</script>

<script lang="ts">
export default {
  name: "AdminShopCommodities",
};
</script>
