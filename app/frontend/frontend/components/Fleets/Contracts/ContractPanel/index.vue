<script lang="ts">
export default {
  name: "FleetContractsPanel",
};
</script>

<script lang="ts" setup>
import Panel from "@/shared/components/base/Panel/index.vue";
import PanelHeading from "@/shared/components/base/Panel/Heading/index.vue";
import PanelBody from "@/shared/components/base/Panel/Body/index.vue";
import { PanelRoundedEnum } from "@/shared/components/base/Panel/types";
import { PanelHeadingShadowEnum } from "@/shared/components/base/Panel/Heading/types";
import { HeadingLevelEnum } from "@/shared/components/base/Heading/types";
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

const cover = computed(() => resolve(props.contract, props.fleet));

// Where the goods come from and go to. A haul has both ends; the other kinds
// only have somewhere to deliver.
const route = computed(() => {
  const to = props.contract.destination?.name;
  const from = props.contract.source?.name;

  if (!to) return undefined;

  return from ? `${from} → ${to}` : to;
});
</script>

<template>
  <Panel
    :bg-image="cover"
    :bg-rounded="PanelRoundedEnum.TOP"
    class="contract-panel"
    data-test="contract-panel"
  >
    <PanelHeading
      :level="HeadingLevelEnum.H2"
      :shadow="PanelHeadingShadowEnum.TOP"
    >
      <router-link
        :to="{
          name: 'fleet-contract',
          params: { slug: fleet.slug, contract: contract.slug },
        }"
      >
        {{ contract.title }}
      </router-link>
    </PanelHeading>

    <!-- A pill in the cover's corner, the treatment the mission and event cards
         share. The state is what a reader scans a board for. -->
    <div class="contract-panel__status">
      <ContractStatePill :state="contract.state" />
    </div>

    <div class="contract-panel__kind">
      {{ t(`labels.fleets.contracts.kind.${contract.kind}`) }}
    </div>

    <template #footer>
      <PanelBody>
        <p v-if="route" class="contract-panel__route">
          <i class="fa-duotone fa-route" />
          {{ route }}
        </p>

        <p v-if="contract.description" class="contract-panel__lede">
          {{ contract.description }}
        </p>

        <!-- The three figures a member decides on: what it pays, how much of it
             there is, and how long they have. -->
        <div class="metrics-card__hero">
          <div class="metrics-card__tile">
            <div class="metrics-card__tile__label">
              {{ t("labels.fleets.contracts.reward") }}
            </div>
            <!-- eslint-disable-next-line vue/no-v-html -->
            <div
              class="metrics-card__tile__value"
              v-html="toUEC(Number(contract.reward))"
            />
          </div>
          <div class="metrics-card__tile">
            <div class="metrics-card__tile__label">
              {{ t("headlines.fleets.contracts.items") }}
            </div>
            <div class="metrics-card__tile__value">
              {{ contract.itemsCount }}
            </div>
          </div>
          <div class="metrics-card__tile">
            <div class="metrics-card__tile__label">
              {{ t("headlines.fleets.contracts.crew") }}
            </div>
            <div class="metrics-card__tile__value">
              {{ contract.crewCount }}
            </div>
          </div>
        </div>

        <p v-if="contract.deadline" class="contract-panel__deadline">
          <i class="fa-duotone fa-clock" />
          {{ t("labels.fleets.contracts.deadline") }}:
          {{ l(contract.deadline) }}
        </p>
      </PanelBody>
    </template>
  </Panel>
</template>

<style lang="scss" scoped>
@import "index";
</style>
