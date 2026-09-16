<script lang="ts">
export default {
  name: "AdminAnnouncementsPage",
};
</script>

<script lang="ts" setup>
import { BtnSizesEnum } from "@/shared/components/base/Btn/types";
import Heading from "@/shared/components/base/Heading/index.vue";
import HeadingSmall from "@/shared/components/base/Heading/Small/index.vue";
import FilteredList from "@/shared/components/FilteredList/index.vue";
import BaseTable from "@/shared/components/base/Table/index.vue";
import { type BaseTableCol } from "@/shared/components/base/Table/types";
import AnnouncementActions from "@/admin/components/Announcements/Actions/index.vue";
import AnnouncementStatusPill from "@/admin/components/Announcements/StatusPill/index.vue";
import AnnouncementDeliveries from "@/admin/components/Announcements/Deliveries/index.vue";
import {
  useAnnouncements,
  getAnnouncementsQueryKey,
  type Announcement,
  type AnnouncementSortEnum,
} from "@/services/fyAdminApi";
import { usePagination } from "@/shared/composables/usePagination";
import Paginator from "@/shared/components/Paginator/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import { useAnnouncementFilters } from "@/admin/composables/useAnnouncementFilters";

const route = useRoute();

const sorts = computed((): AnnouncementSortEnum[] => {
  return route.query.s ? [route.query.s as AnnouncementSortEnum] : [];
});

watch(
  () => sorts.value,
  async () => {
    await refetch();
  },
);

const announcementsQueryKey = computed(() => {
  return getAnnouncementsQueryKey(announcementsQueryParams.value);
});

const { perPage, page, updatePerPage } = usePagination(announcementsQueryKey);

const { filters, isFilterSelected } = useAnnouncementFilters(async () => {
  await refetch();
});

const announcementsQueryParams = computed(() => {
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
  data: announcements,
  refetch,
  ...asyncStatus
} = useAnnouncements(announcementsQueryParams);

const columns: BaseTableCol<Announcement>[] = [
  {
    name: "title",
    label: "Title",
    sortable: true,
  },
  {
    name: "status",
    label: "Status",
  },
  {
    name: "deliveries",
    label: "Channels",
    mobile: false,
  },
  {
    name: "recipients",
    label: "Recipients",
    mobile: false,
  },
  {
    name: "publishedAt",
    label: "Sent",
    sortable: true,
  },
];

const { t, l } = useI18n();
</script>

<template>
  <Heading hero>
    {{ t("headlines.admin.announcements.index") }}
    <HeadingSmall v-if="announcements">
      {{
        t("headlines.pagination.count", {
          current: announcements?.items.length,
          total: announcements?.meta.pagination?.totalCount,
        })
      }}
    </HeadingSmall>
  </Heading>

  <Teleport to="#header-right">
    <Btn
      :size="BtnSizesEnum.MD"
      :to="{ name: 'admin-announcement-create' }"
      :aria-label="t('actions.create')"
      mobile-icon-only
    >
      <i class="fa fa-plus" />
      {{ t("actions.create") }}
    </Btn>
  </Teleport>

  <FilteredList
    name="admin-announcements"
    :records="announcements?.items || []"
    :async-status="asyncStatus"
    hide-loading
    hide-empty
    :is-filter-selected="isFilterSelected"
  >
    <template #default="{ loading, refetching, emptyVisible }">
      <BaseTable
        :records="announcements?.items || []"
        primary-key="id"
        :columns="columns"
        :loading="loading || refetching"
        :empty-visible="emptyVisible"
        default-sort="createdAt desc"
      >
        <template #col-title="{ record }">
          <router-link
            v-if="record.publishable"
            :to="{ name: 'admin-announcement-edit', params: { id: record.id } }"
          >
            {{ record.title }}
          </router-link>
          <span v-else>{{ record.title }}</span>
        </template>
        <template #col-status="{ record }">
          <AnnouncementStatusPill :status="record.status" />
        </template>
        <template #col-deliveries="{ record }">
          <AnnouncementDeliveries :announcement="record" />
        </template>
        <template #col-recipients="{ record }">
          <span v-if="record.recipientsCount">
            {{ record.recipientsCount }}
          </span>
          <span v-else>—</span>
        </template>
        <template #col-publishedAt="{ record }">
          <span v-if="record.publishedAt">
            {{ l(record.publishedAt, "datetime.formats.short") }}
          </span>
          <span v-else-if="record.publishAt">
            {{ l(record.publishAt, "datetime.formats.short") }}
          </span>
          <span v-else>—</span>
        </template>
        <template #actions="{ record }">
          <AnnouncementActions :announcement="record" />
        </template>
      </BaseTable>
    </template>
    <template #pagination-top>
      <Paginator
        :query-result-ref="announcements"
        :per-page="perPage"
        :update-per-page="updatePerPage"
      />
    </template>
    <template #pagination-bottom>
      <Paginator
        :query-result-ref="announcements"
        :per-page="perPage"
        :update-per-page="updatePerPage"
      />
    </template>
  </FilteredList>
</template>
