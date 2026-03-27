<script lang="ts">
export default {
  name: "AdminImagesList",
};
</script>

<script lang="ts" setup>
import FilterForm from "@/admin/components/Images/FilterForm/index.vue";
import FilteredList from "@/shared/components/FilteredList/index.vue";
import Loader from "@/shared/components/Loader/index.vue";
import BaseTable from "@/shared/components/base/Table/index.vue";
import { type BaseTableCol } from "@/shared/components/base/Table/types";
import Paginator from "@/shared/components/Paginator/index.vue";
import ViewImage from "@/shared/components/ViewImage/index.vue";
import { useImages as useImagesQuery } from "@/services/fyAdminApi";
import { usePagination } from "@/shared/composables/usePagination";
import { useImageFilters } from "@/admin/composables/useImageFilters";
import DirectUpload, {
  FileUpload,
} from "@/shared/components/DirectUpload/index.vue";
import {
  type GalleryTypeEnum,
  type ImageQuery,
  type Image,
  useCreateImage as useCreateImageMutation,
} from "@/services/fyAdminApi";
import { useI18n } from "@/shared/composables/useI18n";
import { LazyImageVariantsEnum } from "@/shared/components/LazyImage/types";
import ImageActions from "@/admin/components/Images/Actions/index.vue";

type Props = {
  name?: string;
  galleryId?: string;
  galleryType?: GalleryTypeEnum;
  filterable?: boolean;
};

const props = withDefaults(defineProps<Props>(), {
  name: "admin-images",
  galleryId: undefined,
  galleryType: undefined,
  filterable: false,
});

const { isFilterSelected } = useImageFilters();

const { l } = useI18n();

const route = useRoute();

const routeQuery = computed(() => {
  if (props.galleryId && props.galleryType) {
    return {
      galleryIdEq: props.galleryId,
      galleryTypeEq: props.galleryType,
    } as ImageQuery;
  }

  return (route.query.q || {}) as ImageQuery;
});

const { perPage, page, updatePerPage } = usePagination(props.name);

const { data, refetch, ...asyncStatus } = useImagesQuery({
  page: page.value,
  perPage: perPage.value,
  q: routeQuery.value,
});

watch(
  () => route.query,
  async () => {
    await refetch();
  },
  { deep: true },
);

const attachMutation = useCreateImageMutation();

const handleUploadDone = async (files: FileUpload[]) => {
  const blobIds = files
    .map((file) => file.blob?.signed_id)
    .filter((id): id is string => !!id);

  for (const blobId of blobIds) {
    await attachMutation.mutateAsync({
      data: {
        galleryId: props.galleryId,
        galleryType: props.galleryType,
        file: blobId,
      },
    });

    await refetch();
  }
};

const columns: BaseTableCol<Image>[] = [
  {
    name: "file",
    label: "",
    alignment: "center",
  },
  {
    name: "name",
    label: "Name",
    sortable: true,
  },
  {
    name: "createdAt",
    label: "created at?",
    mobile: false,
    sortable: true,
  },
  {
    name: "updatedAt",
    label: "updated at?",
    mobile: false,
    sortable: true,
  },
];
</script>

<template>
  <FilteredList
    :id="name"
    :name="name"
    :records="data?.items || []"
    :async-status="asyncStatus"
    primary-key="id"
    class="images"
    :is-filter-selected="isFilterSelected"
  >
    <template v-if="filterable" #filter>
      <FilterForm />
    </template>

    <template v-slot:header>
      <DirectUpload
        multiple
        inline
        hide-finished
        @upload:done="handleUploadDone"
      />
    </template>

    <template #default="{ loading, refetching, emptyVisible }">
      <BaseTable
        :records="data?.items || []"
        primary-key="id"
        :columns="columns"
        :loading="loading || refetching"
        :empty-visible="emptyVisible"
        default-sort="name asc"
        selectable
      >
        <template #loader="{ loading }">
          <Loader :loading="loading" admin />
        </template>
        <template #col-file="{ record }">
          <ViewImage
            :image="record"
            size="small"
            alt="image"
            :variant="LazyImageVariantsEnum.WIDE_SMALL"
            shadow
          />
        </template>
        <template #col-name="{ record }">
          {{ record.name }}
        </template>
        <template #col-createdAt="{ record }">
          {{ l(record.createdAt, "datetime.formats.short") }}
        </template>
        <template #col-updatedAt="{ record }">
          {{ l(record.updatedAt, "datetime.formats.short") }}
        </template>
        <template #actions="{ record }">
          <ImageActions :image="record" />
        </template>
      </BaseTable>
    </template>
    <template #pagination-top>
      <Paginator
        v-if="data"
        :query-result-ref="data"
        :per-page="perPage"
        :update-per-page="updatePerPage"
      />
    </template>

    <template #pagination-bottom>
      <Paginator
        v-if="data"
        :query-result-ref="data"
        :per-page="perPage"
        :update-per-page="updatePerPage"
      />
    </template>
  </FilteredList>
</template>
