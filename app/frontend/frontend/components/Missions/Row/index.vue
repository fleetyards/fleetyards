<script lang="ts">
export default {
  name: "MissionRow",
};
</script>

<script lang="ts" setup>
import MissionText from "@/frontend/components/MissionText/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import { type GameMission } from "@/services/fyApi";

type Props = {
  mission: GameMission;
};

const props = defineProps<Props>();

const { t } = useI18n();

const route = useRoute();

// Every value the catalogue can be narrowed by is a link that narrows it, the
// way a blueprint row's materials and alignments are. `page` is dropped: the
// row that was clicked is almost never on the same page of a smaller set.
const filterLink = (key: string, value: string | string[]) => ({
  name: route.name as string,
  query: { ...route.query, page: undefined, [key]: value },
});

// The band, as one phrase. Both ends are set on 2,155 of the 2,536 and they
// are frequently the same rank, which reads as "Neutral" rather than
// "Neutral to Neutral".
const standing = computed(() => {
  const { minStanding, maxStanding } = props.mission;

  if (!minStanding) return undefined;
  if (!maxStanding || maxStanding === minStanding) return minStanding;

  return `${minStanding} – ${maxStanding}`;
});

// The four axes as one figure, which the row has space for and the detail page
// breaks back apart. A plain mean rather than the game's own weighting: the
// weights belong to a profile record the export states separately, and picking
// one here would be inventing a number the game does not publish.
const difficulty = computed(() => {
  const levels = [
    props.mission.difficulty?.mechanicalSkill,
    props.mission.difficulty?.mentalLoad,
    props.mission.difficulty?.riskOfLoss,
    props.mission.difficulty?.gameKnowledge,
  ].filter((level): level is number => typeof level === "number");

  if (!levels.length) return undefined;

  return Math.round(
    levels.reduce((sum, level) => sum + level, 0) / levels.length,
  );
});

const rewardKinds = computed(() => props.mission.rewardKinds || []);
</script>

<template>
  <div class="mission-row">
    <span class="mission-row__main">
      <router-link
        v-if="mission.slug"
        class="mission-row__name"
        :to="{ name: 'mission', params: { slug: mission.slug } }"
      >
        <MissionText :text="mission.name" />
      </router-link>
      <span v-else class="mission-row__name">
        <MissionText :text="mission.name" />
      </span>

      <span class="mission-row__sub">
        <router-link
          v-if="mission.org?.name"
          :to="filterLink('orgNameIn', [mission.org.name])"
        >
          {{ mission.org.name }}
        </router-link>
        <span v-if="standing">{{ standing }}</span>
      </span>
    </span>

    <!-- What it pays, in kinds rather than amounts. The figures are the detail
         page's job, and for 2,352 of the 2,536 contracts there is no figure to
         show at all: the game computes the payout at run time. -->
    <span v-if="rewardKinds.length" class="mission-row__rewards">
      <router-link
        v-for="kind in rewardKinds"
        :key="kind"
        class="mission-row__reward"
        :to="filterLink('rewardingIn', [kind])"
      >
        {{ t(`labels.gameMission.rewardKinds.${kind}`) }}
      </router-link>
    </span>

    <!-- Which side of the law offers it. Coloured words rather than filled
         pills, and a link, like every other value the catalogue narrows by. -->
    <span v-if="mission.org?.alignment" class="mission-row__alignments">
      <router-link
        class="mission-row__alignment"
        :class="`mission-row__alignment--${mission.org.alignment}`"
        :to="filterLink('alignmentIn', [mission.org.alignment])"
      >
        {{ t(`labels.gameMission.alignments.${mission.org.alignment}`) }}
      </router-link>
    </span>

    <span class="mission-row__badges">
      <!-- Said on the row, because a reader hunting a mission in game needs to
           know before they click that this one is not in front of anybody. -->
      <span
        v-if="!mission.released"
        class="mission-row__badge mission-row__badge--quiet"
      >
        <span class="mission-row__badge-value">
          {{ t("labels.gameMission.unreleased") }}
        </span>
      </span>

      <span v-if="difficulty" class="mission-row__badge">
        <span class="mission-row__badge-label">
          {{ t("labels.gameMission.difficulty") }}
        </span>
        <span class="mission-row__badge-value">{{ difficulty }}/7</span>
      </span>
    </span>
  </div>
</template>

<style lang="scss" scoped>
@import "index";
</style>
