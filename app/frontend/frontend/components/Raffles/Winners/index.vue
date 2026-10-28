<script lang="ts">
export default {
  name: "RaffleWinners",
};
</script>

<script lang="ts" setup>
import Panel from "@/shared/components/base/Panel/index.vue";
import PanelHeading from "@/shared/components/base/Panel/Heading/index.vue";
import PanelBody from "@/shared/components/base/Panel/Body/index.vue";
import { PanelVariantsEnum } from "@/shared/components/base/Panel/types";
import { PanelHeadingTonesEnum } from "@/shared/components/base/Panel/Heading/types";
import Pill from "@/shared/components/base/Pill/index.vue";
import { PillVariantsEnum } from "@/shared/components/base/Pill/types";
import { type Raffle } from "@/services/fyApi";
import { useI18n } from "@/shared/composables/useI18n";

type Props = {
  raffle: Raffle;
};

const props = defineProps<Props>();

const { t, l } = useI18n();
</script>

<template>
  <Panel
    v-if="props.raffle.currentWinner || props.raffle.forfeitedWinners.length"
    :variant="PanelVariantsEnum.SLIM"
    data-test="raffle-winners"
  >
    <PanelHeading :tone="PanelHeadingTonesEnum.METRIC" compact divider>
      {{ t("raffles.winner.title") }}
    </PanelHeading>
    <PanelBody>
      <ul class="raffle-winners">
        <li
          v-if="props.raffle.currentWinner"
          class="raffle-winners__row"
          data-test="raffle-winner"
        >
          <span>{{ props.raffle.currentWinner.username }}</span>
          <Pill
            v-if="props.raffle.currentWinner.claimedAt"
            :variant="PillVariantsEnum.SUCCESS"
          >
            {{ t("raffles.winner.claimedPill") }}
          </Pill>
          <span v-else class="raffle-winners__dim">
            {{
              t("raffles.winner.until", {
                date: l(
                  props.raffle.currentWinner.claimDeadlineAt,
                  "datetime.formats.short",
                ),
              })
            }}
          </span>
        </li>
        <li
          v-for="winner in props.raffle.forfeitedWinners"
          :key="winner.drawPosition"
          class="raffle-winners__row"
        >
          <span class="raffle-winners__forfeited">{{ winner.username }}</span>
          <span class="raffle-winners__dim">
            {{ t("raffles.winner.forfeited") }}
          </span>
        </li>
      </ul>
      <p v-if="props.raffle.drawnAt" class="raffle-winners__dim">
        {{
          t("raffles.winner.drawnOn", {
            date: l(props.raffle.drawnAt, "datetime.formats.short"),
            count: props.raffle.entriesCount,
          })
        }}
      </p>
    </PanelBody>
  </Panel>
</template>

<style lang="scss" scoped>
.raffle-winners {
  display: flex;
  flex-direction: column;
  gap: 8px;
  margin: 0;
  padding: 0;
  list-style: none;
}

.raffle-winners__row {
  display: flex;
  justify-content: space-between;
  gap: 8px;
}

.raffle-winners__dim {
  color: var(--color-text-dim, #959595);
  font-size: 0.875rem;
}

.raffle-winners__forfeited {
  color: var(--color-text-dim, #959595);
  text-decoration: line-through;
}
</style>
