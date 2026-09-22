<script lang="ts">
export default {
  name: "MissionRow",
};
</script>

<script lang="ts" setup>
import MissionText from "@/frontend/components/MissionText/index.vue";
import RowListItem from "@/shared/components/RowListItem/index.vue";
import {
  RowListItemTonesEnum,
  type RowListItemBadge,
  type RowListItemChip,
  type RowListItemTag,
} from "@/shared/components/RowListItem/types";
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

// What it pays, in kinds rather than amounts. The figures are the detail page's
// job, and for 2,352 of the 2,536 contracts there is no figure to show at all:
// the game computes the payout at run time.
const rewards = computed<RowListItemChip[]>(() =>
  (props.mission.rewardKinds || []).map((kind) => ({
    key: kind,
    label: t(`labels.gameMission.rewardKinds.${kind}`),
    to: filterLink("rewardingIn", [kind]),
  })),
);

// Which side of the law offers it.
const ALIGNMENT_TONES: Record<string, RowListItemTonesEnum> = {
  lawful: RowListItemTonesEnum.PRIMARY,
  outlaw: RowListItemTonesEnum.DANGER,
};

const tags = computed<RowListItemTag[]>(() => {
  const alignment = props.mission.org?.alignment;
  if (!alignment) return [];

  return [
    {
      key: alignment,
      label: t(`labels.gameMission.alignments.${alignment}`),
      to: filterLink("alignmentIn", [alignment]),
      tone: ALIGNMENT_TONES[alignment],
    },
  ];
});

const badges = computed<RowListItemBadge[]>(() => {
  const list: RowListItemBadge[] = [];

  // Said on the row, because a reader hunting a mission in game needs to know
  // before they click that this one is not in front of anybody.
  if (!props.mission.released) {
    list.push({
      key: "unreleased",
      value: t("labels.gameMission.unreleased"),
      quiet: true,
    });
  }

  if (difficulty.value) {
    list.push({
      key: "difficulty",
      label: t("labels.gameMission.difficulty"),
      value: `${difficulty.value}/7`,
    });
  }

  return list;
});
</script>

<template>
  <RowListItem
    class="mission-row"
    :to="
      mission.slug
        ? { name: 'mission', params: { slug: mission.slug } }
        : undefined
    "
    :chips="rewards"
    :tags="tags"
    :badges="badges"
  >
    <template #name>
      <MissionText :text="mission.name" />
    </template>

    <template #sub>
      <router-link
        v-if="mission.org?.name"
        :to="filterLink('orgNameIn', [mission.org.name])"
      >
        {{ mission.org.name }}
      </router-link>
      <span v-if="standing">{{ standing }}</span>
    </template>
  </RowListItem>
</template>
