<script lang="ts">
export default {
  name: "AdminSupporterContributionsPage",
};
</script>

<script lang="ts" setup>
import PageActions from "@/shared/components/PageActions/index.vue";
import Heading from "@/shared/components/base/Heading/index.vue";
import HeadingSmall from "@/shared/components/base/Heading/Small/index.vue";
import Panel from "@/shared/components/base/Panel/index.vue";
import PanelHeading from "@/shared/components/base/Panel/Heading/index.vue";
import PanelBody from "@/shared/components/base/Panel/Body/index.vue";
import FilteredList from "@/shared/components/FilteredList/index.vue";
import BaseTable from "@/shared/components/base/Table/index.vue";
import { type BaseTableCol } from "@/shared/components/base/Table/types";
import SupporterContributionActions from "@/admin/components/SupporterContributions/Actions/index.vue";
import FilterForm from "@/admin/components/SupporterContributions/FilterForm/index.vue";
import Stats from "@/admin/components/SupporterContributions/Stats/index.vue";
import LinkedViaPill from "@/admin/components/SupporterContributions/LinkedViaPill/index.vue";
import SourcePill from "@/admin/components/SupporterContributions/SourcePill/index.vue";
import MonthlyChart from "@/admin/components/SupporterContributions/MonthlyChart/index.vue";
import {
  useSupporterContributions,
  useSupporterContributionsStats,
  useSyncSupporterContributionsFromPatreon,
  useUpdateSupporterContributionsBulk,
  useDestroySupporterContributionsBulk,
  getSupporterContributionsQueryKey,
  SupporterContributionSourceEnum,
  type NullableSupporterContributionSourceEnum,
  type SupporterContribution,
  type SupporterContributionSortEnum,
  type SupporterContributionUpdateBulkInput,
} from "@/services/fyAdminApi";
import { usePagination } from "@/shared/composables/usePagination";
import Paginator from "@/shared/components/Paginator/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import { useCurrencyFormat } from "@/shared/composables/useCurrencyFormat";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";
import { useSupporterContributionFilters } from "@/admin/composables/useSupporterContributionFilters";
import BtnDropdown from "@/shared/components/base/BtnDropdown/index.vue";
import { BtnTonesEnum } from "@/shared/components/base/Btn/types";
import { useQueryClient } from "@tanstack/vue-query";

const route = useRoute();

const sorts = computed((): SupporterContributionSortEnum[] => {
  return route.query.s ? [route.query.s as SupporterContributionSortEnum] : [];
});

watch(
  () => sorts.value,
  async () => {
    await refetch();
  },
);

const { perPage, page, updatePerPage } = usePagination();

const { filters, isFilterSelected } = useSupporterContributionFilters(
  async () => {
    await refetch();
  },
);

const supporterContributionsQueryParams = computed(() => {
  return {
    page: page.value,
    perPage: perPage.value,
    q: {
      ...filters.value,
      sorts: sorts.value,
    },
  };
});

const statsQueryParams = computed(() => {
  return {
    q: {
      ...filters.value,
    },
  };
});

const { data: stats } = useSupporterContributionsStats(statsQueryParams);

const {
  data: supporterContributions,
  refetch,
  ...asyncStatus
} = useSupporterContributions(supporterContributionsQueryParams);

const { t, l } = useI18n();
const { formatCents } = useCurrencyFormat();
const { displayInfo, displaySuccess, displayAlert } = useAppNotifications();
const queryClient = useQueryClient();

const selected = ref<string[]>([]);

const onSelectedChange = (ids: string[]) => {
  selected.value = ids;
};

const updateBulkMutation = useUpdateSupporterContributionsBulk();
const destroyBulkMutation = useDestroySupporterContributionsBulk();

const bulkPending = computed(
  () =>
    updateBulkMutation.isPending.value || destroyBulkMutation.isPending.value,
);

const afterBulk = (count: number, successKey: string) => {
  selected.value = [];
  void queryClient.invalidateQueries({
    queryKey: getSupporterContributionsQueryKey(),
  });

  if (count === 0) {
    displayInfo({
      text: t("messages.admin.supporterContributions.bulkUnchanged"),
    });

    return;
  }

  displaySuccess({ text: t(successKey, { count }) });
};

const sourceOptions = [
  ...Object.values(SupporterContributionSourceEnum).map((source) => ({
    label: t(`labels.admin.supporterContributions.source.${source}`),
    value: source as NullableSupporterContributionSourceEnum,
  })),
  {
    label: t("labels.supporterContribution.sourceUnspecified"),
    value: null as NullableSupporterContributionSourceEnum,
  },
];

