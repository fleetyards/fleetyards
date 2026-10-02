<script lang="ts">
export default {
  name: "LocationMissions",
};
</script>

<script lang="ts" setup>
import MetricsCard from "@/frontend/components/Models/MetricsCard/index.vue";
import MissionText from "@/frontend/components/MissionText/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import { type GameMission } from "@/services/fyApi";

type Props = {
  missions: GameMission[];
  total: number;
  locationId: string;
};

const props = defineProps<Props>();

const { t } = useI18n();

const open = ref<Record<string, boolean>>({});

// Grouped by who offers the work: Levski alone has 126, and flat that is the
// whole rail.
const groups = computed(() => {
  const byOrg = new Map<string, GameMission[]>();

  props.missions.forEach((mission) => {
    const key = mission.org?.name || "";
    byOrg.set(key, [...(byOrg.get(key) || []), mission]);
  });

  return [...byOrg.entries()]
    .map(([key, entries]) => ({
      key,
      name: key || t("labels.gameMission.offeredByUnknown"),
      entries,
      count: entries.length,
      alignment: entries[0]?.org?.alignment ?? undefined,
    }))
    .sort((a, b) => b.count - a.count);
});

const isOpen = (key: string) => open.value[key] ?? false;

const toggle = (key: string) => {
  open.value = { ...open.value, [key]: !isOpen(key) };
};

watch(
  groups,
  (value) => {
    if (!value.length) return;
    if (value.some((group) => open.value[group.key])) return;

    open.value = { [value[0].key]: true };
  },
  { immediate: true },
);

const standing = (mission: GameMission) => {
  if (!mission.minStanding) return undefined;
  if (!mission.maxStanding || mission.maxStanding === mission.minStanding) {
    return mission.minStanding;
  }

  return `${mission.minStanding} → ${mission.maxStanding}`;
};
</script>

<template>
  <MetricsCard
    class="location-missions"
    :title="t('labels.location.missions')"
    variant="slim"
  >
    <template #head>
      <span class="location-missions__summary">{{ total }}</span>
    </template>

    <div class="location-missions__groups">
      <div
        v-for="group in groups"
        :key="group.key"
        class="location-missions__group"
      >
        <button
          type="button"
          class="location-missions__group-head"
          :aria-expanded="isOpen(group.key)"
          @click="toggle(group.key)"
        >
          <i
            class="fa-duotone fa-chevron-right location-missions__chevron"
            :class="{ 'location-missions__chevron--open': isOpen(group.key) }"
          />
          <span class="location-missions__org">{{ group.name }}</span>
          <span
            v-if="group.alignment"
            class="location-missions__alignment"
            :class="`location-missions__alignment--${group.alignment}`"
          >
            {{ t(`labels.gameMission.alignments.${group.alignment}`) }}
          </span>
          <span class="location-missions__count">{{ group.count }}</span>
        </button>

        <div v-if="isOpen(group.key)" class="location-missions__missions">
          <router-link
            v-for="mission in group.entries"
            :key="mission.id"
            :to="{ name: 'mission', params: { slug: mission.slug } }"
            class="location-missions__mission"
          >
            <div class="location-missions__mission-name">
              <MissionText :text="mission.name" />
            </div>
            <div
              v-if="standing(mission)"
              class="location-missions__mission-meta"
            >
              <span>{{ standing(mission) }}</span>
            </div>
          </router-link>
        </div>
      </div>
    </div>

    <router-link
      v-if="total > missions.length"
      class="location-missions__all"
      :to="{ name: 'missions', query: { atLocation: locationId } }"
    >
      {{ t("labels.location.allMissions") }}
    </router-link>
  </MetricsCard>
</template>

<style lang="scss" scoped>
@import "index";

.location-missions__mission {
  display: block;
  color: inherit;
}

.location-missions__all {
  display: inline-block;
  margin-top: 10px;
  font-size: 13px;
}
</style>
