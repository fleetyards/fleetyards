<script lang="ts">
export default {
  name: "MissionStatsCard",
};
</script>

<script lang="ts" setup>
import { type RouteLocationRaw } from "vue-router";
import StatsCard from "@/frontend/components/StatsCard/index.vue";
import { type HardpointStat } from "@/frontend/composables/useHardpointStats";
import { useI18n } from "@/shared/composables/useI18n";
import { type GameMission } from "@/services/fyApi";

type Props = {
  mission?: GameMission;
  name?: string;
  to?: RouteLocationRaw | false;
  loading?: boolean;
};

const props = withDefaults(defineProps<Props>(), {
  mission: undefined,
  name: undefined,
  to: undefined,
  loading: false,
});

const emit = defineEmits<{ navigate: [] }>();

const { t } = useI18n();

const stats = computed<HardpointStat[]>(() => {
  const mission = props.mission;
  if (!mission) return [];

  return [
    mission.kind
      ? {
          label: t("labels.gameMission.kind"),
          value: t(`labels.gameMission.kinds.${mission.kind}`),
        }
      : undefined,
    mission.locationKind
      ? {
          label: t("labels.gameMission.location"),
          value: t(`labels.gameMission.locationKinds.${mission.locationKind}`),
        }
      : undefined,
    mission.org?.name
      ? {
          label: t("labels.gameMission.offeredBy"),
          value: mission.org.name,
          wide: true,
        }
      : undefined,
  ].filter((stat): stat is HardpointStat => !!stat);
});

const subtitle = computed(
  () =>
    [
      props.mission?.retired ? t("labels.gameMission.retired") : undefined,
      props.mission && !props.mission.released
        ? t("labels.gameMission.unreleased")
        : undefined,
    ]
      .filter(Boolean)
      .join(" · ") || undefined,
);

const ownRoute = computed(() =>
  props.mission?.slug
    ? { name: "mission", params: { slug: props.mission.slug } }
    : undefined,
);
</script>

<template>
  <StatsCard
    compact
    :title="mission?.name || name || ''"
    variant="slim"
    :subtitle="subtitle"
    :stats="stats"
    :to="to === false ? undefined : (to ?? ownRoute)"
    :loading="loading"
    :unavailable="!loading && !mission"
    @navigate="emit('navigate')"
  />
</template>