const updateSelected = async (
  attributes: Omit<SupporterContributionUpdateBulkInput, "ids">,
) => {
  try {
    const { count } = await updateBulkMutation.mutateAsync({
      data: { ids: selected.value, ...attributes },
    });

    afterBulk(count, "messages.admin.supporterContributions.updatedBulk");
  } catch {
    displayAlert({
      text: t("messages.admin.supporterContributions.bulkError"),
    });
  }
};

const destroySelected = async () => {
  try {
    const { count } = await destroyBulkMutation.mutateAsync({
      data: { ids: selected.value },
    });

    afterBulk(count, "messages.admin.supporterContributions.destroyedBulk");
  } catch {
    displayAlert({
      text: t("messages.admin.supporterContributions.bulkError"),
    });
  }
};

const columns: BaseTableCol<SupporterContribution>[] = [
  {
    name: "name",
    label: t("labels.supporterContribution.name"),
    sortable: true,
  },
  {
    name: "amount",
    label: t("labels.supporterContribution.amount"),
    sortable: false,
  },
  {
    name: "user",
    label: t("labels.supporterContribution.user"),
    mobile: false,
  },
  {
    name: "linkedVia",
    label: t("labels.supporterContribution.linkedVia"),
    mobile: false,
  },
  {
    name: "startedAt",
    label: t("labels.supporterContribution.startedAt"),
    sortable: true,
  },
  {
    name: "endedAt",
    label: t("labels.supporterContribution.endedAt"),
    mobile: false,
    sortable: true,
  },
  {
    name: "recurring",
    label: t("labels.supporterContribution.recurring"),
    mobile: false,
  },
  {
    name: "anonymous",
    label: t("labels.supporterContribution.anonymous"),
    mobile: false,
  },
  {
    name: "source",
    label: t("labels.supporterContribution.source"),
    mobile: false,
  },
];

const syncMutation = useSyncSupporterContributionsFromPatreon({
  mutation: {
    onSuccess: () => {
      displayInfo({
        text: t("messages.admin.supporterContributions.patreonSyncStarted"),
      });
    },
  },
});

const syncFromPatreon = () => {
  syncMutation.mutate();
};
</script>

