<script lang="ts">
export default {
  name: "AdminModelEditVideosPage",
};
</script>

<script lang="ts" setup>
import { useI18n } from "@/shared/composables/useI18n";
import Heading from "@/shared/components/base/Heading/index.vue";
import {
  type ModelExtended,
  type ModelUpdateInput,
} from "@/services/fyAdminApi";
import { useForm } from "vee-validate";
import {
  useModelVideos as useModelVideosQuery,
  type Video,
} from "@/services/fyAdminApi";
import { usePagination } from "@/shared/composables/usePagination";
import FilteredList from "@/shared/components/FilteredList/index.vue";
import BaseTable, {
  type BaseTableCol,
} from "@/shared/components/base/Table/index.vue";
import Paginator from "@/shared/components/Paginator/index.vue";
import Loader from "@/shared/components/Loader/index.vue";

type Props = {
  model: ModelExtended;
};

const props = defineProps<Props>();

const { t, l } = useI18n();

const initialValues = ref<ModelUpdateInput>({
  size: props.model.metrics.size,
  length: props.model.metrics.length,
  beam: props.model.metrics.beam,
  height: props.model.metrics.height,
});

const validationSchema = {};

useForm({
  initialValues: initialValues.value,
  validationSchema,
});

const { perPage, page, updatePerPage } = usePagination("admin-model-videos");

const { data, ...asyncStatus } = useModelVideosQuery(props.model.id, {
  page: page.value,
  perPage: perPage.value,
});

const columns: BaseTableCol<Video>[] = [
  {
    name: "url",
    label: "",
    alignment: "center",
  },
  {
    name: "type",
    label: "Type",
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

// const [size, sizeProps] = defineField("size");
</script>

<template>
  <Heading>{{ t("headlines.admin.models.edit.videos") }}</Heading>

  <FilteredList
    name="admin-model-videos"
    :records="data?.items || []"
    :async-status="asyncStatus"
    primary-key="id"
  >
    <template v-slot:header> Form </template>

    <template #default="{ loading, emptyVisible }">
      <BaseTable
        :records="data?.items || []"
        primary-key="id"
        :columns="columns"
        :loading="loading"
        :empty-visible="emptyVisible"
        default-sort="name asc"
        selectable
      >
        <template #loader="{ loading }">
          <Loader :loading="loading" admin />
        </template>
        <template #col-url="{ record }">
          {{ record.url }}
        </template>
        <template #col-type="{ record }">
          {{ record.type }}
        </template>
        <template #col-createdAt="{ record }">
          {{ l(record.createdAt, "datetime.formats.short") }}
        </template>
        <template #col-updatedAt="{ record }">
          {{ l(record.updatedAt, "datetime.formats.short") }}
        </template>
        <template #actions> Actions </template>
      </BaseTable>
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
