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
import { type GameMission, type ModelExtended } from "@/services/fyApi";

type Props = {
  mission: GameMission;
  // The pilot's ship, when one is chosen: its contracts are marked, not hidden.
  ship?: Pick<ModelExtended, "name" | "canLandOnPlanets">;
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
  const list: RowListItemTag[] = [];
  const alignment = props.mission.org?.alignment;

  if (alignment) {
    list.push({
      key: alignment,
      label: t(`labels.gameMission.alignments.${alignment}`),
      to: filterLink("alignmentIn", [alignment]),
      tone: ALIGNMENT_TONES[alignment],
    });
  }

  // Where it takes place, for everyone. Unknown says nothing worth a tag.
  const location = props.mission.locationKind;
  if (location && location !== "unknown") {
    list.push({
      key: `location-${location}`,
      label: t(`labels.gameMission.locationKinds.${location}`),
      to: filterLink("locationKindIn", [location]),
    });
  }

  return list;
});

// The same label as the tag, for phones: `RowListItem` hides every tag below
// 992px, and where a contract takes place is not optional on a phone.
const locationLabel = computed(() => {
  const location = props.mission.locationKind;
  if (!location || location === "unknown") return undefined;

  return t(`labels.gameMission.locationKinds.${location}`);
});

// Only for a ship that can't land, and only where the work puts a pilot on
// the ground: ship combat at a surface target is fought in flight. A contract
// that may roll a space location gets the softer wording.
const cannotLand = computed(() => {
  const { ship, mission } = props;
  if (ship?.canLandOnPlanets !== false || !mission.needsLanding)
    return undefined;

  const wording = mission.locationKind === "mixed" ? "mixed" : "surface";

  return {
    firm: wording === "surface",
    text: t(`labels.gameMission.cannotLand.${wording}`, { ship: ship.name }),
  };
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
    :class="{ 'mission-row--cannot-land': cannotLand?.firm }"
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
      <span v-if="locationLabel" class="mission-row__location">
        {{ locationLabel }}
      </span>
      <span
        v-if="cannotLand"
        role="note"
        class="mission-row__cannot-land"
        :class="{ 'mission-row__cannot-land--firm': cannotLand.firm }"
      >
        <i class="fa-light fa-ban" aria-hidden="true" />
        {{ cannotLand.text }}
      </span>
    </template>
  </RowListItem>
</template>

<style lang="scss" scoped>
// Dimmed, not hidden, and dimmed by colour rather than opacity: the quiet text
// colour keeps the name readable, where opacity took it below AA contrast. The
// reason keeps its own colour, since it is the one thing on the row to read.
.mission-row--cannot-land :deep(.row-list-item__name),
.mission-row--cannot-land
  :deep(.row-list-item__sub > :not(.mission-row__cannot-land)) {
  color: var(--color-text-dim, #959595);
}

.mission-row__location {
  @media (min-width: $desktop-breakpoint) {
    display: none;
  }
}

.mission-row__cannot-land {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  color: var(--color-text-dim, #959595);
  font-size: 0.85em;
}

.mission-row__cannot-land--firm {
  color: #e0a15c;
}
</style>
