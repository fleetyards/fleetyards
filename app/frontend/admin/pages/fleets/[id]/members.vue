<script lang="ts">
export default {
  name: "AdminFleetMembersPage",
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
import { useAppNotifications } from "@/shared/composables/useAppNotifications";
import { BtnSizesEnum } from "@/shared/components/base/Btn/types";
import {
  type Fleet,
  type AdminFleetMember,
  type FleetMembershipSortEnum,
  useFleetMembers as useFleetMembersQuery,
  getFleetMembersQueryKey,
  loginAsFleetMember,
} from "@/services/fyAdminApi";

type Props = {
  fleet: Fleet;
};

const props = defineProps<Props>();

const { t, lUtc: l, timeDistance } = useI18n();
const { displayConfirm } = useAppNotifications();

const route = useRoute();

const sorts = computed((): FleetMembershipSortEnum[] => {
  return route.query.s ? [route.query.s as FleetMembershipSortEnum] : [];
});

watch(
  () => sorts.value,
  async () => {
    await refetch();
  },
);

const membersQueryParams = computed(() => {
  return {
    page: page.value,
    perPage: perPage.value,
    q: {
      sorts: sorts.value,
    },
  };
});

const membersQueryKey = computed(() => {
  return getFleetMembersQueryKey(props.fleet.id, membersQueryParams.value);
});

const { perPage, page, updatePerPage } = usePagination(membersQueryKey);

const {
  data: members,
  refetch,
  ...asyncStatus
} = useFleetMembersQuery(props.fleet.id, membersQueryParams);

const columns: BaseTableCol<AdminFleetMember>[] = [
  {
    name: "avatar",
    label: "",
  },
  {
    name: "username",
    label: t("labels.username"),
    sortable: true,
  },
  {
    name: "email",
    label: t("labels.email"),
    sortable: true,
  },
  {
    name: "rsiHandle",
    attributeKey: "rsiHandle",
    label: t("labels.user.rsiHandle"),
  },
  {
    name: "role",
    label: t("labels.fleet.members.role"),
  },
  {
    name: "status",
    label: t("labels.status"),
  },
  {
    name: "lastActiveAt",
    attributeKey: "lastActiveAt",
    label: t("labels.user.lastActiveAt"),
    sortable: true,
  },
  {
    name: "createdAt",
    attributeKey: "createdAt",
    label: t("labels.createdAt"),
    sortable: true,
  },
];

const loginAs = (member: AdminFleetMember) => {
  displayConfirm({
    text: t("messages.confirm.user.loginAs"),
    onConfirm: async () => {
      await loginAsFleetMember(props.fleet.id, member.id);
      window.open(window.FRONTEND_ENDPOINT, "_blank");
    },
  });
};
</script>

<template>
  <Heading hero>
    {{ t("headlines.admin.fleets.members") }}
    <HeadingSmall v-if="members">
      {{
        t("headlines.pagination.count", {
          current: members?.items.length,
          total: members?.meta.pagination?.totalCount,
        })
      }}
    </HeadingSmall>
  </Heading>

  <FilteredList
    v-if="members"
    name="admin-fleet-members"
    :records="members.items || []"
    :async-status="asyncStatus"
    hide-loading
    hide-empty
  >
    <template #default="{ loading, refetching, emptyVisible }">
      <BaseTable
        :records="members.items || []"
        primary-key="id"
        :columns="columns"
        :loading="loading || refetching"
        :empty-visible="emptyVisible"
        selectable
      >
        <template #col-avatar="{ record }">
          <LazyImage
            v-if="record.avatar"
            :variant="LazyImageVariantsEnum.EXTRA_SMALL"
            :src="record.avatar?.smallUrl"
            alt="User Avatar"
            shadow
          />
        </template>
        <template #col-lastActiveAt="{ record }">
          <template v-if="record.lastActiveAt">
            {{ timeDistance(record.lastActiveAt) }}
          </template>
        </template>
        <template #col-createdAt="{ record }">
          {{ l(record.createdAt, "datetime.formats.short") }}
        </template>
        <template #actions="{ record }">
          <Btn
            v-tooltip="t('actions.users.loginAs')"
            :size="BtnSizesEnum.SMALL"
            @click="loginAs(record)"
          >
            <i class="fa-duotone fa-right-to-bracket" />
          </Btn>
        </template>
      </BaseTable>
    </template>
    <template #pagination-top>
      <Paginator
        v-if="members"
        :query-result-ref="members"
        :per-page="perPage"
        :update-per-page="updatePerPage"
      />
    </template>
    <template #pagination-bottom>
      <Paginator
        v-if="members"
        :query-result-ref="members"
        :per-page="perPage"
        :update-per-page="updatePerPage"
      />
    </template>
  </FilteredList>
</template>
