<script lang="ts">
export default {
  name: "MissionPage",
};
</script>

<script lang="ts" setup>
import AsyncData from "@/shared/components/AsyncData.vue";
import Heading from "@/shared/components/base/Heading/index.vue";
import MissionText from "@/frontend/components/MissionText/index.vue";
import MissionRewards from "@/frontend/components/Missions/Rewards/index.vue";
import { missionTextPlain } from "@/frontend/components/MissionText/index";
import { useI18n } from "@/shared/composables/useI18n";
import { useMetaInfo } from "@/shared/composables/useMetaInfo";
import { useGameMission as useMissionQuery } from "@/services/fyApi";

const { t } = useI18n();
const { updateMetaInfo } = useMetaInfo();
const route = useRoute();

const slug = computed(() => route.params.slug as string);

const { data: mission, ...asyncStatus } = useMissionQuery(slug);

// The four axes as the export states them, each a 1-7 its own designers rated.
// Shown apart rather than combined: the game weights them per difficulty
// profile, and those weights are a record the export states separately -- one
// number here would be a formula we invented.
const difficultyAxes = computed(() => {
  const difficulty = mission.value?.difficulty;
  if (!difficulty) return [];

  return [
    { key: "mechanicalSkill", level: difficulty.mechanicalSkill },
    { key: "mentalLoad", level: difficulty.mentalLoad },
    { key: "riskOfLoss", level: difficulty.riskOfLoss },
    { key: "gameKnowledge", level: difficulty.gameKnowledge },
  ].filter(
    (axis): axis is { key: string; level: number } =>
      typeof axis.level === "number",
  );
});

const standing = computed(() => {
  const min = mission.value?.minStanding;
  const max = mission.value?.maxStanding;

  if (!min) return undefined;
  if (!max || max === min) return min;

  return `${min} – ${max}`;
});

watch(
  () => mission.value,
  (value) => {
    if (!value) return;

    // The run-time spans are stripped to a bracketed name here rather than
    // rendered: a meta title is plain text, and `~mission(TargetName)` in a
    // browser tab or a link preview reads as a bug.
    updateMetaInfo({
      title: missionTextPlain(value.name) || t("headlines.missions.index"),
      description: missionTextPlain(value.description),
    });
  },
  { immediate: true },
);
</script>

<template>
  <AsyncData :async-status="asyncStatus">
    <!-- `resolved`, not the default slot: AsyncData renders the error and
         loading slots by name and the success one by name too, so content in
         the default slot is silently never rendered at all. -->
    <template #resolved>
      <div v-if="mission" class="mission-page">
        <div class="mission-page__masthead">
          <div class="mission-page__title">
            <Heading hero>
              <MissionText :text="mission.name" />
            </Heading>

            <div class="mission-page__sub">
              <template v-if="mission.org">
                {{ t("labels.gameMission.offeredBy") }}
                <router-link
                  :to="{
                    name: 'missions',
                    query: { orgNameIn: [mission.org.name] },
                  }"
                >
                  {{ mission.org.name }}
                </router-link>
              </template>
              <!-- 197 of the 2,536 sit on a handler naming no faction inside a
                   generator naming more than one. A wrong org is worse than
                   none when this is the whole question. -->
              <span v-else>{{ t("labels.gameMission.offeredByUnknown") }}</span>
            </div>
          </div>

          <div class="mission-page__badges">
            <span
              v-if="mission.retired"
              class="mission-page__badge mission-page__badge--retired"
            >
              <span class="mission-page__badge-value">
                {{ t("labels.gameMission.retired") }}
              </span>
            </span>

            <span
              v-if="!mission.released"
              class="mission-page__badge mission-page__badge--quiet"
            >
              <span class="mission-page__badge-value">
                {{ t("labels.gameMission.unreleased") }}
              </span>
            </span>

            <span v-if="standing" class="mission-page__badge">
              <span class="mission-page__badge-label">
                {{ t("labels.gameMission.standing") }}
              </span>
              <span class="mission-page__badge-value">{{ standing }}</span>
            </span>

            <span v-if="mission.kind" class="mission-page__badge">
              <span class="mission-page__badge-label">
                {{ t("labels.gameMission.kind") }}
              </span>
              <span class="mission-page__badge-value">
                {{ t(`labels.gameMission.kinds.${mission.kind}`) }}
              </span>
            </span>
          </div>
        </div>

        <!-- The briefing as the game writes it, spans and emphasis intact.
             2,344 of the 2,475 descriptions carry a substitution the game
             fills in when it generates the mission, so this is a template
             rather than the sentence a player will read. -->
        <section v-if="mission.description" class="mission-page__panel">
          <h2 class="mission-page__panel-title">
            {{ t("labels.gameMission.briefing") }}
          </h2>
          <p class="mission-page__description">
            <MissionText :text="mission.description" multiline />
          </p>
          <p class="mission-page__note">
            {{ t("labels.gameMission.templatedNote") }}
          </p>
        </section>

        <section class="mission-page__panel">
          <h2 class="mission-page__panel-title">
            {{ t("labels.gameMission.rewards") }}
          </h2>

          <MissionRewards
            v-if="mission.rewards?.length"
            :rewards="mission.rewards"
          />
          <p v-else class="mission-page__note">
            {{ t("labels.gameMission.noRewards") }}
          </p>

          <!-- Said outright on every page, because it is true of 2,352 of the
               2,536 contracts: the payout is computed by the game at run time
               and the export states no table to reproduce it from. Leaving it
               unsaid would read as our gap rather than as the game's. -->
          <p class="mission-page__note">
            {{ t("labels.gameMission.payoutNote") }}
          </p>
        </section>

        <!-- The payoff of the two tenants sitting in one section: 786 of the
             2,536 contracts hand out a recipe, and this is the only place
             that link can be followed. The reverse -- a blueprint naming the
             missions that drop it -- is text today and stays text until
             `blueprint_sources` points at a mission instead of carrying its
             own copy of the name. -->
        <section v-if="mission.blueprints?.length" class="mission-page__panel">
          <h2 class="mission-page__panel-title">
            {{ t("labels.gameMission.blueprints") }}
          </h2>

          <ul class="mission-page__blueprints">
            <li
              v-for="blueprint in mission.blueprints"
              :key="blueprint.id"
              class="mission-page__blueprint"
            >
              <router-link
                :to="{ name: 'blueprint', params: { slug: blueprint.slug } }"
              >
                {{ blueprint.name }}
              </router-link>
            </li>
          </ul>
        </section>

        <section v-if="difficultyAxes.length" class="mission-page__panel">
          <h2 class="mission-page__panel-title">
            {{ t("labels.gameMission.difficulty") }}
          </h2>

          <dl class="mission-page__axes">
            <div
              v-for="axis in difficultyAxes"
              :key="axis.key"
              class="mission-page__axis"
            >
              <dt class="mission-page__axis-label">
                {{ t(`labels.gameMission.difficultyAxes.${axis.key}`) }}
              </dt>
              <dd class="mission-page__axis-value">{{ axis.level }}/7</dd>
            </div>
          </dl>
        </section>
      </div>
    </template>
  </AsyncData>
</template>

<style lang="scss" scoped>
@import "index";
</style>
