<script lang="ts">
export default {
  name: "AdminOauthApplicationsPage",
};
</script>

<script lang="ts" setup>
import Heading from "@/shared/components/base/Heading/index.vue";
import HeadingSmall from "@/shared/components/base/Heading/Small/index.vue";
import FilteredList from "@/shared/components/FilteredList/index.vue";
import BaseTable from "@/shared/components/base/Table/index.vue";
import { type BaseTableCol } from "@/shared/components/base/Table/types";
import LazyImage from "@/shared/components/LazyImage/index.vue";
import { LazyImageVariantsEnum } from "@/shared/components/LazyImage/types";
import PageActions from "@/shared/components/PageActions/index.vue";
import {
  useOauthApplications,
  type OauthApplication,
  type OauthApplicationQuery,
  type OauthApplicationSortEnum,
} from "@/services/fyAdminApi";
import { usePagination } from "@/shared/composables/usePagination";
import { useFilters } from "@/shared/composables/useFilters";
import Paginator from "@/shared/components/Paginator/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import OauthApplicationActions from "@/admin/components/OauthApplications/Actions/index.vue";
import FilterForm from "@/admin/components/OauthApplications/FilterForm/index.vue";
import OauthApplicationState from "@/shared/components/OauthApplicationState/index.vue";
import BulkSelectionBar from "@/shared/components/BulkSelectionBar/index.vue";
import Btn from "@/shared/components/base/Btn/index.vue";
import { useBulkSelection } from "@/shared/composables/useBulkSelection";
import { useComlink } from "@/shared/composables/useComlink";

const { t, l } = useI18n();

const route = useRoute();

const sorts = computed((): OauthApplicationSortEnum[] => {
  return [route.query.s].flat().filter(Boolean) as OauthApplicationSortEnum[];
});

const { perPage, page, updatePerPage } = usePagination();

const { filters, isFilterSelected } = useFilters<OauthApplicationQuery>();

const queryParams = computed(() => {
  return {
    page: page.value,
    perPage: perPage.value,
    q: {
      ...filters.value,
      sorts: sorts.value,
    },
  };
});

const { data: oauthApplications, ...asyncStatus } =
  useOauthApplications(queryParams);

const records = computed(() => oauthApplications.value?.items || []);

const totalCount = computed(
  () => oauthApplications.value?.meta.pagination?.totalCount,
);

const {
  selectedIds,
  allMatchingSelected,
  selectedCount,
  matchingCount,
  pageSelected,
  pagePartiallySelected,
  canSelectAllMatching,
  togglePage,
  selectAllMatching,
  clear: clearSelection,
  payload: bulkPayload,
} = useBulkSelection(records, () => filters.value, totalCount);

const comlink = useComlink();

// The modal owns the reason, because it is required and there is nowhere on a
// toolbar to type one.
const rejectSelected = () => {
  if (!selectedCount.value) return;

  comlink.emit("open-modal", {
    component: () =>
      import("@/admin/components/OauthApplications/RejectModal/index.vue"),
    props: {
      bulkPayload: bulkPayload.value,
      count: selectedCount.value,
      onRejected: clearSelection,
    },
  });
};

const columns: BaseTableCol<OauthApplication>[] = [
  {
    name: "name",
    label: t("labels.oauthApplications.name"),
    sortable: true,
    flexGrow: 2,
  },
  {
    name: "aasmState",
    label: t("labels.oauthApplications.state"),
    sortable: true,
    flexGrow: 1,
  },
  {
    name: "ownerName",
    label: t("labels.oauthApplications.owner"),
    mobile: false,
  },
  {
    name: "scopes",
    label: t("labels.oauthApplications.scopes"),
    mobile: false,
    flexGrow: 1,
  },
  {
    name: "authorizedUsersCount",
    label: t("labels.oauthApplications.authorizedUsers"),
    alignment: "right",
    mobile: false,
    sortable: true,
  },
  {
    name: "createdAt",
    label: t("labels.createdAt"),
    mobile: false,
    sortable: true,
  },
  {
    name: "updatedAt",
    label: t("labels.updatedAt"),
    mobile: false,
    sortable: true,
  },
];

