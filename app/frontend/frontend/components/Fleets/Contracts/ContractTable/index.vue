<script lang="ts">
export default {
  name: "FleetContractsTable",
};
</script>

<script lang="ts" setup>
import BaseTable from "@/shared/components/base/Table/index.vue";
import type { BaseTableCol } from "@/shared/components/base/Table/types";
import { BaseTableColAlignmentEnum } from "@/shared/components/base/Table/types";
import ContractStatePill from "@/frontend/components/Fleets/Contracts/ContractStatePill/index.vue";
import ContractDeliveredBar from "@/frontend/components/Fleets/Contracts/ContractDeliveredBar/index.vue";
import Avatar from "@/shared/components/Avatar/index.vue";
import { type AsyncStatus } from "@/shared/components/AsyncData.types";
import { type Fleet, type FleetContract } from "@/services/fyApi";
import { useI18n } from "@/shared/composables/useI18n";
import { useContractCover } from "@/frontend/composables/useContractCover";
import { useContractRoute } from "@/frontend/composables/useContractRoute";
import { useRouter } from "vue-router";

type Props = {
  fleet: Fleet;
  contracts: FleetContract[];
  asyncStatus?: AsyncStatus;
  // Drawn as a row inside the table's own frame, rather than as a panel under
  // an empty header.
  emptyVisible?: boolean;
};

const props = defineProps<Props>();

const { t, toUEC, l } = useI18n();
const { resolve } = useContractCover();
const router = useRouter();

const columns = computed<BaseTableCol<FleetContract>[]>(() => [
  {
    name: "cover",
    label: "",
    width: "68px",
    skeletonMedia: "38px",
  },
  {
    name: "contract",
    label: t("headlines.fleets.contracts.index"),
    flexGrow: 2,
    minWidth: "200px",
    // The column renders more than the title, so the sort is named separately.
    attributeKey: "title",
    sortable: true,
  },
  {
    name: "delivered",
    label: t("labels.fleets.contracts.delivered"),
    flexGrow: 1,
    minWidth: "140px",
  },
  {
    name: "reward",
    label: t("labels.fleets.contracts.reward"),
    width: "130px",
    alignment: BaseTableColAlignmentEnum.RIGHT,
    sortable: true,
  },
  {
    name: "deadline",
    // Wide enough for the date, the clock time and the zone together, like the
    // events and missions tables. `short` dropped the year, which on a deadline
    // is the difference between overdue and a year out.
    label: t("labels.fleets.contracts.deadline"),
    width: "195px",
    mobile: false,
    sortable: true,
  },
  {
    name: "crew",
    label: t("headlines.fleets.contracts.crew"),
    width: "110px",
    mobile: false,
  },
]);

const cover = (contract: FleetContract) => resolve(contract, props.fleet);

const { routeLabel: route } = useContractRoute();

const openContract = (contract: FleetContract) => {
  void router.push({
    name: "fleet-contract",
    params: { slug: props.fleet.slug, contract: contract.slug },
  });
};
</script>

<template>
  <BaseTable
    :records="contracts"
    :columns="columns"
    primary-key="id"
    :async-status="asyncStatus"
    :empty-visible="emptyVisible"
    row-clickable
    data-test="contracts-table"
    @row-click="openContract($event as FleetContract)"
  >
    <!-- The cover survives as a thumbnail, so the kind still reads at a
         glance. -->
    <template #col-cover="{ record }">
      <span class="contract-table__cover">
        <img :src="cover(record as FleetContract)" alt="" />
      </span>
    </template>

    <template #col-contract="{ record }">
      <span class="contract-table__contract">
        <span class="contract-table__title-line">
          <span class="contract-table__title">
            {{ (record as FleetContract).title }}
          </span>
          <ContractStatePill :state="(record as FleetContract).state" />
        </span>
        <span
          v-if="route(record as FleetContract)"
          class="contract-table__route"
        >
          {{ route(record as FleetContract) }}
        </span>
      </span>
    </template>

    <template #col-delivered="{ record }">
      <ContractDeliveredBar
        :progress="(record as FleetContract).progress"
        :state="(record as FleetContract).state"
      />
    </template>

    <template #col-reward="{ record }">
      <!-- eslint-disable-next-line vue/no-v-html -->
      <span
        class="contract-table__reward"
        v-html="toUEC(Number((record as FleetContract).reward))"
      />
    </template>

    <template #col-deadline="{ record }">
      <span class="contract-table__deadline">
        {{
          (record as FleetContract).deadline
            ? l(
                (record as FleetContract).deadline!,
                "datetime.formats.dateTimeZone",
              )
            : "—"
        }}
      </span>
    </template>

    <!-- Who is on it reads faster as faces than as a number. -->
    <template #col-crew="{ record }">
      <span
        v-if="(record as FleetContract).crewPreview.length"
        class="contract-table__crew"
      >
        <Avatar
          v-for="member in (record as FleetContract).crewPreview"
          :key="member.id"
          v-tooltip="member.username"
          :avatar="member.avatar?.smallUrl || undefined"
          size="small"
        />
      </span>
      <span v-else class="contract-table__crew-empty">—</span>
    </template>
  </BaseTable>
</template>

<style lang="scss" scoped>
@import "index";
</style>
