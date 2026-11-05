<script lang="ts">
export default {
  name: "FactionLadder",
};
</script>

<script lang="ts" setup>
import Panel from "@/shared/components/base/Panel/index.vue";
import PanelBody from "@/shared/components/base/Panel/Body/index.vue";
import PanelHeading from "@/shared/components/base/Panel/Heading/index.vue";
import { PanelHeadingTonesEnum } from "@/shared/components/base/Panel/Heading/types";
import { useI18n } from "@/shared/composables/useI18n";
import { type FactionLadder } from "@/services/fyApi";

type Props = {
  ladder: FactionLadder;
};

const props = defineProps<Props>();

const { t, toNumber } = useI18n();

// `toNumber` reads zero as not available, and here zero is a real figure.
const points = (value: number) => (value ? toNumber(value) : "0");

const signed = (value?: number | null) => `+${toNumber(value ?? 0)}`;

const award = computed(() => {
  const { minAward, maxAward } = props.ladder;

  if (minAward === maxAward) return signed(minAward);

  return t("labels.faction.awardRange", {
    min: signed(minAward),
    max: signed(maxAward),
  });
});

const topPoints = computed(() =>
  Math.max(...props.ladder.ranks.map((rank) => rank.minReputation), 0),
);

// The rank's total against the top rank's, unscaled, so a bar states the real
// climb. A rank at or below zero takes no points to reach and has no bar.
const barStyle = (minReputation: number) => {
  if (minReputation <= 0 || !topPoints.value) return { width: "0" };

  // The floor keeps the lowest ranks visible beside a top rank thousands of
  // times their size.
  return {
    width: `${(minReputation / topPoints.value) * 100}%`,
    minWidth: "2px",
  };
};
</script>

<template>
  <Panel :outer-spacing="false" data-test="faction-ladder">
    <PanelHeading :tone="PanelHeadingTonesEnum.METRIC">
      {{ ladder.name }}
    </PanelHeading>

    <PanelBody>
      <div class="faction-ladder">
        <dl v-if="ladder.missionCount" class="faction-ladder__stats">
          <div class="faction-ladder__stat">
            <dt>{{ t("labels.faction.missions") }}</dt>
            <dd>{{ toNumber(ladder.missionCount) }}</dd>
          </div>
          <div class="faction-ladder__stat">
            <dt>{{ t("labels.faction.perMission") }}</dt>
            <dd data-test="faction-ladder-award">{{ award }}</dd>
          </div>
        </dl>
        <p v-else class="faction-ladder__note">
          {{ t("labels.faction.noAwards") }}
        </p>

        <ol class="faction-ladder__ranks">
          <li
            v-for="rank in ladder.ranks"
            :key="rank.name"
            class="faction-ladder__rank"
          >
            <div class="faction-ladder__rank-line">
              <span class="faction-ladder__rank-name">{{ rank.name }}</span>
              <span class="faction-ladder__rank-points">
                {{ points(rank.minReputation) }}
              </span>
            </div>
            <div class="faction-ladder__track" aria-hidden="true">
              <div
                class="faction-ladder__bar"
                :style="barStyle(rank.minReputation)"
              />
            </div>
          </li>
        </ol>
      </div>
    </PanelBody>
  </Panel>
</template>

<style lang="scss" scoped>
.faction-ladder {
  display: flex;
  flex-direction: column;
  gap: 14px;

  &__stats {
    display: grid;
    grid-template-columns: repeat(2, minmax(0, 1fr));
    gap: 8px;
    margin: 0;
  }

  &__stat {
    padding: 8px 10px;
    background-color: var(--color-gray-black);
    border-radius: var(--radius-control);

    dt {
      font-family: "Orbitron", tahoma, sans-serif;
      font-size: 10px;
      font-weight: 400;
      line-height: 1.3;
      letter-spacing: 0.16em;
      text-transform: uppercase;
      color: var(--color-text-dim);
    }

    dd {
      margin: 2px 0 0;
      font-size: 13.5px;
      font-weight: 600;
      color: var(--color-lifted);
    }
  }

  &__note {
    margin: 0;
    font-size: 0.75rem;
    color: var(--color-text-dim);
  }

  &__ranks {
    display: flex;
    flex-direction: column;
    gap: 9px;
    margin: 0;
    padding: 0;
    list-style: none;
  }

  &__rank {
    display: flex;
    flex-direction: column;
    gap: 4px;
  }

  &__rank-line {
    display: flex;
    align-items: baseline;
    justify-content: space-between;
    gap: 12px;
    font-size: 13px;
  }

  &__rank-name {
    color: var(--color-lifted);
  }

  &__rank-points {
    color: var(--color-text-dim);
    white-space: nowrap;
    font-variant-numeric: tabular-nums;
  }

  &__track {
    height: 4px;
    overflow: hidden;
    background-color: var(--color-gray-black);
    border-radius: 2px;
  }

  &__bar {
    height: 100%;
    background-color: var(--color-endcap);
    border-radius: 2px;
  }
}
</style>
