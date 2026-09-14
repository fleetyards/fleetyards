<script lang="ts">
export default {
  name: "FleetContractsPanel",
};
</script>

<script lang="ts" setup>
import Panel from "@/shared/components/base/Panel/index.vue";
import PanelBody from "@/shared/components/base/Panel/Body/index.vue";
import { PanelRoundedEnum } from "@/shared/components/base/Panel/types";
import ContractStatePill from "@/frontend/components/Fleets/Contracts/ContractStatePill/index.vue";
import ContractDeliveredBar from "@/frontend/components/Fleets/Contracts/ContractDeliveredBar/index.vue";
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
  <!-- The cover is the panel's own background rather than an image of ours:
       it is what rounds the photograph to the frame's inner radius, and
       --panel-image-height is the knob it offers for how tall it stands. -->
  <Panel
    :bg-image="cover"
    :bg-rounded="PanelRoundedEnum.TOP"
    class="contract-panel"
    data-test="contract-panel"
  >
    <div class="contract-panel__scrim" />

    <div class="contract-panel__kind">
      {{ t(`labels.fleets.contracts.kind.${contract.kind}`) }}
    </div>

    <div class="contract-panel__status">
      <ContractStatePill :state="contract.state" />
    </div>

    <template #footer>
      <PanelBody>
        <h2 class="contract-panel__title">
          <router-link
            :to="{
              name: 'fleet-contract',
              params: { slug: fleet.slug, contract: contract.slug },
            }"
          >
            {{ contract.title }}
          </router-link>
        </h2>

        <p v-if="route" class="contract-panel__route">
          <i class="fa-duotone fa-route" />
          {{ route }}
        </p>

        <!-- The three figures a member decides on: what it pays, how much of
             it there is, and how long they have. -->
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

        <!-- Read off the ledger, so it only moves when goods actually land. A
             contract asking for nothing yet has no bar to show. -->
        <ContractDeliveredBar
          v-if="contract.itemsCount"
          class="contract-panel__progress"
          :progress="contract.progress"
          :state="contract.state"
          label-above
        />

        <p v-if="contract.deadline" class="contract-panel__deadline">
          <i class="fa-duotone fa-clock" />
          {{ l(contract.deadline, "datetime.formats.short") }}
        </p>
      </PanelBody>
    </template>
  </Panel>
</template>

<style lang="scss" scoped>
@import "index";
</style>