const scopeList = (record: OauthApplication) =>
  record.scopes.split(" ").filter(Boolean);

const redirectUris = (record: OauthApplication) =>
  record.redirectUri.split(/\s+/).filter(Boolean);

// The host is what tells two registrations apart at a glance; the full URI
// is on the edit page.
const redirectHost = (uri: string) => {
  try {
    return new URL(uri).host || uri;
  } catch {
    return uri;
  }
};

const reviewSummary = (record: OauthApplication) => {
  const date =
    record.state === "rejected" ? record.rejectedAt : record.approvedAt;

  if (!record.reviewedByName || !date) return undefined;

  return t("labels.oauthApplications.reviewedByOn", {
    name: record.reviewedByName,
    date: l(date, "datetime.formats.short"),
  });
};

const ownerFilter = (record: OauthApplication) => ({
  query: { ...route.query, ownerIdEq: record.ownerId, page: undefined },
});
</script>

<template>
  <Heading hero mobile-hidden>
    {{ t("headlines.admin.oauthApplications.index") }}
    <HeadingSmall v-if="oauthApplications">
      {{
        t("headlines.pagination.count", {
          current: oauthApplications?.items.length,
          total: oauthApplications?.meta.pagination?.totalCount,
        })
      }}
    </HeadingSmall>
  </Heading>

  <PageActions>
    <Btn
      :to="{ name: 'admin-oauth-application-create' }"
      :aria-label="t('actions.create')"
    >
      <i class="fa fa-plus" />
      {{ t("actions.create") }}
    </Btn>
  </PageActions>

  <FilteredList
    name="admin-oauth-applications"
    :records="records"
    :async-status="asyncStatus"
    :is-filter-selected="isFilterSelected"
    hide-loading
    hide-empty
  >
    <template #filter>
      <FilterForm />
    </template>
    <template #default="{ loading, refetching, emptyVisible }">
      <BulkSelectionBar
        :disabled="!records.length"
        :selected-count="selectedCount"
        :matching-count="matchingCount"
        :page-selected="pageSelected"
        :page-partially-selected="pagePartiallySelected"
        :can-select-all-matching="canSelectAllMatching"
        :all-matching-selected="allMatchingSelected"
        @toggle-page="togglePage"
        @select-all-matching="selectAllMatching"
        @clear="clearSelection"
      >
        <Btn
          v-tooltip="t('actions.oauthApplications.rejectSelected')"
          :aria-label="t('actions.oauthApplications.rejectSelected')"
          data-test="bulk-reject"
          @click="rejectSelected"
        >
          <i class="fa-duotone fa-circle-xmark" />
        </Btn>
      </BulkSelectionBar>

      <BaseTable
        :records="records"
        primary-key="id"
        :columns="columns"
        :loading="loading || refetching"
        :empty-visible="emptyVisible"
        default-sort="createdAt desc"
        :selected="selectedIds"
        selectable
        data-test="oauth-applications-list"
        @selected-change="selectedIds = $event"
      >
        <template #col-name="{ record, mobile }">
          <div class="app-summary">
            <div class="app-logo">
              <LazyImage
                v-if="record.logo"
                :variant="LazyImageVariantsEnum.EXTRA_SMALL"
                :src="record.logo.smallUrl || record.logo.url"
                :alt="t('labels.oauthApplications.logo')"
                transparent
              />
              <i v-else class="fa-duotone fa-key" aria-hidden="true" />
            </div>
            <div class="app-text">
              <router-link
                :to="{
                  name: 'admin-oauth-application-edit',
                  params: { id: record.id },
                }"
                class="app-name"
              >
                {{ record.name }}
              </router-link>
              <small class="app-detail" data-test="redirect-host">
                {{ redirectHost(redirectUris(record)[0] || "") }}
                <template v-if="redirectUris(record).length > 1">
                  {{
                    t("labels.oauthApplications.moreRedirectUris", {
                      count: redirectUris(record).length - 1,
                    })
                  }}
                </template>
              </small>
              <template v-if="mobile">
                <small class="app-detail" data-test="mobile-owner">
                  <i class="fa-duotone fa-user" aria-hidden="true" />
                  {{ record.ownerName || "-" }}
                  ·
                  {{
                    t("labels.oauthApplications.authorizedUsersCount", {
                      count: record.authorizedUsersCount,
                    })
                  }}
                </small>
                <small class="app-detail" data-test="mobile-scopes">
                  <i class="fa-duotone fa-shield-keyhole" aria-hidden="true" />
                  {{
                    scopeList(record).join(", ") ||
                    t("labels.oauthApplications.defaultScopes")
                  }}
                </small>
              </template>
              <code v-else class="app-detail app-uid">{{ record.uid }}</code>
            </div>
          </div>
        </template>
        <template #col-aasmState="{ record }">
          <div class="app-review">
            <OauthApplicationState :state="record.state" />
            <small
              v-if="record.state === 'rejected' && record.rejectionReason"
              class="app-detail app-reason"
              :title="record.rejectionReason"
              data-test="rejection-reason"
            >
              {{ record.rejectionReason }}
            </small>
            <small
              v-if="reviewSummary(record)"
              class="app-detail"
              data-test="review-summary"
            >
              {{ reviewSummary(record) }}
            </small>
          </div>
        </template>
        <template #col-ownerName="{ record }">
          <router-link
            v-if="record.ownerName && record.ownerId"
            v-tooltip="
              t('labels.oauthApplications.filterByOwner', {
                name: record.ownerName,
              })
            "
            :to="ownerFilter(record)"
            data-test="owner-filter"
          >
            {{ record.ownerName }}
          </router-link>
          <span v-else>-</span>
        </template>
        <template #col-scopes="{ record }">
          <div v-if="scopeList(record).length" class="app-scopes">
            <code v-for="scope in scopeList(record)" :key="scope">
              {{ scope }}
            </code>
          </div>
          <em v-else class="app-detail">
            {{ t("labels.oauthApplications.defaultScopes") }}
          </em>
          <small class="app-detail">
            {{
              record.confidential
                ? t("labels.oauthApplications.confidentialShort")
                : t("labels.oauthApplications.publicShort")
            }}
          </small>
        </template>
        <template #col-authorizedUsersCount="{ record }">
          {{ record.authorizedUsersCount }}
        </template>
        <template #col-createdAt="{ record }">
          {{ l(record.createdAt, "datetime.formats.short") }}
        </template>
        <template #col-updatedAt="{ record }">
          {{ l(record.updatedAt, "datetime.formats.short") }}
        </template>
        <template #actions="{ record }">
          <OauthApplicationActions :oauth-application="record" />
        </template>
      </BaseTable>
    </template>
    <template #pagination-top>
      <Paginator
        :query-result-ref="oauthApplications"
        :per-page="perPage"
        :update-per-page="updatePerPage"
      />
    </template>
    <template #pagination-bottom>
      <Paginator
        :query-result-ref="oauthApplications"
        :per-page="perPage"
        :update-per-page="updatePerPage"
      />
    </template>
  </FilteredList>
</template>

<style lang="scss" scoped>
.app-summary {
  display: flex;
  align-items: center;
  gap: 0.75rem;
  min-width: 0;
}

.app-logo {
  display: flex;
  flex: 0 0 2.5rem;
  align-items: center;
  justify-content: center;
  width: 2.5rem;
  height: 2.5rem;
  overflow: hidden;
  border-radius: var(--border-radius, 4px);
  color: var(--color-text-dim);
  font-size: 1.25rem;
}

.app-text,
.app-review {
  min-width: 0;
}

.app-name {
  display: block;
  overflow-wrap: anywhere;
}

.app-detail {
  display: block;
  color: var(--color-text-dim);
  overflow-wrap: anywhere;
}

.app-uid {
  font-size: 0.75rem;
}

.app-reason {
  display: -webkit-box;
  overflow: hidden;
  -webkit-line-clamp: 2;
  -webkit-box-orient: vertical;
}

.app-review {
  display: flex;
  flex-direction: column;
  align-items: flex-start;
  gap: 0.25rem;
}

.app-scopes {
  display: flex;
  flex-wrap: wrap;
  gap: 0.25rem;
}
</style>
