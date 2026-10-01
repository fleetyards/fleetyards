<script lang="ts">
export default {
  name: "AdminLocationPage",
};
</script>

<script lang="ts" setup>
import { useLocation } from "@/services/fyAdminApi";
import AsyncData from "@/shared/components/AsyncData.vue";
import BreadCrumbs from "@/shared/components/BreadCrumbs/index.vue";
import Heading from "@/shared/components/base/Heading/index.vue";
import DetailList from "@/admin/components/DetailList/index.vue";
import { type Detail } from "@/admin/components/DetailList/types";
import { useI18n } from "@/shared/composables/useI18n";
import { useMetaInfo } from "@/shared/composables/useMetaInfo";

const { t } = useI18n();

const route = useRoute();

const locationId = computed(() => route.params.id as string);

const { data: location, ...asyncStatus } = useLocation(locationId);

const { updateMetaInfo } = useMetaInfo();

watch(
  () => location.value,
  (value) => {
    if (!value) return;

    updateMetaInfo({ title: value.name || value.scKey });
  },
  { immediate: true },
);

const crumbs = computed(() => [
  {
    to: { name: "admin-locations", hash: `#${locationId.value}` },
    label: t("nav.admin.locations.index"),
  },
  {
    to: { name: "admin-location", params: { id: locationId.value } },
    label: location.value?.name || location.value?.scKey || "",
  },
]);

const dash = "—";

const yesNo = (value?: boolean) =>
  value ? t("labels.admin.locations.yes") : t("labels.admin.locations.no");

const details = computed((): Detail[] => {
  const record = location.value;

  if (!record) return [];

  return [
    { label: t("labels.location.name"), value: record.name },
    {
      label: t("labels.location.kind"),
      value: t(`labels.location.kinds.${record.kind}`),
    },
    { label: t("labels.admin.locations.gameType"), value: record.gameType },
    { label: t("labels.admin.locations.parent"), value: record.parent?.name },
    // The game's own parent where it is not the place this one sits in:
    // what the in-game map draws, beside where the place is.
    {
      label: t("labels.location.mapParent"),
      value: record.mapParent?.name || dash,
    },
    { label: t("labels.admin.locations.system"), value: record.system?.name },
    {
      label: t("labels.location.starmapVisibility"),
      value: yesNo(record.shownOnStarmap),
    },
    {
      label: t("labels.admin.locations.shownWithParentOnly"),
      value: yesNo(record.shownWithParentOnly),
    },
    {
      label: t("labels.location.alwaysShown"),
      value: yesNo(record.alwaysShown),
    },
    {
      label: t("labels.location.quantumTravel"),
      value: yesNo(record.quantumTravelDestination),
    },
    { label: t("labels.admin.locations.slug"), value: record.slug },
    { label: t("labels.admin.locations.scKey"), value: record.scKey },
    // More than one where the overrides merged copies, or a namesake child
    // folded in.
    {
      label: t("labels.admin.locations.scRefs"),
      value: record.scRefs.join(", ") || dash,
    },
    {
      label: t("labels.admin.locations.build"),
      value: record.version || t("labels.location.retired"),
    },
    {
      label: t("labels.admin.locations.children"),
      value: record.childrenCount,
    },
    {
      label: t("labels.admin.locations.missions"),
      value: record.gameMissionsCount,
    },
    {
      label: t("labels.admin.locations.missionTemplates"),
      value: record.missionTemplateRefs?.length,
    },
    {
      label: t("labels.location.terminals"),
      value:
        (record.terminals || [])
          .map((terminal) =>
            terminal.available
              ? terminal.name
              : `${terminal.name} (${t("labels.admin.locations.unavailable")})`,
          )
          .join(", ") || dash,
    },
  ];
});
</script>

<template>
  <AsyncData :async-status="asyncStatus">
    <template #resolved>
      <BreadCrumbs :crumbs="crumbs" :current-id="locationId" />

      <Heading hero class="mb-4">
        {{ location?.name || location?.scKey }}
      </Heading>

      <!-- Read only: a wrong place is a parser or override fix. -->
      <DetailList :details="details" data-test="location-details" />
    </template>
  </AsyncData>
</template>
