<script lang="ts">
export default {
  name: "AdminVehiclesPage",
};
</script>

<script lang="ts" setup>
import { useI18n } from "@/shared/composables/useI18n";
import Heading from "@/shared/components/base/Heading/index.vue";
import HeadingSmall from "@/shared/components/base/Heading/Small/index.vue";
import FilteredList from "@/shared/components/FilteredList/index.vue";
import BaseTable from "@/shared/components/base/Table/index.vue";
import ViewImage from "@/shared/components/ViewImage/index.vue";
import { type BaseTableCol } from "@/shared/components/base/Table/types";
import { LazyImageVariantsEnum } from "@/shared/components/LazyImage/types";
import FilterForm from "@/admin/components/Vehicles/FilterForm/index.vue";
import { useVehicleFilters } from "@/admin/composables/useVehicleFilters";
import { usePagination } from "@/shared/composables/usePagination";
import Paginator from "@/shared/components/Paginator/index.vue";
import {
  type Vehicle,
  useVehicles as useVehiclesQuery,
  getVehiclesQueryKey,
} from "@/services/fyAdminApi";
import VehicleActions from "@/admin/components/Vehicles/Actions/index.vue";

const { t } = useI18n();

const route = useRoute();

const sorts = computed(() => {
  return route.query.s ? [route.query.s as string] : [];
});

watch(
  () => sorts.value,
  async () => {
    await refetch();
  },
);

const { getQuery } = useVehicleFilters(async () => {
  await refetch();
});

const vehiclesQueryParams = computed(() => {
  return {
    page: page.value,
    perPage: perPage.value,
    q: getQuery(),
    s: sorts.value,
  };
});

const vehiclesQueryKey = computed(() => {
  return getVehiclesQueryKey(vehiclesQueryParams.value);
});

const { perPage, page, updatePerPage } = usePagination(vehiclesQueryKey);

const {
  data: vehicles,
  refetch,
  ...asyncStatus
} = useVehiclesQuery(vehiclesQueryParams);

const columns: BaseTableCol<Vehicle>[] = [
  {
    name: "image",
    label: "",
    alignment: "center",
    width: "120px",
  },
  {
    name: "fleetchart",
    label: "",
    alignment: "center",
    width: "120px",
    mobile: false,
  },
  {
    name: "name",
    label: "Name",
    sortable: true,
  },
  {
    name: "model_name",
    label: "Model",
    sortable: true,
  },
  {
    name: "user",
    label: "User",
    sortable: true,
  },
  {
    name: "wanted",
    label: "Wanted",
    sortable: true,
  },
];

const image = (record: Vehicle) => {
  if (record.paint && record.paint.media.storeImage) {
    return record.paint.media.storeImage;
  }

  if (record.upgrade && record.upgrade.media.storeImage) {
    return record.upgrade.media.storeImage;
  }

  return record.model.media.storeImage;
};
</script>

<template>
  <Heading hero>
    {{ t("headlines.admin.vehicles.index") }}
    <HeadingSmall v-if="vehicles">
      {{
        t("headlines.pagination.count", {
          current: vehicles?.items.length,
          total: vehicles?.meta.pagination?.totalCount,
        })
      }}
    </HeadingSmall>
  </Heading>
  <FilteredList
    name="admin-vehicles"
    :records="vehicles?.items || []"
    :async-status="asyncStatus"
    hide-loading
    hide-empty
  >
    <template #filter>
      <FilterForm />
    </template>
    <template #default="{ loading, refetching, emptyVisible }">
      <BaseTable
        :records="vehicles?.items || []"
        primary-key="id"
        :columns="columns"
        :loading="loading || refetching"
        :empty-visible="emptyVisible"
        default-sort="name asc"
        selectable
      >
        <template #col-image="{ record }">
          <ViewImage
            :image="image(record)"
            size="small"
            alt="Model image"
            :variant="LazyImageVariantsEnum.WIDE_SMALL"
            shadow
          />
        </template>
        <template #col-fleetchart="{ record }">
          <ViewImage
            v-if="record.model.media.angledView"
            :image="record.model.media.angledView"
            size="small"
            alt="Model angledView"
            :variant="LazyImageVariantsEnum.WIDE_SMALL"
            transparent
          />
        </template>
        <template #col-model_name="{ record }">
          <router-link
            :to="{
              name: 'admin-model-edit',
              params: {
                id: record.model.id,
              },
            }"
          >
            {{ record.model.manufacturer?.code }} {{ record.model.name }}
          </router-link>
        </template>
        <template #col-user="{ record }">
          <router-link
            :to="{
              name: 'admin-user-edit',
              params: {
                id: record.user.id,
              },
            }"
          >
            {{ record.user.username }}
          </router-link>
        </template>
        <template #actions="{ record }">
          <VehicleActions :vehicle="record" />
        </template>
      </BaseTable>
    </template>
    <template #pagination-top>
      <Paginator
        v-if="vehicles"
        :query-result-ref="vehicles"
        :per-page="perPage"
        :update-per-page="updatePerPage"
      />
    </template>
    <template #pagination-bottom>
      <Paginator
        v-if="vehicles"
        :query-result-ref="vehicles"
        :per-page="perPage"
        :update-per-page="updatePerPage"
      />
    </template>
  </FilteredList>
</template>
