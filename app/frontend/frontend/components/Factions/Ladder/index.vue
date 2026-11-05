<script lang="ts">
export default {
  name: "FactionLadder",
};
</script>

<script lang="ts" setup>
import { useI18n } from "@/shared/composables/useI18n";
import { type FactionLadder } from "@/services/fyApi";

type Props = {
  ladder: FactionLadder;
};

const props = defineProps<Props>();

const { t, toNumber } = useI18n();

// `toNumber` reads zero as not available, and here zero is a real figure.
const points = (value: number) => (value ? toNumber(value) : "0");

const award = computed(() => {
  const { missionCount, minAward, maxAward } = props.ladder;

  if (!missionCount) return t("labels.faction.noAwards");

  return t("labels.faction.awards", {
    count: missionCount,
    min: `+${toNumber(minAward ?? 0)}`,
    max: `+${toNumber(maxAward ?? 0)}`,
  });
});
</script>

<template>
  <article class="faction-ladder" data-test="faction-ladder">
    <h3 class="faction-ladder__name">{{ ladder.name }}</h3>

    <table class="faction-ladder__ranks">
      <thead>
        <tr>
          <th scope="col">{{ t("labels.faction.rank") }}</th>
          <th scope="col" class="faction-ladder__points">
            {{ t("labels.faction.points") }}
          </th>
        </tr>
      </thead>
      <tbody>
        <tr v-for="rank in ladder.ranks" :key="rank.name">
          <td>{{ rank.name }}</td>
          <td class="faction-ladder__points">
            {{ points(rank.minReputation) }}
          </td>
        </tr>
      </tbody>
    </table>

    <p class="faction-ladder__award">{{ award }}</p>
  </article>
</template>

<style lang="scss" scoped>
.faction-ladder {
  display: flex;
  flex-direction: column;
  gap: 12px;
  padding: 16px;
  background-color: var(--color-control, rgb(39 43 48 / 0.9));
  border: 1px solid var(--color-edge-soft, rgb(122 130 136 / 0.28));
  border-radius: var(--radius-surface-slim, 12px);

  &__name {
    margin: 0;
    font-size: 0.9375rem;
    font-weight: 600;
    color: var(--color-text, #c8c8c8);
  }

  &__ranks {
    width: 100%;
    font-size: 0.8125rem;
    color: var(--color-text, #c8c8c8);
    border-collapse: collapse;

    th {
      padding-bottom: 6px;
      font-family: "Orbitron", tahoma, sans-serif;
      font-size: 0.6875rem;
      font-weight: 400;
      letter-spacing: 0.16em;
      text-align: left;
      text-transform: uppercase;
      color: var(--color-text-dim, #959595);
    }

    td {
      padding: 4px 0;
      border-top: 1px solid var(--color-edge-faint, rgb(122 130 136 / 0.16));
    }

    th.faction-ladder__points,
    td.faction-ladder__points {
      padding-left: 12px;
      text-align: right;
      white-space: nowrap;
      font-variant-numeric: tabular-nums;
    }
  }

  &__award {
    margin: 0;
    font-size: 0.75rem;
    color: var(--color-text-dim, #959595);
  }
}
</style>
