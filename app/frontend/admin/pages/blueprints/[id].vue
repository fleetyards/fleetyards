<script lang="ts">
export default {
  name: "AdminBlueprintPage",
};
</script>

<script lang="ts" setup>
import { useBlueprint as useBlueprintQuery } from "@/services/fyAdminApi";
import AsyncData from "@/shared/components/AsyncData.vue";
import BreadCrumbs from "@/shared/components/BreadCrumbs/index.vue";
import Heading from "@/shared/components/base/Heading/index.vue";
import BaseTable from "@/shared/components/base/Table/index.vue";
import { type BaseTableCol } from "@/shared/components/base/Table/types";
import DetailList from "@/admin/components/DetailList/index.vue";
import { type Detail } from "@/admin/components/DetailList/types";
import { useI18n } from "@/shared/composables/useI18n";
import { useMetaInfo } from "@/shared/composables/useMetaInfo";

type MaterialRow = {
  id: string;
  slot: string;
  material: string;
  type: string;
  quantity?: number | null;
  minQuality?: number | null;
};

type StatRow = {
  id: string;
  slot: string;
  stat: string;
  ramp: string;
  quality: string;
  change: string;
  baseValue?: number | null;
};

type SourceRow = {
  id: string;
  kind: string;
  org: string;
  mission: string;
  standing: string;
  pool: string;
};

const { t, l } = useI18n();

const route = useRoute();

// `params.id` is typed `string | string[]`; this route declares one segment.
const blueprintId = computed(() => route.params.id as string);

const { data: blueprint, ...asyncStatus } = useBlueprintQuery(blueprintId);

const { updateMetaInfo } = useMetaInfo();

const title = computed(() => {
  if (route.meta.title && blueprint.value) {
    return t(`title.${route.meta.title}`, {
      blueprint: blueprint.value.name || blueprint.value.scKey,
    });
  }

  return undefined;
});

watch(
  [() => blueprint.value, () => route.meta.title],
  () => {
    if (title.value) {
      updateMetaInfo({ title: title.value });
    }
  },
  { immediate: true },
);

const crumbs = computed(() => [
  {
    to: { name: "admin-blueprints", hash: `#${blueprintId.value}` },
    label: t("nav.admin.blueprints.index"),
  },
  {
    to: { name: "admin-blueprint", params: { id: blueprintId.value } },
    label: blueprint.value?.name || blueprint.value?.scKey || "",
  },
]);

const dash = "—";

const details = computed((): Detail[] => {
  const record = blueprint.value;

  if (!record) return [];

  return [
    { label: t("labels.blueprint.name"), value: record.name },
    {
      label: t("labels.admin.blueprints.makes"),
      value: record.craftable
        ? `${record.craftable.name || record.craftable.slug} (${record.craftable.type})`
        : t("labels.admin.blueprints.noOutput"),
    },
    { label: t("labels.blueprint.craftTime"), value: record.craftTime },
    { label: t("labels.blueprint.slots"), value: record.slotCount },
    { label: t("labels.admin.blueprints.slug"), value: record.slug },
    { label: t("labels.admin.blueprints.scKey"), value: record.scKey },
    { label: t("labels.admin.blueprints.scRef"), value: record.scRef },
    {
      label: t("labels.admin.blueprints.build"),
      value: record.build
        ? `${record.build.version} (${record.build.environment})`
        : dash,
    },
    {
      label: t("labels.admin.blueprints.state"),
      value: t(
        record.retired
          ? "labels.admin.blueprints.states.retired"
          : "labels.admin.blueprints.states.current",
      ),
    },
    {
      label: t("labels.admin.blueprints.createdAt"),
      value: l(record.createdAt, "datetime.formats.short"),
    },
    {
      label: t("labels.admin.blueprints.updatedAt"),
      value: l(record.updatedAt, "datetime.formats.short"),
    },
  ];
});

const slotLabel = (position: number, name?: string | null) =>
  name ? `${position} · ${name}` : String(position);

