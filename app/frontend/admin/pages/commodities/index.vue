<script lang="ts">
export default {
  name: "AdminCommoditiesPage",
};
</script>

<script lang="ts" setup>
import { BtnSizesEnum } from "@/shared/components/base/Btn/types";
import Heading from "@/shared/components/base/Heading/index.vue";
import HeadingSmall from "@/shared/components/base/Heading/Small/index.vue";
import FilteredList from "@/shared/components/FilteredList/index.vue";
import BaseTable from "@/shared/components/base/Table/index.vue";
import { type BaseTableCol } from "@/shared/components/base/Table/types";
import FilterForm from "@/admin/components/Commodities/FilterForm/index.vue";
import {
  useCommodities,
  getCommoditiesQueryKey,
  type Commodity,
  type CommoditySortEnum,
} from "@/services/fyAdminApi";
import { usePagination } from "@/shared/composables/usePagination";
import Paginator from "@/shared/components/Paginator/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import { useCommodityFilters } from "@/admin/composables/useCommodityFilters";
import CommodityActions from "@/admin/components/Commodities/Actions/index.vue";
import ViewImage from "@/shared/components/ViewImage/index.vue";
import { LazyImageVariantsEnum } from "@/shared/components/LazyImage/types";

const route = useRoute();

const sorts = computed((): CommoditySortEnum[] => {
  return route.query.s ? [route.query.s as CommoditySortEnum] : [];
});

watch(
  () => sorts.value,
  async () => {
    await refetch();
  },
);

const commoditiesQueryKey = computed(() => {
  return getCommoditiesQueryKey(commoditiesQueryParams.value);
});

const { perPage, page, updatePerPage } = usePagination(commoditiesQueryKey);

const { filters, isFilterSelected } = useCommodityFilters(async () => {
  await refetch();
});

const commoditiesQueryParams = computed(() => {
  return {
    page: page.value,
    perPage: perPage.value,
    q: {
      ...filters.value,
      sorts: sorts.value,
    },
  };
});

const {
  data: commodities,
  refetch,
  ...asyncStatus
} = useCommodities(commoditiesQueryParams);

const columns: BaseTableCol<Commodity>[] = [
  {
    name: "storeImage",
    label: "",
    width: "120px",
    alignment: "center",
  },
  {
    name: "name",
    label: "Name",
    sortable: true,
  },
  {
    name: "commodityType",
    label: "Type",
    sortable: true,
    mobile: false,
  },
  {
    name: "uexCode",
    label: "UEX Code",
    mobile: false,
  },
  {
    name: "buyPrice",
    label: "Buy",
    alignment: "right",
    mobile: false,
  },
  {
    name: "sellPrice",
    label: "Sell",
    alignment: "right",
    mobile: false,
  },
  {
    name: "version",
    label: "Version",
    mobile: false,
  },
  {
    name: "createdAt",
    label: "Created At",
    mobile: false,
    sortable: true,
  },
  {
    name: "updatedAt",
    label: "Updated At",
    mobile: false,
    sortable: true,
  },
];

const { t, l, toUEC } = useI18n();
</script>

<template>
  <Heading hero>
    {{ t("headlines.admin.commodities.index") }}
    <HeadingSmall v-if="commodities">
      {{
        t("headlines.pagination.count", {
          current: commodities?.items.length,
          total: commodities?.meta.pagination?.totalCount,
        })
      }}
    </HeadingSmall>
  </Heading>

  <Teleport to="#header-right">
    <Btn
      :size="BtnSizesEnum.MD"
      :to="{ name: 'admin-commodity-create' }"
      :aria-label="t('actions.create')"
      mobile-icon-only
    >
      <i class="fa fa-plus" />
      {{ t("actions.create") }}
    </Btn>
  </Teleport>

  <FilteredList
    name="admin-commodities"
    :records="commodities?.items || []"
    :async-status="asyncStatus"
    hide-loading
    hide-empty
    :is-filter-selected="isFilterSelected"
  >
    <template #filter>
      <FilterForm />
    </template>
    <template #default="{ loading, refetching, emptyVisible }">
      <BaseTable
        :records="commodities?.items || []"
        primary-key="id"
        :columns="columns"
        :loading="loading || refetching"
        :empty-visible="emptyVisible"
        default-sort="name asc"
        selectable
      >
        <template #col-storeImage="{ record }">
          <ViewImage
            :image="record.storeImage"
            size="small"
            alt="image"
            :variant="LazyImageVariantsEnum.WIDE_SMALL"
            transparent
          />
        </template>
        <template #col-name="{ record }">
          <router-link
            :to="{
              name: 'admin-commodity-edit',
              params: {
                id: record.id,
              },
            }"
          >
            {{ record.name }}
          </router-link>
        </template>
        <template #col-commodityType="{ record }">
          {{ record.commodityType }}
        </template>
        <template #col-uexCode="{ record }">
          {{ record.uexCode }}
        </template>
        <!-- eslint-disable vue/no-v-html -->
        <template #col-buyPrice="{ record }">
          <div class="no-break" v-html="toUEC(record.buyPrice ?? undefined)" />
        </template>
        <template #col-sellPrice="{ record }">
          <div class="no-break" v-html="toUEC(record.sellPrice ?? undefined)" />
        </template>
        <!-- eslint-enable vue/no-v-html -->
        <template #col-version="{ record }">
          {{ record.version }}
        </template>
        <template #col-createdAt="{ record }">
          {{ l(record.createdAt, "datetime.formats.short") }}
        </template>
        <template #col-updatedAt="{ record }">
          {{ l(record.updatedAt, "datetime.formats.short") }}
        </template>
        <template #actions="{ record }">
          <CommodityActions :commodity="record" />
        </template>
      </BaseTable>
    </template>
    <template #pagination-top>
      <Paginator
        :query-result-ref="commodities"
        :per-page="perPage"
        :update-per-page="updatePerPage"
      />
    </template>
    <template #pagination-bottom>
      <Paginator
        :query-result-ref="commodities"
        :per-page="perPage"
        :update-per-page="updatePerPage"
      />
    </template>
  </FilteredList>
</template>
