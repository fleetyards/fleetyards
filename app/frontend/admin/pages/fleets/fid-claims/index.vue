<script lang="ts">
export default {
  name: "AdminFleetFidClaimsPage",
};
</script>

<script lang="ts" setup>
import Heading from "@/shared/components/base/Heading/index.vue";
import HeadingSmall from "@/shared/components/base/Heading/Small/index.vue";
import BreadCrumbs from "@/shared/components/BreadCrumbs/index.vue";
import { type Crumb } from "@/shared/components/BreadCrumbs/types";
import FilteredList from "@/shared/components/FilteredList/index.vue";
import BaseTable from "@/shared/components/base/Table/index.vue";
import { type BaseTableCol } from "@/shared/components/base/Table/types";
import Paginator from "@/shared/components/Paginator/index.vue";
import FleetFidClaimActions from "@/admin/components/FleetFidClaims/Actions/index.vue";
import {
  type AdminFleetFidClaim,
  getFleetFidClaimsQueryKey,
  useFleetFidClaims,
} from "@/services/fyAdminApi";
import { usePagination } from "@/shared/composables/usePagination";
import { useI18n } from "@/shared/composables/useI18n";

const { t, l } = useI18n();

const crumbs = computed<Crumb[]>(() => [
  {
    to: { name: "admin-fleets" },
    label: t("nav.admin.fleets.index"),
  },
  {
    label: t("nav.admin.fleetFidClaims.index"),
  },
]);

const claimsQueryKey = computed(() =>
  getFleetFidClaimsQueryKey(claimsQueryParams.value),
);

const { perPage, page, updatePerPage } = usePagination(claimsQueryKey);

const claimsQueryParams = computed(() => ({
  page: page.value,
}));

const { data: claims, ...asyncStatus } = useFleetFidClaims(claimsQueryParams);

const columns: BaseTableCol<AdminFleetFidClaim>[] = [
  {
    name: "fid",
    label: "FID",
  },
  {
    name: "claimant",
    label: "Claimant",
  },
  {
    name: "holder",
    label: "Holder",
  },
  {
    name: "endsAt",
    label: "Ends At",
    mobile: false,
  },
  {
    name: "createdAt",
    label: "Opened At",
    mobile: false,
  },
];
</script>

<template>
  <BreadCrumbs :crumbs="crumbs" />

  <Heading hero>
    {{ t("headlines.admin.fleetFidClaims.index") }}
    <HeadingSmall v-if="claims">
      {{
        t("headlines.pagination.count", {
          current: claims?.items.length,
          total: claims?.meta.pagination?.totalCount,
        })
      }}
    </HeadingSmall>
  </Heading>

  <FilteredList
    name="admin-fleet-fid-claims"
    :records="claims?.items || []"
    :async-status="asyncStatus"
    hide-loading
    hide-empty
  >
    <template #default="{ loading, refetching, emptyVisible }">
      <BaseTable
        :records="claims?.items || []"
        primary-key="id"
        :columns="columns"
        :loading="loading || refetching"
        :empty-visible="emptyVisible"
      >
        <template #col-fid="{ record }">
          {{ record.fid }}
        </template>
        <template #col-claimant="{ record }">
          <router-link
            :to="{
              name: 'admin-fleet-edit',
              params: { id: record.claimantId },
            }"
          >
            {{ record.claimantName }} ({{ record.claimantFid }})
          </router-link>
        </template>
        <template #col-holder="{ record }">
          <router-link
            v-if="record.holderId"
            :to="{ name: 'admin-fleet-edit', params: { id: record.holderId } }"
          >
            {{ record.holderName }} ({{ record.holderFid }})
          </router-link>
          <template v-else>—</template>
        </template>
        <template #col-endsAt="{ record }">
          {{ l(record.endsAt, "datetime.formats.short") }}
        </template>
        <template #col-createdAt="{ record }">
          {{ l(record.createdAt, "datetime.formats.short") }}
        </template>
        <template #actions="{ record }">
          <FleetFidClaimActions :claim="record" />
        </template>
      </BaseTable>
    </template>
    <template #pagination-top>
      <Paginator
        :query-result-ref="claims"
        :per-page="perPage"
        :update-per-page="updatePerPage"
      />
    </template>
    <template #pagination-bottom>
      <Paginator
        :query-result-ref="claims"
        :per-page="perPage"
        :update-per-page="updatePerPage"
      />
    </template>
  </FilteredList>
</template>
