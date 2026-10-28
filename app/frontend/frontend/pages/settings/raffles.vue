<script lang="ts">
export default {
  name: "SettingsRafflesPage",
};
</script>

<script lang="ts" setup>
import BreadCrumbs from "@/shared/components/BreadCrumbs/index.vue";
import { type Crumb } from "@/shared/components/BreadCrumbs/types";
import Heading from "@/shared/components/base/Heading/index.vue";
import FilteredList from "@/shared/components/FilteredList/index.vue";
import BaseTable from "@/shared/components/base/Table/index.vue";
import { type BaseTableCol } from "@/shared/components/base/Table/types";
import Paginator from "@/shared/components/Paginator/index.vue";
import Pill from "@/shared/components/base/Pill/index.vue";
import { PillVariantsEnum } from "@/shared/components/base/Pill/types";
import {
  type MyRaffleEntry,
  RaffleEntryOutcomeEnum,
  useMyRaffleEntries,
} from "@/services/fyApi";
import { usePagination } from "@/shared/composables/usePagination";
import { useI18n } from "@/shared/composables/useI18n";

const { t, l } = useI18n();

const crumbs = computed<Crumb[]>(() => [
  { to: { name: "settings-profile" }, label: t("nav.settings.index") },
]);

const { perPage, page, updatePerPage } = usePagination();

const params = computed(() => ({
  page: page.value,
  perPage: perPage.value,
}));

const { data: entries, ...asyncStatus } = useMyRaffleEntries(params);

const OUTCOME_PILLS: Record<RaffleEntryOutcomeEnum, `${PillVariantsEnum}`> = {
  [RaffleEntryOutcomeEnum.OPEN]: PillVariantsEnum.DEFAULT,
  [RaffleEntryOutcomeEnum.WAITING]: PillVariantsEnum.NEUTRAL,
  [RaffleEntryOutcomeEnum.WON]: PillVariantsEnum.SUCCESS,
  [RaffleEntryOutcomeEnum.CLAIMED]: PillVariantsEnum.SUCCESS,
  [RaffleEntryOutcomeEnum.FORFEITED]: PillVariantsEnum.WARNING,
  [RaffleEntryOutcomeEnum.NOT_WON]: PillVariantsEnum.NEUTRAL,
};

const columns: BaseTableCol<MyRaffleEntry>[] = [
  { name: "raffleTitle", label: t("raffles.mine.raffle") },
  { name: "prize", label: t("raffles.entry.prize"), mobile: false },
  { name: "enteredAt", label: t("raffles.mine.enteredAt"), mobile: false },
  { name: "outcome", label: t("raffles.mine.outcome") },
];
</script>

<template>
  <BreadCrumbs :crumbs="crumbs" />
  <Heading hero>{{ t("headlines.settings.raffles") }}</Heading>

  <FilteredList
    name="settings-raffles"
    :records="entries?.items || []"
    :async-status="asyncStatus"
    hide-loading
  >
    <template #default="{ loading, refetching, emptyVisible }">
      <BaseTable
        :records="entries?.items || []"
        primary-key="id"
        :columns="columns"
        :loading="loading || refetching"
        :empty-visible="emptyVisible"
        data-test="my-raffle-entries"
      >
        <template #col-raffleTitle="{ record }">
          <router-link
            :to="{ name: 'raffle', params: { id: record.raffleId } }"
          >
            {{ record.raffleTitle }}
          </router-link>
        </template>
        <template #col-prize="{ record }">
          {{ record.prize || "—" }}
        </template>
        <template #col-enteredAt="{ record }">
          {{ l(record.enteredAt, "datetime.formats.date") }}
        </template>
        <template #col-outcome="{ record }">
          <Pill :variant="OUTCOME_PILLS[record.outcome]">
            {{ t(`raffles.mine.outcomes.${record.outcome}`) }}
          </Pill>
          <div
            v-if="
              record.outcome === RaffleEntryOutcomeEnum.WON &&
              record.claimDeadlineAt
            "
            class="settings-raffles__deadline"
          >
            {{
              t("raffles.mine.claimBy", {
                date: l(record.claimDeadlineAt, "datetime.formats.short"),
              })
            }}
          </div>
        </template>
      </BaseTable>
    </template>
    <template #pagination-bottom>
      <Paginator
        :query-result-ref="entries"
        :per-page="perPage"
        :update-per-page="updatePerPage"
      />
    </template>
  </FilteredList>
</template>

<style lang="scss" scoped>
.settings-raffles__deadline {
  margin-top: 4px;
  color: var(--color-text-dim, #959595);
  font-size: 0.8125rem;
}
</style>
