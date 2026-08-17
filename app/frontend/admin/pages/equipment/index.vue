<script lang="ts">
export default {
  name: "AdminEquipmentPage",
};
</script>

<script lang="ts" setup>
import { BtnSizesEnum } from "@/shared/components/base/Btn/types";
import Heading from "@/shared/components/base/Heading/index.vue";
import HeadingSmall from "@/shared/components/base/Heading/Small/index.vue";
import FilteredList from "@/shared/components/FilteredList/index.vue";
import BaseTable from "@/shared/components/base/Table/index.vue";
import { type BaseTableCol } from "@/shared/components/base/Table/types";
import FilterForm from "@/admin/components/Equipment/FilterForm/index.vue";
import {
  useEquipment,
  getEquipmentQueryKey,
  type Equipment,
  type EquipmentSortEnum,
} from "@/services/fyAdminApi";
import { usePagination } from "@/shared/composables/usePagination";
import Paginator from "@/shared/components/Paginator/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import { useEquipmentFilters } from "@/admin/composables/useEquipmentFilters";
import EquipmentActions from "@/admin/components/Equipment/Actions/index.vue";
import ViewImage from "@/shared/components/ViewImage/index.vue";
import { LazyImageVariantsEnum } from "@/shared/components/LazyImage/types";

const route = useRoute();

const sorts = computed((): EquipmentSortEnum[] => {
  return route.query.s ? [route.query.s as EquipmentSortEnum] : [];
});

watch(
  () => sorts.value,
  async () => {
    await refetch();
  },
);

const equipmentQueryKey = computed(() => {
  return getEquipmentQueryKey(equipmentQueryParams.value);
});

const { perPage, page, updatePerPage } = usePagination(equipmentQueryKey);

const { filters, isFilterSelected } = useEquipmentFilters(async () => {
  await refetch();
});

const equipmentQueryParams = computed(() => {
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
  data: equipment,
  refetch,
  ...asyncStatus
} = useEquipment(equipmentQueryParams);

const columns: BaseTableCol<Equipment>[] = [
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
    name: "equipmentType",
    label: "Equipment Type",
    mobile: false,
  },
  {
    name: "itemType",
    label: "Item Type",
    sortable: true,
    mobile: false,
  },
  {
    name: "weaponClass",
    label: "Weapon Class",
    mobile: false,
  },
  {
    name: "size",
    label: "Size",
    mobile: false,
  },
  {
    name: "manufacturer",
    label: "Manufacturer",
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
    name: "hidden",
    label: "Hidden",
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
    {{ t("headlines.admin.equipment.index") }}
    <HeadingSmall v-if="equipment">
      {{
        t("headlines.pagination.count", {
          current: equipment?.items.length,
          total: equipment?.meta.pagination?.totalCount,
        })
      }}
    </HeadingSmall>
  </Heading>

  <Teleport to="#header-right">
    <Btn
      :size="BtnSizesEnum.MD"
      :to="{ name: 'admin-equipment-create' }"
      :aria-label="t('actions.create')"
      mobile-icon-only
    >
      <i class="fa fa-plus" />
      {{ t("actions.create") }}
    </Btn>
  </Teleport>

  <FilteredList
    name="admin-equipment"
    :records="equipment?.items || []"
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
        :records="equipment?.items || []"
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
            shadow
          />
        </template>
        <template #col-name="{ record }">
          <router-link
            :to="{
              name: 'admin-equipment-edit',
              params: {
                id: record.id,
              },
            }"
          >
            {{ record.name }}
          </router-link>
        </template>
        <template #col-equipmentType="{ record }">
          {{ record.equipmentType }}
        </template>
        <template #col-itemType="{ record }">
          {{ record.itemType }}
        </template>
        <template #col-weaponClass="{ record }">
          {{ record.weaponClass }}
        </template>
        <template #col-size="{ record }">
          {{ record.size }}
        </template>
        <template #col-manufacturer="{ record }">
          {{ record.manufacturer?.name }}
        </template>
        <!-- eslint-disable vue/no-v-html -->
        <template #col-buyPrice="{ record }">
          <div class="no-break" v-html="toUEC(record.buyPrice ?? undefined)" />
        </template>
        <template #col-sellPrice="{ record }">
          <div class="no-break" v-html="toUEC(record.sellPrice ?? undefined)" />
        </template>
        <!-- eslint-enable vue/no-v-html -->
        <template #col-hidden="{ record }">
          <i v-if="record.hidden" class="fa-duotone fa-check" />
          <i v-else class="fa-duotone fa-times" />
        </template>
        <template #col-createdAt="{ record }">
          {{ l(record.createdAt, "datetime.formats.short") }}
        </template>
        <template #col-updatedAt="{ record }">
          {{ l(record.updatedAt, "datetime.formats.short") }}
        </template>
        <template #actions="{ record }">
          <EquipmentActions :equipment="record" />
        </template>
      </BaseTable>
    </template>
    <template #pagination-top>
      <Paginator
        v-if="equipment"
        :query-result-ref="equipment"
        :per-page="perPage"
        :update-per-page="updatePerPage"
      />
    </template>
    <template #pagination-bottom>
      <Paginator
        v-if="equipment"
        :query-result-ref="equipment"
        :per-page="perPage"
        :update-per-page="updatePerPage"
      />
    </template>
  </FilteredList>
</template>
