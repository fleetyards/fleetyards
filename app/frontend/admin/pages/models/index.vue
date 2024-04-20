<script lang="ts">
export default {
  name: "AdminModelsPage",
};
</script>

<script lang="ts" setup>
import { useApiClient } from "@/admin/composables/useApiClient";
import { useQuery } from "@tanstack/vue-query";
import FilteredList from "@/shared/components/FilteredList/index.vue";
import BaseTable from "@/shared/components/base/Table/index.vue";
import { type BaseTableColumn } from "@/shared/components/base/Table/types";
import LazyImage from "@/shared/components/LazyImage/index.vue";
import { LazyImageVariantsEnum } from "@/shared/components/LazyImage/types";
import ModelActions from "@/admin/components/Models/Actions/index.vue";
import { type Models, type ApiError } from "@/services/fyAdminApi";

const { models: modelsService } = useApiClient();

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

const {
  data: models,
  refetch,
  ...asyncStatus
} = useQuery<Models, ApiError>({
  queryKey: ["models", sorts.value],
  queryFn: () =>
    modelsService.models({
      s: sorts.value,
    }),
});

const columns = computed<BaseTableColumn[]>(() => {
  return [
    {
      name: "storeImage",
      label: "",
      centered: true,
    },
    {
      name: "rsiStoreImage",
      label: "",
      centered: true,
      mobile: false,
    },
    {
      name: "angledView",
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
      name: "rsiId",
      label: "RSI ID",
      field: "rsi_id",
      sortable: true,
    },
    {
      name: "hidden",
      label: "hidden?",
      mobile: false,
      sortable: true,
    },
    {
      name: "active",
      label: "active?",
      mobile: false,
      sortable: true,
    },
  ];
});
</script>

<template>
  <FilteredList
    v-if="models"
    name="admin-models"
    :records="models.items || []"
    :async-status="asyncStatus"
  >
    <template #default>
      <BaseTable
        :records="models.items || []"
        primary-key="id"
        :columns="columns"
        selectable
      >
        <template #col-storeImage="{ record }">
          <LazyImage
            v-if="record.media.storeImage"
            :variant="LazyImageVariantsEnum.WIDE_SMALL"
            :src="record.media.storeImage.small"
            alt="Model storeImage"
            shadow
          />
        </template>
        <template #col-rsiStoreImage="{ record }">
          <LazyImage
            v-if="record.media.storeImage"
            :variant="LazyImageVariantsEnum.WIDE_SMALL"
            :src="record.media.storeImage.small"
            alt="Model rsiStoreImage"
            shadow
          />
        </template>
        <template #col-angledView="{ record }">
          <LazyImage
            v-if="record.media.angledView"
            :variant="LazyImageVariantsEnum.WIDE_SMALL"
            :src="record.media.angledView.small"
            alt="Model angledView"
            contain
          />
        </template>
        <template #col-name="{ record }">
          <router-link
            :to="{
              name: 'admin-model',
              params: {
                id: record.id,
              },
            }"
          >
            {{ record.manufacturer?.code }} {{ record.name }}
          </router-link>
        </template>
        <template #col-rsiId="{ record }">
          {{ record.rsiId }}
        </template>
        <template #col-hidden="{ record }">
          <i v-if="record.hidden" class="fad fa-check" />
          <i v-else class="fad fa-times" />
        </template>
        <template #col-active="{ record }">
          <i v-if="record.active" class="fad fa-check" />
          <i v-else class="fad fa-times" />
        </template>
        <template #actions="{ record }">
          <ModelActions :record="record" />
        </template>
      </BaseTable>
    </template>
  </FilteredList>
</template>