<template>
  <Heading hero mobile-hidden>
    {{ t("headlines.admin.supporterContributions.index") }}
    <HeadingSmall v-if="supporterContributions">
      {{
        t("headlines.pagination.count", {
          current: supporterContributions?.items.length,
          total: supporterContributions?.meta.pagination?.totalCount,
        })
      }}
    </HeadingSmall>
  </Heading>

  <PageActions>
    <Btn
      :to="{ name: 'admin-funding-goals' }"
      :aria-label="t('headlines.admin.fundingGoals.index')"
    >
      <i class="fa-duotone fa-bullseye-arrow" />
      {{ t("headlines.admin.fundingGoals.index") }}
    </Btn>
    <Btn
      v-if="stats?.patreonSyncEnabled"
      :aria-label="t('actions.admin.supporterContributions.syncFromPatreon')"
      :loading="syncMutation.isPending.value"
      @click="syncFromPatreon"
    >
      <i class="fa-brands fa-patreon" />
      {{ t("actions.admin.supporterContributions.syncFromPatreon") }}
    </Btn>
    <Btn
      :to="{ name: 'admin-supporter-contribution-create' }"
      :aria-label="t('actions.create')"
    >
      <i class="fa fa-plus" />
      {{ t("actions.create") }}
    </Btn>
  </PageActions>

  <FilteredList
    name="admin-supporter-contributions"
    :records="supporterContributions?.items || []"
    :async-status="asyncStatus"
    hide-loading
    hide-empty
    :is-filter-selected="isFilterSelected"
  >
    <template #filter>
      <FilterForm />
    </template>
    <template #header>
      <Stats :params="statsQueryParams" />
      <Panel>
        <PanelHeading>
          {{ t("headlines.admin.supporterContributions.perMonth") }}
        </PanelHeading>
        <PanelBody>
          <MonthlyChart :params="statsQueryParams" />
        </PanelBody>
      </Panel>
    </template>
    <template #default="{ loading, refetching, emptyVisible }">
      <BaseTable
        :records="supporterContributions?.items || []"
        primary-key="id"
        :columns="columns"
        :loading="loading || refetching"
        :empty-visible="emptyVisible"
        default-sort="startedAt desc"
        selectable
        :selected="selected"
        @selected-change="onSelectedChange"
      >
        <template #selected-actions>
          <BtnGroup>
            <Btn
              v-tooltip="
                t('actions.admin.supporterContributions.markAnonymousSelected')
              "
              :aria-label="
                t('actions.admin.supporterContributions.markAnonymousSelected')
              "
              :disabled="bulkPending"
              @click="updateSelected({ anonymous: true })"
            >
              <i class="fa-duotone fa-user-secret" />
            </Btn>
            <Btn
              v-tooltip="
                t('actions.admin.supporterContributions.markPublicSelected')
              "
              :aria-label="
                t('actions.admin.supporterContributions.markPublicSelected')
              "
              :disabled="bulkPending"
              @click="updateSelected({ anonymous: false })"
            >
              <i class="fa-duotone fa-user" />
            </Btn>
            <BtnDropdown>
              <template #label>
                <i
                  v-tooltip="
                    t('actions.admin.supporterContributions.setSourceSelected')
                  "
                  class="fa-duotone fa-hand-holding-heart"
                />
              </template>
              <Btn
                v-for="option in sourceOptions"
                :key="option.value ?? 'unspecified'"
                :disabled="bulkPending"
                @click="updateSelected({ source: option.value })"
              >
                <span>{{ option.label }}</span>
              </Btn>
            </BtnDropdown>
            <Btn
              v-tooltip="
                t('actions.admin.supporterContributions.destroySelected')
              "
              :aria-label="
                t('actions.admin.supporterContributions.destroySelected')
              "
              :tone="BtnTonesEnum.DANGER"
              :disabled="bulkPending"
              :confirm="
                t('messages.confirm.supporterContribution.destroySelected')
              "
              @click="destroySelected"
            >
              <i class="fa-duotone fa-trash" />
            </Btn>
          </BtnGroup>
        </template>
        <template #col-name="{ record }">
          <router-link
            :to="{
              name: 'admin-supporter-contribution-edit',
              params: { id: record.id },
            }"
          >
            <span v-if="record.name">{{ record.name }}</span>
            <em v-else>—</em>
          </router-link>
        </template>
        <template #col-amount="{ record }">
          {{ formatCents(record.amountCents, record.currency) }}
        </template>
        <template #col-user="{ record }">
          <router-link
            v-if="record.user"
            :to="{ name: 'admin-user-edit', params: { id: record.user.id } }"
          >
            {{ record.user.username }}
          </router-link>
          <span v-else>—</span>
        </template>
        <template #col-linkedVia="{ record }">
          <LinkedViaPill :linked-via="record.linkedVia" />
        </template>
        <template #col-startedAt="{ record }">
          {{ l(record.startedAt, "datetime.formats.date") }}
        </template>
        <template #col-endedAt="{ record }">
          <span v-if="record.endedAt">
            {{ l(record.endedAt, "datetime.formats.date") }}
          </span>
          <span v-else>—</span>
        </template>
        <template #col-recurring="{ record }">
          <i
            v-if="record.recurring"
            v-tooltip="t('labels.supporterContribution.recurring')"
            class="fa-duotone fa-arrows-rotate"
          />
          <i
            v-else
            v-tooltip="t('labels.supporterContribution.oneTime')"
            class="fa-duotone fa-calendar-day"
          />
        </template>
        <template #col-anonymous="{ record }">
          <i
            v-if="record.anonymous"
            v-tooltip="t('labels.supporterContribution.anonymous')"
            class="fa-duotone fa-user-secret"
          />
          <i
            v-else
            v-tooltip="t('labels.supporterContribution.public')"
            class="fa-duotone fa-user"
          />
        </template>
        <template #col-source="{ record }">
          <SourcePill :source="record.source" />
        </template>
        <template #actions="{ record }">
          <SupporterContributionActions :supporter-contribution="record" />
        </template>
      </BaseTable>
    </template>
    <template #pagination-top>
      <Paginator
        :query-result-ref="supporterContributions"
        :per-page="perPage"
        :update-per-page="updatePerPage"
      />
    </template>
    <template #pagination-bottom>
      <Paginator
        :query-result-ref="supporterContributions"
        :per-page="perPage"
        :update-per-page="updatePerPage"
      />
    </template>
  </FilteredList>
</template>
