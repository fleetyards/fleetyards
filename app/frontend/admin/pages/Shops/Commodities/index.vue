<template>
  <FilteredList
    id="admin-commodities"
    name="admin-commodities"
    :records="data?.items || []"
    :loading="isLoading || isFetching"
    primary-key="id"
    static-filters
    hide-empty-box
    hide-loading
  >
    <template #filter>
      <FilterForm />
    </template>

    <template #actions>
      <Btn @click="openAddModal(ShopCommodityItemTypeEnum.COMMODITY)">
        {{ t("actions.add") }} Commodity
      </Btn>
      <Btn @click="openComponentModal">{{ t("actions.add") }} Component</Btn>
      <Btn @click="openAddModal(ShopCommodityItemTypeEnum.EQUIPMENT)">
        {{ t("actions.add") }} Equipment
      </Btn>
      <Btn @click="openAddModal(ShopCommodityItemTypeEnum.MODEL)">
        {{ t("actions.add") }} Model
      </Btn>
      <Btn @click="openAddModal(ShopCommodityItemTypeEnum.MODEL_PAINT)">
        {{ t("actions.add") }} ModelPaint
      </Btn>
      <Btn @click="openAddModal(ShopCommodityItemTypeEnum.MODEL_MODULE)">
        {{ t("actions.add") }} ModelModule
      </Btn>
    </template>

    <template #default="{ records, loading, emptyBoxVisible, primaryKey }">
      <FilteredTable
        :records="records"
        :primary-key="primaryKey"
        :columns="tableColumns"
        :loading="loading"
        :empty-box-visible="emptyBoxVisible"
        selectable
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
              :key="`price-${record[primaryKey]}-${price}`"
            >
              <div v-if="record[price]" class="d-flex justify-content-between">
                {{ t(`models.shopCommodity.prices.${price}`) }}:
                <span v-html="toUEC(record[price])" />
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
              in-group
              @click="openEditModal(record)"
            >
              {{ t("actions.edit") }}
            </Btn>
            <BtnDropdown :inline="true" size="small" variant="link" in-group>
              <Btn
                size="small"
                variant="dropdown"
                @click="openSellPricesModal(record)"
              >
                <i class="fal fa-list" />
                <span>{{ t("models.shopCommodity.sellPrices") }}</span>
              </Btn>
              <Btn
                size="small"
                variant="dropdown"
                @click="openBuyPricesModal(record)"
              >
                <i class="fal fa-list" />
                <span>{{ t("models.shopCommodity.buyPrices") }}</span>
              </Btn>
              <Btn
                size="small"
                variant="dropdown"
                @click="openRentalPricesModal(record)"
              >
                <i class="fal fa-list" />
                <span>{{ t("models.shopCommodity.rentalPrices") }}</span>
              </Btn>
              <Btn
                size="small"
                variant="dropdown"
                :disabled="deleting"
                data-test="shopCommodity-delete"
                @click="remove(record)"
              >
                <i class="fal fa-trash" />
                <span>{{ t("actions.remove") }}</span>
              </Btn>
            </BtnDropdown>
          </BtnGroup>
        </template>
      </FilteredTable>
    </template>
    <template #pagination-bottom>
      <Paginator
        :pagination="pagination"
        :per-page="perPage"
        :update-per-page="updatePerPage"
      />
    </template>
  </FilteredList>
</template>

<script lang="ts" setup>
import FilteredList from "@/shared/components/FilteredList/index.vue";
import FilteredTable from "@/shared/components/FilteredTable/index.vue";
import FilterForm from "@/admin/components/ShopCommodities/FilterForm/index.vue";
import BtnGroup from "@/shared/components/BaseBtnGroup/index.vue";
import BtnDropdown from "@/shared/components/BaseBtnDropdown/index.vue";
import Btn from "@/shared/components/BaseBtn/index.vue";
import { useI18n } from "@/admin/composables/useI18n";
import { useNoty } from "@/shared/composables/useNoty";
import { useRoute } from "vue-router";
import { usePagination } from "@/shared/composables/usePagination";
import { useComlink } from "@/shared/composables/useComlink";
import { useQuery } from "@tanstack/vue-query";
import Paginator from "@/shared/components/Paginator/index.vue";
import { useApiClient } from "@/admin/composables/useApiClient";
import type {
  ShopCommodity,
  ShopCommodityQuery,
  BaseList,
} from "@/services/fyAdminApi";
import { ShopCommodityItemTypeEnum } from "@/services/fyAdminApi";

