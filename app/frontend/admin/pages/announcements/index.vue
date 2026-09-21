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
import RowList from "@/shared/components/RowList/index.vue";
import RowsSkeleton from "@/shared/components/RowsSkeleton/index.vue";
import SortBar from "@/shared/components/base/Table/SortBar/index.vue";
import AnnouncementRow from "@/admin/components/Announcements/Row/index.vue";
import {
  useAnnouncements,
  getAnnouncementsQueryKey,
  type AnnouncementSortEnum,
} from "@/services/fyAdminApi";
import { usePagination } from "@/shared/composables/usePagination";
import Paginator from "@/shared/components/Paginator/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import { useAnnouncementFilters } from "@/admin/composables/useAnnouncementFilters";
import { useAnnouncementSortFields } from "@/admin/composables/useAnnouncementSortFields";
import { useAnnouncementUpdates } from "@/admin/composables/useAnnouncementUpdates";

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

// A publish dispatches four channels that each settle from their own job, so
// the rows on screen move on their own from here on.
useAnnouncementUpdates();

const { t } = useI18n();

const sortFields = useAnnouncementSortFields();
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
    :is-filter-selected="isFilterSelected"
  >
    <template #skeleton="{ count }">
      <RowsSkeleton :count="count" icon meta trailing />
    </template>

    <template #sort>
      <SortBar :columns="sortFields" default-sort="createdAt desc" />
    </template>

    <!-- No `hide-empty`: the table used to draw its own empty row so the column
         headings survived it, and a row list has no headings to keep. The
         standard Empty box, and its reset-filters action, is the better answer
         here -- which is the call the catalogues already made. -->
    <template #default="{ records }">
      <RowList :records="records">
        <template #default="{ record }">
          <AnnouncementRow :announcement="record" />
        </template>
      </RowList>
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
