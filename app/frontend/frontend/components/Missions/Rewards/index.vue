<script lang="ts">
export default {
  name: "MissionRewards",
};
</script>

<script lang="ts" setup>
import { useI18n } from "@/shared/composables/useI18n";
import {
  type GameMissionReward,
  GameMissionRewardKindEnum,
} from "@/services/fyApi";

type Props = {
  rewards?: GameMissionReward[];
};

const props = defineProps<Props>();

const { t, toNumber } = useI18n();

// Grouped by kind, in the order the enum declares them, so a mission that pays
// standing with three orgs reads as one block rather than three scattered
// lines. Within a kind the export's own order is kept: a contract declares one
// result per outcome, and that order is the game's.
const groups = computed(() =>
  Object.values(GameMissionRewardKindEnum)
    .map((kind) => ({
      kind,
      rewards: (props.rewards || []).filter((reward) => reward.kind === kind),
    }))
    .filter((group) => group.rewards.length),
);

// A standing loss is stated the same way a gain is -- 16 of the 58 amounts the
// export declares are negative -- so the sign carries the meaning and is never
// dropped.
const reputationAmount = (reward: GameMissionReward) =>
  `${(reward.amount ?? 0) > 0 ? "+" : ""}${toNumber(reward.amount ?? 0)}`;

// `toNumber` with the currency spelled out rather than `toUEC`: seven of the
// eight stated payouts are in aUEC and the eighth is in mercenary scrip, and
// `toUEC` hardcodes the unit and returns markup that would need `v-html`.
const currencyAmount = (reward: GameMissionReward) => {
  const amount = toNumber(reward.amount ?? 0);

  if (!reward.max) return `${amount} ${reward.currency}`;

  return `${amount} – ${toNumber(reward.max)} ${reward.currency}`;
};
</script>

<template>
  <div v-if="groups.length" class="mission-rewards">
    <div
      v-for="group in groups"
      :key="group.kind"
      class="mission-rewards__group"
    >
      <span class="mission-rewards__label">
        {{ t(`labels.gameMission.rewardKinds.${group.kind}`) }}
      </span>

      <ul class="mission-rewards__list">
        <li
          v-for="(reward, index) in group.rewards"
          :key="index"
          class="mission-rewards__item"
        >
          <template v-if="reward.kind === 'reputation'">
            <span class="mission-rewards__value">{{
              reputationAmount(reward)
            }}</span>
            <span v-if="reward.orgName" class="mission-rewards__note">{{
              reward.orgName
            }}</span>
          </template>

          <template v-else-if="reward.kind === 'currency'">
            <span class="mission-rewards__value">{{
              currencyAmount(reward)
            }}</span>
          </template>

          <!-- The name the parser resolved out of the export's entity tree.
               405 of the 410 awards have one; the five that do not are the only
               place a ref is shown, because an award with neither would be a
               blank line. The weight says it is one of several sets. -->
          <template v-else-if="reward.kind === 'item'">
            <span class="mission-rewards__value">
              {{ reward.amount ?? 1 }}&times; {{ reward.entityName }}
            </span>
            <span
              v-if="!reward.entityName"
              class="mission-rewards__note mission-rewards__note--ref"
              >{{ reward.entityClass }}</span
            >
            <span v-if="reward.weight" class="mission-rewards__note">{{
              t("labels.gameMission.oneOfASet")
            }}</span>
          </template>

          <template v-else>
            <span class="mission-rewards__value">{{ reward.badge }}</span>
          </template>
        </li>
      </ul>
    </div>
  </div>
</template>

<style lang="scss" scoped>
@import "index";
</style>