const deleting = ref(false);

const { t, toUEC } = useI18n();

const tableColumns = ref([
  { name: "item", label: t("models.shopCommodity.item"), width: "30%" },
  {
    name: "prices",
    label: t("models.shopCommodity.prices.label"),
    width: "20%",
  },
  {
    name: "confirmed",
    label: t("models.shopCommodity.confirmed"),
    width: "10%",
  },
  {
    name: "actions",
    label: t("labels.actions"),
    width: "10%",
    class: "actions",
  },
]);

const prices = ref([
  "buyPrice",
  "averageBuyPrice",
  "sellPrice",
  "averageSellPrice",
  "rentalPrice1Day",
  "averageRentalPrice1Day",
  "rentalPrice3Days",
  "averageRentalPrice3Days",
  "rentalPrice7Days",
  "averageRentalPrice7Days",
  "rentalPrice30Days",
  "averageRentalPrice30Days",
]);

const route = useRoute();

const routeQuery = computed(() => {
  return (route.query.q || {}) as ShopCommodityQuery;
});

const { shops: shopsService, shopCommodities: shopCommodityService } =
  useApiClient();

const { isLoading, isFetching, data, refetch } = useQuery({
  queryKey: ["admin-commodities"],
  queryFn: () =>
    shopsService.shopCommodities({
      shopId: route.params.shopId as string,
      page: page.value,
      perPage: perPage.value,
      filters: routeQuery.value,
    }),
});

const { perPage, page, pagination, updatePerPage } = usePagination(
  "admin-commodities",
  data as Ref<BaseList>,
  refetch,
);

const comlink = useComlink();

onMounted(() => {
  comlink.on("prices-update", refetch);
  comlink.on("commodities-update", refetch);
});

onUnmounted(() => {
  comlink.off("prices-update", refetch);
  comlink.off("commodities-update", refetch);
});

const openEditModal = (shopCommodity: ShopCommodity) => {
  comlink.emit("open-modal", {
    component: () =>
      import("@/admin/components/ShopCommodities/Modal/index.vue"),
    props: {
      shopId: route.params.shopId,
      shopCommodity,
    },
  });
};

const openSellPricesModal = (shopCommodity: ShopCommodity) => {
  comlink.emit("open-modal", {
    component: () =>
      import("@/admin/components/ShopCommodities/PricesModal/index.vue"),
    props: {
      path: "sell",
      shopId: route.params.shopId,
      shopCommodity,
    },
  });
};

const openBuyPricesModal = (shopCommodity: ShopCommodity) => {
  comlink.emit("open-modal", {
    component: () =>
      import("@/admin/components/ShopCommodities/PricesModal/index.vue"),
    props: {
      path: "buy",
      shopId: route.params.shopId,
      shopCommodity,
    },
  });
};

const openRentalPricesModal = (shopCommodity: ShopCommodity) => {
  comlink.emit("open-modal", {
    component: () =>
      import("@/admin/components/ShopCommodities/PricesModal/index.vue"),
    props: {
      path: "rental",
      shopId: route.params.shopId,
      shopCommodity,
    },
  });
};

const openAddModal = (commodityItemType: ShopCommodityItemTypeEnum) => {
  comlink.emit("open-modal", {
    component: () =>
      import("@/admin/components/ShopCommodities/NewModal/index.vue"),
    props: {
      shopId: route.params.shopId,
      commodityItemType,
    },
  });
};

const openComponentModal = () => {
  const filters = (route.query.filters || {}) as ShopCommodityQuery;
  comlink.emit("open-modal", {
    component: () =>
      import("@/admin/components/ShopCommodities/NewModal/index.vue"),
    props: {
      shopId: route.params.shopId,
      commodityItemType: "Component",
      itemTypeFilter: (filters.componentItemType || [])[0],
    },
  });
};

const { displayConfirm } = useNoty(t);

const remove = (shopCommodity: ShopCommodity) => {
  deleting.value = true;

  displayConfirm({
    text: t("messages.confirm.shopCommodity.destroy"),
    onConfirm: () => {
      destroy(shopCommodity);
    },
    onClose: () => {
      deleting.value = false;
    },
  });
};

const destroy = async (shopCommodity: ShopCommodity) => {
  try {
    await shopCommodityService.destroyShopCommodity({ id: shopCommodity.id });

    refetch();
  } catch (e) {
    console.error(e);
  }

  deleting.value = false;
};
</script>

<script lang="ts">
export default {
  name: "AdminCommoditiesPage",
};
</script>
