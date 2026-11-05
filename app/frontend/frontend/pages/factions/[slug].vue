<script lang="ts">
export default {
  name: "FactionPage",
};
</script>

<script lang="ts" setup>
import AsyncData from "@/shared/components/AsyncData.vue";
import Heading from "@/shared/components/base/Heading/index.vue";
import FactionLadder from "@/frontend/components/Factions/Ladder/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import { useMetaInfo } from "@/shared/composables/useMetaInfo";
import { useFaction } from "@/services/fyApi";

const { t, toNumber } = useI18n();
const { updateMetaInfo } = useMetaInfo();
const route = useRoute();

const slug = computed(() => route.params.slug as string);

const { data: faction, ...asyncStatus } = useFaction(slug);

const logo = computed(
  () => faction.value?.logo?.smallUrl || faction.value?.logo?.url,
);

const details = computed(() =>
  (["headquarters", "founded", "leadership", "area", "focus"] as const)
    .map((key) => ({ key, value: faction.value?.[key] }))
    .filter((detail): detail is { key: typeof detail.key; value: string } =>
      Boolean(detail.value),
    ),
);

watch(
  () => faction.value,
  (value) => {
    if (!value) return;

    updateMetaInfo({
      title: value.name,
      description: value.description || undefined,
    });
  },
  { immediate: true },
);
</script>

<template>
  <AsyncData :async-status="asyncStatus">
    <template #resolved>
      <div v-if="faction" class="mission-page faction-page">
        <div class="mission-page__masthead">
          <img
            v-if="logo"
            class="faction-page__logo"
            :src="logo"
            :alt="faction.name"
          />

          <div class="mission-page__title">
            <Heading hero>{{ faction.name }}</Heading>
          </div>

          <div class="mission-page__badges">
            <span v-if="faction.alignment" class="mission-page__badge">
              <span class="mission-page__badge-value">
                {{ t(`labels.gameMission.alignments.${faction.alignment}`) }}
              </span>
            </span>

            <span class="mission-page__badge">
              <span class="mission-page__badge-label">
                {{ t("labels.faction.missions") }}
              </span>
              <span class="mission-page__badge-value">
                <router-link
                  v-if="faction.missionCount"
                  :to="{
                    name: 'missions',
                    query: { orgNameIn: [faction.name], released: 'true' },
                  }"
                >
                  {{ toNumber(faction.missionCount) }}
                </router-link>
                <template v-else>0</template>
              </span>
            </span>
          </div>
        </div>

        <section v-if="faction.description" class="mission-page__panel">
          <p class="mission-page__description">{{ faction.description }}</p>
        </section>

        <section v-if="details.length" class="mission-page__panel">
          <h2 class="mission-page__panel-title">
            {{ t("labels.faction.details") }}
          </h2>

          <dl class="mission-page__axes">
            <div
              v-for="detail in details"
              :key="detail.key"
              class="mission-page__axis"
            >
              <dt class="mission-page__axis-label">
                {{ t(`labels.faction.${detail.key}`) }}
              </dt>
              <dd class="faction-page__detail">{{ detail.value }}</dd>
            </div>
          </dl>
        </section>

        <section v-if="faction.ladders.length" class="faction-page__section">
          <Heading level="h2">{{ t("labels.faction.ladders") }}</Heading>

          <div class="faction-page__ladders">
            <FactionLadder
              v-for="ladder in faction.ladders"
              :key="ladder.key"
              :ladder="ladder"
            />
          </div>
        </section>
      </div>
    </template>
  </AsyncData>
</template>

<style lang="scss" scoped>
@import "@/frontend/pages/missions/index";

.faction-page {
  &__logo {
    flex: none;
    width: 64px;
    height: 64px;
    object-fit: contain;
  }

  &__detail {
    margin: 0;
    font-size: 0.875rem;
    color: var(--color-text, #c8c8c8);
  }

  &__section {
    display: flex;
    flex-direction: column;
    gap: 12px;
  }

  &__ladders {
    display: grid;
    grid-template-columns: repeat(auto-fit, minmax(min(320px, 100%), 1fr));
    align-items: start;
    gap: 16px;
  }
}
</style>
