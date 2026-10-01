<script lang="ts">
export default {
  name: "MissionStatsCard",
};
</script>

<script lang="ts" setup>
import { type RouteLocationRaw } from "vue-router";
import StatsCard from "@/frontend/components/StatsCard/index.vue";
import {
  type StatsCardBadge,
  type StatsCardStatus,
} from "@/frontend/components/StatsCard/types";
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

const category = computed(() =>
  props.mission?.kind
    ? t(`labels.gameMission.kinds.${props.mission.kind}`)
    : undefined,
);

const subtitle = computed(() =>
  props.mission?.org?.name
    ? t("labels.statsCard.offeredBy", { name: props.mission.org.name })
    : undefined,
);

// Retired outranks unreleased: a mission the game dropped is no longer
// waiting on a release.
const status = computed<StatsCardStatus | undefined>(() => {
  const mission = props.mission;
  if (!mission) return undefined;

  if (mission.retired) {
    return { label: t("labels.gameMission.retired"), tone: "neutral" };
  }

  if (!mission.released) {
    return { label: t("labels.gameMission.unreleased"), tone: "warning" };
  }

  return undefined;
});

const badges = computed<StatsCardBadge[]>(() =>
  props.mission?.locationKind
    ? [
        {
          key: "location",
          label: t("labels.gameMission.location"),
          value: t(
            `labels.gameMission.locationKinds.${props.mission.locationKind}`,
          ),
        },
      ]
    : [],
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
    kind="GameMission"
    :category="category"
    :subtitle="subtitle"
    :status="status"
    :badges="badges"
    :to="to === false ? undefined : (to ?? ownRoute)"
    :loading="loading"
    :unavailable="!loading && !mission"
    @navigate="emit('navigate')"
  />
</template>
