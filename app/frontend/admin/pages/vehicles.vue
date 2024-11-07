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
import { type BaseTableColumn } from "@/shared/components/base/Table/types";
import LazyImage from "@/shared/components/LazyImage/index.vue";
import { LazyImageVariantsEnum } from "@/shared/components/LazyImage/types";
import FilterForm from "@/admin/components/Vehicles/FilterForm/index.vue";
import {
  QueryKeysEnum,
  useVehicleQueries,
} from "@/admin/composables/useVehicleQueries";
import { useVehicleFilters } from "@/admin/composables/useVehicleFilters";
import { usePagination } from "@/shared/composables/usePagination";
import Paginator from "@/shared/components/Paginator/index.vue";
import { Vehicle } from "@/services/fyApi";
import fallbackImageJpg from "@/images/fallback/store_image.jpg";
import fallbackImage from "@/images/fallback/store_image.webp";
import { useWebpCheck } from "@/shared/composables/useWebpCheck";

const { t } = useI18n();

const route = useRoute();

const sorts = computed(() => {
  return route.query.s ? [route.query.s as string] : [];
});

watch(
  () => sorts.value,
  () => {
    refetch();
  },
);

const { perPage, page, updatePerPage } = usePagination(QueryKeysEnum.VEHICLES);

const { filters } = useVehicleFilters(() => refetch());

const { vehiclesQuery } = useVehicleQueries();

const {
  data: vehicles,
  refetch,
  ...asyncStatus
} = vehiclesQuery({
  page,
  perPage,
  filters,
  sorts,
});

const columns: BaseTableColumn[] = [
  {
    name: "image",
    label: "",
    centered: true,
  },
  {
    name: "fleetchart",
    label: "",
    centered: true,
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

const { supported: webpSupported } = useWebpCheck();

const image = (record: Vehicle) => {
  if (record.paint && record.paint.media.storeImage) {
    return record.paint.media.storeImage.small;
  }

  if (record.upgrade && record.upgrade.media.storeImage) {
    return record.upgrade.media.storeImage.small;
  }

  if (record.model.media.storeImage) {
    return record.model.media.storeImage.small;
  }

  if (webpSupported) {
    return fallbackImage;
  }

  return fallbackImageJpg;
};
</script>

<template>
  <Heading>
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
    hide-empty-box
  >
    <template #filter>
      <FilterForm />
    </template>
    <template #default="{ loading, emptyBoxVisible }">
      <BaseTable
        :records="vehicles?.items || []"
        primary-key="id"
        :columns="columns"
        :loading="loading"
        :empty-box-visible="emptyBoxVisible"
        default-sort="name asc"
        selectable
      >
        <template #col-image="{ record }">
          <LazyImage
            v-if="image(record)"
            :variant="LazyImageVariantsEnum.WIDE_SMALL"
            :src="image(record)"
            alt="Model storeImage"
            shadow
          />
        </template>
        <template #col-fleetchart="{ record }">
          <LazyImage
            v-if="record.model.media.angledView"
            :variant="LazyImageVariantsEnum.WIDE_SMALL"
            :src="record.model.media.angledView.small"
            alt="Model angledView"
            contain
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