const materialRows = computed((): MaterialRow[] =>
  (blueprint.value?.costSlots || []).flatMap((slot) =>
    slot.options.map((option, index) => ({
      id: `${slot.position}-${index}`,
      slot: slotLabel(slot.position, slot.name),
      // `commodityKey` answers even where the catalogue has no row, so a cost
      // line never renders nameless.
      material: option.commodity?.name || option.commodityKey || dash,
      type: option.type,
      quantity: option.quantity,
      minQuality: option.minQuality,
    })),
  ),
);

const statRows = computed((): StatRow[] =>
  (blueprint.value?.costSlots || []).flatMap((slot) =>
    slot.modifiers.map((modifier, index) => ({
      id: `${slot.position}-${index}`,
      slot: slotLabel(slot.position, slot.name),
      stat: modifier.name || modifier.propertyKey || dash,
      ramp: modifier.ramp,
      quality: `${modifier.startQuality ?? dash} – ${modifier.endQuality ?? dash}`,
      change: `${modifier.modifierAtStart ?? dash} → ${modifier.modifierAtEnd ?? dash}${modifier.unit ? ` ${modifier.unit}` : ""}`,
      baseValue: modifier.baseValue,
    })),
  ),
);

const sourceRows = computed((): SourceRow[] =>
  (blueprint.value?.sources || []).map((source, index) => ({
    id: String(index),
    kind: source.kind,
    // 24 of the 154 reward pools name no org, so this is blank rather than
    // guessed.
    org: source.orgName || t("labels.blueprint.unattributed"),
    mission: source.missionName || dash,
    standing:
      source.minStanding || source.maxStanding
        ? `${source.minStanding || dash} – ${source.maxStanding || dash}`
        : source.minPoints != null
          ? t("labels.blueprint.minPoints", { points: source.minPoints })
          : dash,
    pool:
      [source.poolGroup, source.poolKey].filter(Boolean).join(" / ") || dash,
  })),
);

const materialColumns: BaseTableCol<MaterialRow>[] = [
  { name: "slot", label: "Slot" },
  { name: "material", label: "Material" },
  { name: "type", label: "Type", mobile: false },
  { name: "quantity", label: "Quantity", alignment: "right" },
  { name: "minQuality", label: "Min Quality", alignment: "right" },
];

const statColumns: BaseTableCol<StatRow>[] = [
  { name: "slot", label: "Slot" },
  { name: "stat", label: "Stat" },
  { name: "quality", label: "Quality", mobile: false },
  { name: "change", label: "Change", alignment: "right" },
  { name: "baseValue", label: "Base", alignment: "right", mobile: false },
  { name: "ramp", label: "Ramp", mobile: false },
];

const sourceColumns: BaseTableCol<SourceRow>[] = [
  { name: "kind", label: "Kind" },
  { name: "org", label: "Org" },
  { name: "mission", label: "Mission", mobile: false },
  { name: "standing", label: "Standing", mobile: false },
  { name: "pool", label: "Pool", mobile: false },
];
</script>

<template>
  <AsyncData :async-status="asyncStatus">
    <template #resolved>
      <BreadCrumbs :crumbs="crumbs" :current-id="blueprintId" />

      <Heading hero>
        {{ blueprint?.name || blueprint?.scKey }}
      </Heading>

      <DetailList :details="details" data-test="blueprint-details" />

      <!--
        Read only. Every figure below is replaced by the next load, so there is
        nothing here to edit -- a wrong recipe is a parser or loader fix.
      -->
      <BaseTable
        :records="materialRows"
        primary-key="id"
        :columns="materialColumns"
        :title="t('headlines.admin.blueprints.materials')"
        empty-visible
        data-test="blueprint-materials"
      />

      <BaseTable
        :records="statRows"
        primary-key="id"
        :columns="statColumns"
        :title="t('headlines.admin.blueprints.stats')"
        empty-visible
        data-test="blueprint-stats"
      />

      <BaseTable
        :records="sourceRows"
        primary-key="id"
        :columns="sourceColumns"
        :title="t('headlines.admin.blueprints.sources')"
        empty-visible
        data-test="blueprint-sources"
      />
    </template>
  </AsyncData>
</template>
