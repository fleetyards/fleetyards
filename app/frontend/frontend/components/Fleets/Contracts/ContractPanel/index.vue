<script lang="ts">
export default {
  name: "FleetContractsPanel",
};
</script>

<script lang="ts" setup>
import Panel from "@/shared/components/base/Panel/index.vue";
import PanelHeading from "@/shared/components/base/Panel/Heading/index.vue";
import PanelBody from "@/shared/components/base/Panel/Body/index.vue";
import { HeadingLevelEnum } from "@/shared/components/base/Heading/types";
import ContractStatePill from "@/frontend/components/Fleets/Contracts/ContractStatePill/index.vue";
import { type Fleet, type FleetContract } from "@/services/fyApi";
import { useI18n } from "@/shared/composables/useI18n";

type Props = {
  fleet: Fleet;
  contract: FleetContract;
};

const props = defineProps<Props>();

const { t, toUEC, l } = useI18n();
</script>

<template>
  <Panel class="contract-panel" data-test="contract-panel">
    <PanelHeading :level="HeadingLevelEnum.H2">
      <router-link
        :to="{
          name: 'fleet-contract',
          params: { slug: props.fleet.slug, contract: props.contract.slug },
        }"
      >
        {{ props.contract.title }}
      </router-link>
    </PanelHeading>

    <PanelBody>
      <div class="contract-panel__meta">
        <ContractStatePill :state="props.contract.state" />
        <span class="contract-panel__kind">
          {{ t(`labels.fleets.contracts.kind.${props.contract.kind}`) }}
        </span>
      </div>

      <p v-if="props.contract.description" class="contract-panel__description">
        {{ props.contract.description }}
      </p>

      <dl class="contract-panel__facts">
        <div v-if="props.contract.source">
          <dt>{{ t("labels.fleets.contracts.from") }}</dt>
          <dd>{{ props.contract.source.name }}</dd>
        </div>
        <div v-if="props.contract.destination">
          <dt>{{ t("labels.fleets.contracts.to") }}</dt>
          <dd>{{ props.contract.destination.name }}</dd>
        </div>
        <div>
          <dt>{{ t("labels.fleets.contracts.reward") }}</dt>
          <!-- eslint-disable-next-line vue/no-v-html -->
          <dd v-html="toUEC(Number(props.contract.reward))" />
        </div>
        <div v-if="props.contract.deadline">
          <dt>{{ t("labels.fleets.contracts.deadline") }}</dt>
          <dd>{{ l(props.contract.deadline) }}</dd>
        </div>
      </dl>
    </PanelBody>
  </Panel>
</template>

<style lang="scss" scoped>
@import "index";
</style>
