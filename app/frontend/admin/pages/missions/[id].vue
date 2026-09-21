<script lang="ts">
export default {
  name: "AdminMissionPage",
};
</script>

<script lang="ts" setup>
import { useGameMission as useMissionQuery } from "@/services/fyAdminApi";
import AsyncData from "@/shared/components/AsyncData.vue";
import BreadCrumbs from "@/shared/components/BreadCrumbs/index.vue";
import Heading from "@/shared/components/base/Heading/index.vue";
import BaseTable from "@/shared/components/base/Table/index.vue";
import { type BaseTableCol } from "@/shared/components/base/Table/types";
import DetailList from "@/admin/components/DetailList/index.vue";
import { type Detail } from "@/admin/components/DetailList/types";
import { useI18n } from "@/shared/composables/useI18n";
import { useMetaInfo } from "@/shared/composables/useMetaInfo";

type RewardRow = {
  id: string;
  kind: string;
  amount: string;
  detail: string;
};

const { t } = useI18n();

const route = useRoute();

// `params.id` is typed `string | string[]`; this route declares one segment.
const missionId = computed(() => route.params.id as string);

const { data: mission, ...asyncStatus } = useMissionQuery(missionId);

const { updateMetaInfo } = useMetaInfo();

watch(
  () => mission.value,
  (value) => {
    if (!value) return;

    updateMetaInfo({
      title: value.name || value.scKey,
    });
  },
  { immediate: true },
);

const crumbs = computed(() => [
  {
    to: { name: "admin-missions", hash: `#${missionId.value}` },
    label: t("nav.admin.missions.index"),
  },
  {
    to: { name: "admin-mission", params: { id: missionId.value } },
    label: mission.value?.name || mission.value?.scKey || "",
  },
]);

const dash = "—";

const standing = computed(() => {
  const record = mission.value;
  if (!record?.minStanding) return dash;
  if (!record.maxStanding || record.maxStanding === record.minStanding) {
    return record.minStanding;
  }

  return `${record.minStanding} – ${record.maxStanding}`;
});

const difficulty = computed(() => {
  const axes = mission.value?.difficulty;
  if (!axes) return dash;

  return [
    axes.mechanicalSkill,
    axes.mentalLoad,
    axes.riskOfLoss,
    axes.gameKnowledge,
  ]
    .map((level) => level ?? dash)
    .join(" / ");
});

const details = computed((): Detail[] => {
  const record = mission.value;

  if (!record) return [];

  return [
    {
      label: t("labels.gameMission.name"),
      // 74 contracts have no name anywhere. Said outright here rather than
      // left blank, because these are the rows this section exists to surface.
      value: record.name || t("labels.admin.missions.unnamed"),
    },
    {
      label: t("labels.gameMission.org"),
      value: record.org?.name || t("labels.gameMission.offeredByUnknown"),
    },
    { label: t("labels.gameMission.standing"), value: standing.value },
    {
      label: t("labels.gameMission.kind"),
      value: record.kind ? t(`labels.gameMission.kinds.${record.kind}`) : dash,
    },
    {
      // Four axes rather than one figure: the game weights them per difficulty
      // profile, and a single number would be one we invented.
      label: t("labels.admin.missions.difficultyAxes"),
      value: difficulty.value,
    },
    {
      label: t("labels.gameMission.difficulty"),
      value: record.difficulty?.profile || dash,
    },
    { label: t("labels.admin.missions.slug"), value: record.slug },
    { label: t("labels.admin.missions.scKey"), value: record.scKey },
    { label: t("labels.admin.missions.scRef"), value: record.scRef },
    {
      label: t("labels.admin.missions.generator"),
      value: record.generatorKey || dash,
    },
    {
      // A developer's note, and the only handle on a row the game never named.
      label: t("labels.admin.missions.debugName"),
      value: record.debugName || dash,
    },
    {
      label: t("labels.admin.missions.build"),
      value: record.build
        ? `${record.build.version} (${record.build.environment})`
        : dash,
    },
    {
      label: t("labels.admin.missions.state"),
      value: t(
        record.retired
          ? "labels.admin.missions.states.retired"
          : record.released
            ? "labels.admin.missions.states.released"
            : "labels.admin.missions.states.unreleased",
      ),
    },
    {
      label: t("labels.gameMission.blueprints"),
      value: record.blueprintPoolRefs?.length
        ? String(record.blueprintPoolRefs.length)
        : dash,
    },
  ];
});

const rewardColumns: BaseTableCol<RewardRow>[] = [
  { name: "kind", label: t("labels.admin.missions.columns.rewardKind") },
  {
    name: "amount",
    label: t("labels.admin.missions.columns.amount"),
    alignment: "right",
  },
  { name: "detail", label: t("labels.admin.missions.columns.rewardDetail") },
];

const rewardRows = computed((): RewardRow[] =>
  (mission.value?.rewards || []).map((reward, index) => ({
    id: `${reward.kind}-${index}`,
    kind: t(`labels.gameMission.rewardKinds.${reward.kind}`),
    // 2,352 of the contracts that pay leave the figure to the game, so the
    // amount column says which of the two this is rather than sitting empty.
    amount: reward.calculated
      ? t("labels.gameMission.calculatedInGame")
      : [reward.amount, reward.max].filter((v) => v != null).join(" – ") ||
        dash,
    detail:
      reward.entityName ||
      reward.orgName ||
      reward.badge ||
      reward.currency ||
      reward.entityClass ||
      dash,
  })),
);
</script>

<template>
  <AsyncData :async-status="asyncStatus">
    <template #resolved>
      <BreadCrumbs :crumbs="crumbs" :current-id="missionId" />

      <Heading hero class="mb-4">
        {{ mission?.name || mission?.scKey }}
      </Heading>

      <DetailList :details="details" data-test="mission-details" />

      <!--
        Read only. Every figure here is replaced by the next load, so there is
        nothing to edit -- a wrong title or a missing reward is a parser fix.
      -->
      <section class="mt-10">
        <BaseTable
          :records="rewardRows"
          primary-key="id"
          :columns="rewardColumns"
          :empty-visible="!rewardRows.length"
        >
          <template #col-kind="{ record }">{{ record.kind }}</template>
          <template #col-amount="{ record }">{{ record.amount }}</template>
          <template #col-detail="{ record }">{{ record.detail }}</template>
        </BaseTable>
      </section>
    </template>
  </AsyncData>
</template>
