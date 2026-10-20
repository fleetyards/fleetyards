<script lang="ts">
export default {
  name: "MissionAvailability",
};
</script>

<script lang="ts" setup>
import CatalogueItemPopover from "@/frontend/components/CatalogueItemPopover/index.vue";
import MissionText from "@/frontend/components/MissionText/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import {
  type GameMission,
  type GameMissionPrerequisite,
  GameMissionPrerequisiteKindEnum,
} from "@/services/fyApi";

type Props = {
  mission: GameMission;
};

const props = defineProps<Props>();

const { t, toNumber } = useI18n();

const perPlayer = computed(() => {
  const count = props.mission.maxInstancesPerPlayer;
  if (!count) return undefined;

  return count === 1
    ? t("labels.gameMission.availability.onePerPlayer")
    : t("labels.gameMission.availability.perPlayer", { count });
});

const respawn = computed(() => {
  const time = props.mission.respawnTime;
  if (!time) return undefined;

  const variation = props.mission.respawnVariation;

  return variation
    ? t("labels.gameMission.availability.respawnVaried", {
        time: toNumber(time),
        variation: toNumber(variation),
      })
    : t("labels.gameMission.availability.respawn", { time: toNumber(time) });
});

// An excluded set the catalogue offers none of, and that is not this mission
// either, has nothing left to name.
const prerequisites = computed(() =>
  (props.mission.prerequisites || []).filter(
    (prerequisite) =>
      prerequisite.kind !== GameMissionPrerequisiteKindEnum.EXCLUDED_MISSIONS ||
      prerequisite.missions.length ||
      prerequisite.includesSelf,
  ),
);

// The files state a band, which can be open at the top: "at least Neutral".
const band = (prerequisite: GameMissionPrerequisite) => {
  const { minStanding: min, maxStanding: max } = prerequisite;

  if (min && max) return min === max ? min : `${min} – ${max}`;
  if (min) {
    return t("labels.gameMission.availability.orHigher", { standing: min });
  }

  return max || "";
};

const reputationLabel = (prerequisite: GameMissionPrerequisite) => {
  const org = prerequisite.orgName || "";
  const standing = band(prerequisite);

  if (!standing) {
    return t("labels.gameMission.availability.reputationAny", { org });
  }

  return t(
    prerequisite.excluded
      ? "labels.gameMission.availability.reputationExcluded"
      : "labels.gameMission.availability.reputation",
    { band: standing, org },
  );
};

// Done once only: the mission is the one thing that rules itself out.
const onceOnly = (prerequisite: GameMissionPrerequisite) =>
  prerequisite.kind === GameMissionPrerequisiteKindEnum.EXCLUDED_MISSIONS &&
  prerequisite.includesSelf &&
  !prerequisite.missions.length;

// One mission to finish first reads as a step; several, or a count above one,
// as a tally towards them.
const completedLabel = (prerequisite: GameMissionPrerequisite) => {
  const count = prerequisite.count ?? 1;

  if (!prerequisite.missions.length && !prerequisite.includesSelf) {
    return t("labels.gameMission.availability.completeUnlisted", { count });
  }

  if (count === 1 && prerequisite.missions.length === 1) {
    return t("labels.gameMission.availability.completeFirst");
  }

  return t("labels.gameMission.availability.completeCount", { count });
};

const hasAny = computed(
  () => !!perPlayer.value || !!respawn.value || !!prerequisites.value.length,
);
</script>

<template>
  <ul v-if="hasAny" class="mission-availability">
    <li v-if="perPlayer" class="mission-availability__item">
      {{ perPlayer }}
    </li>
    <li v-if="respawn" class="mission-availability__item">
      {{ respawn }}
    </li>

    <li
      v-for="(prerequisite, index) in prerequisites"
      :key="index"
      class="mission-availability__item"
      :data-test="`mission-prerequisite-${prerequisite.kind}`"
    >
      <template
        v-if="prerequisite.kind === GameMissionPrerequisiteKindEnum.CRIME_STAT"
      >
        {{
          t("labels.gameMission.availability.crimeStat", {
            min: prerequisite.min ?? 0,
            max: prerequisite.max ?? 0,
          })
        }}
      </template>

      <template
        v-else-if="
          prerequisite.kind === GameMissionPrerequisiteKindEnum.REPUTATION
        "
      >
        {{ reputationLabel(prerequisite) }}
      </template>

      <template v-else-if="onceOnly(prerequisite)">
        {{ t("labels.gameMission.availability.onceOnly") }}
      </template>

      <template v-else>
        <span class="mission-availability__label">
          {{
            prerequisite.kind ===
            GameMissionPrerequisiteKindEnum.EXCLUDED_MISSIONS
              ? t("labels.gameMission.availability.excluded")
              : completedLabel(prerequisite)
          }}
        </span>
        <span
          v-for="linked in prerequisite.missions"
          :key="linked.id"
          class="mission-availability__mission"
        >
          <CatalogueItemPopover
            :item="{
              type: 'GameMission',
              slug: linked.slug,
              name: linked.name,
            }"
          >
            <MissionText :text="linked.name" />
          </CatalogueItemPopover>
        </span>
        <span
          v-if="prerequisite.includesSelf"
          class="mission-availability__mission"
        >
          {{ t("labels.gameMission.availability.thisMission") }}
        </span>
      </template>
    </li>
  </ul>
</template>

<style lang="scss" scoped>
@import "index";
</style>
