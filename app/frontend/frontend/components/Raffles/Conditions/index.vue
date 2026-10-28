<script lang="ts">
export default {
  name: "RaffleConditions",
};
</script>

<script lang="ts" setup>
import Panel from "@/shared/components/base/Panel/index.vue";
import PanelHeading from "@/shared/components/base/Panel/Heading/index.vue";
import PanelBody from "@/shared/components/base/Panel/Body/index.vue";
import { PanelVariantsEnum } from "@/shared/components/base/Panel/types";
import { PanelHeadingTonesEnum } from "@/shared/components/base/Panel/Heading/types";
import { type Raffle } from "@/services/fyApi";
import { useI18n } from "@/shared/composables/useI18n";

type Props = {
  raffle: Raffle;
};

const props = defineProps<Props>();

const { t } = useI18n();

const CONDITIONS = [
  "confirmedAccount",
  "publicEntrants",
  "publicWinner",
  "drawOrder",
  "claimMail",
  "claimDeadline",
  "prizeMail",
  "deletedAccount",
  "noCash",
  "noLiability",
  "noRecourse",
  "notAffiliated",
] as const;
</script>

<template>
  <Panel
    :variant="PanelVariantsEnum.SLIM"
    class="raffle-conditions"
    data-test="raffle-conditions"
  >
    <PanelHeading :tone="PanelHeadingTonesEnum.METRIC" compact divider>
      {{ t("raffles.conditions.title") }}
    </PanelHeading>
    <PanelBody>
      <ol class="raffle-conditions__list">
        <li v-for="condition in CONDITIONS" :key="condition">
          {{
            t(`raffles.conditions.${condition}`, {
              days: props.raffle.claimPeriodDays,
            })
          }}
        </li>
      </ol>
    </PanelBody>
    <footer class="raffle-conditions__footnote">
      <p class="raffle-conditions__version">
        {{
          t("raffles.conditions.version", {
            version: props.raffle.conditionsVersion,
          })
        }}
      </p>
    </footer>
  </Panel>
</template>

<style lang="scss" scoped>
.raffle-conditions__list {
  margin: 0;
  padding-left: 1.25rem;
  font-size: 0.875rem;

  li + li {
    margin-top: 6px;
  }
}

.raffle-conditions__footnote {
  padding: 10px 18px 14px;
  border-top: 1px solid var(--color-edge-faint, rgba(122, 130, 136, 0.16));
}

.raffle-conditions__version {
  margin: 0;
  font-size: 0.85rem;
  color: var(--color-text-dim, #959595);
}
</style>
