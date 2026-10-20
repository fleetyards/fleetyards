<script lang="ts">
export default {
  name: "MissionHandIns",
};
</script>

<script lang="ts" setup>
import { useI18n } from "@/shared/composables/useI18n";
import {
  type GameMissionHandIn,
  GameMissionHandInKindEnum,
} from "@/services/fyApi";

type Props = {
  handIns?: GameMissionHandIn[];
};

const props = defineProps<Props>();

const { t, toNumber } = useI18n();

const required = computed(() =>
  (props.handIns || []).filter((handIn) => handIn.option == null),
);

// Entries sharing an option are one alternative; any one option satisfies the
// contract.
const options = computed(() => {
  const grouped = new Map<number, GameMissionHandIn[]>();

  (props.handIns || []).forEach((handIn) => {
    if (handIn.option == null) return;

    grouped.set(handIn.option, [...(grouped.get(handIn.option) || []), handIn]);
  });

  return [...grouped.values()];
});

const amount = (handIn: GameMissionHandIn) => {
  if (handIn.kind === GameMissionHandInKindEnum.RESOURCE) {
    const top = toNumber(handIn.max || handIn.amount, "cargo");

    return handIn.max ? `${toNumber(handIn.amount)} – ${top}` : top;
  }

  const range = handIn.max
    ? `${toNumber(handIn.amount)} – ${toNumber(handIn.max)}`
    : toNumber(handIn.amount);

  return `${range}×`;
};
</script>

<template>
  <div v-if="handIns?.length" class="mission-rewards">
    <div v-if="required.length" class="mission-rewards__group">
      <ul class="mission-rewards__list">
        <li
          v-for="(handIn, index) in required"
          :key="`${handIn.ref}-${index}`"
          class="mission-rewards__item"
        >
          <span class="mission-rewards__value">
            {{ amount(handIn) }} {{ handIn.name }}
          </span>
          <span
            v-if="!handIn.name"
            class="mission-rewards__note mission-rewards__note--ref"
            >{{ handIn.ref }}</span
          >
        </li>
      </ul>
    </div>

    <div v-if="options.length" class="mission-rewards__group">
      <span class="mission-rewards__label">
        {{ t("labels.gameMission.handInsChoice") }}
      </span>

      <ul class="mission-rewards__list">
        <li
          v-for="(option, index) in options"
          :key="index"
          class="mission-rewards__item"
        >
          <template
            v-for="(handIn, position) in option"
            :key="`${handIn.ref}-${position}`"
          >
            <span v-if="position" class="mission-rewards__note">+</span>
            <span class="mission-rewards__value">
              {{ amount(handIn) }} {{ handIn.name }}
            </span>
            <span
              v-if="!handIn.name"
              class="mission-rewards__note mission-rewards__note--ref"
              >{{ handIn.ref }}</span
            >
          </template>
        </li>
      </ul>
    </div>
  </div>
</template>

<style lang="scss" scoped>
@import "../Rewards/index";
</style>
