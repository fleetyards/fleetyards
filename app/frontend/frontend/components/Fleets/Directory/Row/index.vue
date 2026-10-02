<script lang="ts">
export default {
  name: "FleetDirectoryRow",
};
</script>

<script lang="ts" setup>
import Avatar from "@/shared/components/Avatar/index.vue";
import RowListItem from "@/shared/components/RowListItem/index.vue";
import {
  RowListItemTonesEnum,
  type RowListItemBadge,
  type RowListItemChip,
  type RowListItemTag,
} from "@/shared/components/RowListItem/types";
import { useI18n } from "@/shared/composables/useI18n";
import { useFleetProfileLabels } from "@/frontend/composables/useFleetProfileLabels";
import { type FleetDirectoryEntry } from "@/services/fyApi";

type Props = {
  fleet: FleetDirectoryEntry;
};

const props = defineProps<Props>();

const { t, toNumber } = useI18n();

const route = useRoute();

const { activityLabel, alignmentLabel, commitmentLabel, languageLabel } =
  useFleetProfileLabels();

// Every value the directory filters by narrows it when clicked, as in the
// catalogue lists. `page` is dropped: the clicked row is rarely on the same
// page of a smaller result.
const filterLink = (key: string, value: string) => ({
  name: route.name as string,
  query: { ...route.query, page: undefined, [key]: value },
});

const chips = computed<RowListItemChip[]>(() =>
  [props.fleet.primaryActivity, props.fleet.secondaryActivity]
    .filter((activity): activity is NonNullable<typeof activity> => !!activity)
    .map((activity) => ({
      key: activity,
      label: activityLabel(activity) ?? activity,
      to: filterLink("activityIn", activity),
    })),
);

const ALIGNMENT_TONES: Record<string, RowListItemTonesEnum> = {
  lawful: RowListItemTonesEnum.PRIMARY,
  neutral: RowListItemTonesEnum.DEFAULT,
  outlaw: RowListItemTonesEnum.DANGER,
};

const tags = computed<RowListItemTag[]>(() => {
  const list: RowListItemTag[] = [];

  if (props.fleet.alignment) {
    list.push({
      key: "alignment",
      label: alignmentLabel(props.fleet.alignment) ?? props.fleet.alignment,
      to: filterLink("alignmentIn", props.fleet.alignment),
      tone: ALIGNMENT_TONES[props.fleet.alignment],
    });
  }

  if (props.fleet.commitment) {
    list.push({
      key: "commitment",
      label: commitmentLabel(props.fleet.commitment) ?? props.fleet.commitment,
      to: filterLink("commitmentIn", props.fleet.commitment),
    });
  }

  if (props.fleet.roleplay) {
    list.push({
      key: "roleplay",
      label: t("labels.fleetDirectory.roleplay"),
      to: filterLink("roleplayEq", "true"),
    });
  }

  return list;
});

const badges = computed<RowListItemBadge[]>(() => {
  const list: RowListItemBadge[] = [
    {
      key: "members",
      label: t("labels.fleetDirectory.memberCount"),
      value: String(toNumber(props.fleet.memberCount, "integer")),
    },
  ];

  if (props.fleet.language) {
    list.push({
      key: "language",
      label: t("labels.fleetDirectory.language"),
      value: languageLabel(props.fleet.language) ?? props.fleet.language,
    });
  }

  if (props.fleet.recruiting !== null && props.fleet.recruiting !== undefined) {
    list.push({
      key: "recruiting",
      value: props.fleet.recruiting
        ? t("labels.fleetDirectory.recruiting")
        : t("labels.fleetDirectory.notRecruiting"),
      quiet: !props.fleet.recruiting,
    });
  }

  return list;
});
</script>

<template>
  <RowListItem
    class="fleet-directory-row"
    :to="{ name: 'fleet', params: { slug: fleet.slug } }"
    :chips="chips"
    :tags="tags"
    :badges="badges"
    data-test="fleet-directory-row"
  >
    <template #leading>
      <Avatar :avatar="fleet.logo?.smallUrl || undefined" size="small" />
    </template>

    <template #name>
      {{ fleet.name }}
    </template>

    <template #sub>
      <span>{{ fleet.fid }}</span>
      <span>{{
        t("labels.fleetDirectory.rsiSid", { sid: fleet.rsiSid })
      }}</span>
    </template>
  </RowListItem>
</template>
