<script lang="ts">
export default {
  name: "FleetContractsRow",
};
</script>

<script lang="ts" setup>
import ContractStatePill from "@/frontend/components/Fleets/Contracts/ContractStatePill/index.vue";
import { type Fleet, type FleetContract } from "@/services/fyApi";
import { useI18n } from "@/shared/composables/useI18n";
import { useContractCover } from "@/frontend/composables/useContractCover";

type Props = {
  fleet: Fleet;
  contract: FleetContract;
};

const props = defineProps<Props>();

const { t, toUEC, l } = useI18n();
const { resolve } = useContractCover();

const cover = computed(() => resolve(props.contract));

const route = computed(() => {
  const to = props.contract.destination?.name;
  const from = props.contract.source?.name;

  if (!to) return undefined;

  return from ? `${from} → ${to}` : to;
});
</script>

<template>
  <div class="contract-row" data-test="contract-row">
    <!-- The cover survives as a thumbnail, so the kind still reads at a glance. -->
    <div class="contract-row__cover">
      <img :src="cover" alt="" />
    </div>

    <div class="contract-row__main">
      <div class="contract-row__title-line">
        <router-link
          class="contract-row__title"
          :to="{
            name: 'fleet-contract',
            params: { slug: fleet.slug, contract: contract.slug },
          }"
        >
          {{ contract.title }}
        </router-link>
        <ContractStatePill :state="contract.state" />
      </div>
      <div v-if="route" class="contract-row__route">{{ route }}</div>
    </div>

    <div class="contract-row__figure contract-row__figure--goods">
      <span class="contract-row__label">{{
        t("headlines.fleets.contracts.items")
      }}</span>
      <span>{{ contract.itemsCount }}</span>
    </div>

    <div class="contract-row__figure">
      <span class="contract-row__label">{{
        t("labels.fleets.contracts.reward")
      }}</span>
      <!-- eslint-disable-next-line vue/no-v-html -->
      <span v-html="toUEC(Number(contract.reward))" />
    </div>

    <div class="contract-row__figure">
      <span class="contract-row__label">{{
        t("labels.fleets.contracts.deadline")
      }}</span>
      <span>{{ contract.deadline ? l(contract.deadline) : "—" }}</span>
    </div>

    <div class="contract-row__figure">
      <span class="contract-row__label">{{
        t("headlines.fleets.contracts.crew")
      }}</span>
      <span>{{ contract.crewCount }}</span>
    </div>
  </div>
</template>

<style lang="scss" scoped>
@import "index";
</style>
