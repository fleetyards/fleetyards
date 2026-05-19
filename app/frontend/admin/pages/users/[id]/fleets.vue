<script lang="ts">
export default {
  name: "AdminUserFleetsPage",
};
</script>

<script lang="ts" setup>
import { useI18n } from "@/shared/composables/useI18n";
import Heading from "@/shared/components/base/Heading/index.vue";
import FilteredList from "@/shared/components/FilteredList/index.vue";
import BaseTable from "@/shared/components/base/Table/index.vue";
import LazyImage from "@/shared/components/LazyImage/index.vue";
import Paginator from "@/shared/components/Paginator/index.vue";
import { BaseTableCol } from "@/shared/components/base/Table/types";
import { usePagination } from "@/shared/composables/usePagination";
import { LazyImageVariantsEnum } from "@/shared/components/LazyImage/types";
import {
  type User,
  type AdminUserFleet,
  useUserFleets as useUserFleetsQuery,
  getUserFleetsQueryKey,
} from "@/services/fyAdminApi";

type Props = {
  user: User;
};

const props = defineProps<Props>();

const { t, lUtc: l } = useI18n();

const fleetsQueryParams = computed(() => ({
  page: page.value,
  perPage: perPage.value,
}));

const fleetsQueryKey = computed(() =>
  getUserFleetsQueryKey(props.user.id!, fleetsQueryParams.value),
);

const { perPage, page, updatePerPage } = usePagination(fleetsQueryKey);

const { data: fleets, ...asyncStatus } = useUserFleetsQuery(
  props.user.id!,
  fleetsQueryParams,
);

const columns: BaseTableCol<AdminUserFleet>[] = [
  {
    name: "logo",
    label: "",
  },
  {
    name: "name",
    label: t("labels.fleet.name"),
  },
  {
    name: "role",
    label: t("labels.fleet.members.role"),
  },
  {
    name: "permanent",
    label: t("labels.fleet.roles.permanent"),
  },
  {
    name: "primary",
    label: t("labels.fleet.members.primary"),
  },
  {
    name: "status",
    label: t("labels.status"),
  },
  {
    name: "membersCount",
    label: t("labels.fleet.members.accepted"),
  },
  {
    name: "createdAt",
    label: t("labels.createdAt"),
  },
];
</script>

<template>
  <Heading hero>
    {{ t("headlines.admin.users.fleets") }}
    <HeadingSmall v-if="fleets">
      {{
        t("headlines.pagination.count", {
          current: fleets?.items.length,
          total: fleets?.meta.pagination?.totalCount,
        })
      }}
    </HeadingSmall>
  </Heading>

  <FilteredList
    v-if="fleets"
    name="admin-user-fleets"
    :records="fleets.items || []"
    :async-status="asyncStatus"
    hide-loading
    hide-empty
  >
    <template #default="{ loading, refetching, emptyVisible }">
      <BaseTable
        :records="fleets.items || []"
        primary-key="id"
        :columns="columns"
        :loading="loading || refetching"
        :empty-visible="emptyVisible"
      >
        <template #col-logo="{ record }">
          <LazyImage
            v-if="record.logo"
            :variant="LazyImageVariantsEnum.EXTRA_SMALL"
            :src="record.logo?.smallUrl"
            alt="Fleet Logo"
            shadow
          />
        </template>
        <template #col-name="{ record }">
          <router-link
            :to="{
              name: 'admin-fleet-edit',
              params: { id: record.fleetId },
            }"
          >
            {{ record.name }}
          </router-link>
        </template>
        <template #col-permanent="{ record }">
          <i
            v-if="record.permanent"
            v-tooltip="t('labels.fleet.roles.permanent')"
            class="fa-duotone fa-check"
          />
        </template>
        <template #col-primary="{ record }">
          <i
            v-if="record.primary"
            v-tooltip="t('labels.fleet.members.primary')"
            class="fa-duotone fa-check"
          />
        </template>
        <template #col-createdAt="{ record }">
          {{ l(record.createdAt, "datetime.formats.short") }}
        </template>
      </BaseTable>
    </template>
    <template #pagination-top>
      <Paginator
        v-if="fleets"
        :query-result-ref="fleets"
        :per-page="perPage"
        :update-per-page="updatePerPage"
      />
    </template>
    <template #pagination-bottom>
      <Paginator
        v-if="fleets"
        :query-result-ref="fleets"
        :per-page="perPage"
        :update-per-page="updatePerPage"
      />
    </template>
  </FilteredList>
</template>
