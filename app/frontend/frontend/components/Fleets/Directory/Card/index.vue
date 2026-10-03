<script lang="ts">
export default {
  name: "FleetDirectoryCard",
};
</script>

<script lang="ts" setup>
import Avatar from "@/shared/components/Avatar/index.vue";
import Panel from "@/shared/components/base/Panel/index.vue";
import PanelHeading from "@/shared/components/base/Panel/Heading/index.vue";
import PanelBody from "@/shared/components/base/Panel/Body/index.vue";
import Pill from "@/shared/components/base/Pill/index.vue";
import { PillVariantsEnum } from "@/shared/components/base/Pill/types";
import { HeadingLevelEnum } from "@/shared/components/base/Heading/types";
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

// As in the row: a value the directory filters by narrows it when clicked.
const filterLink = (key: string, value: string) => ({
  name: route.name as string,
  query: { ...route.query, page: undefined, [key]: value },
});

// A fleet that claimed its SID as its FID would print the same code twice.
const showSid = computed(
  () =>
    !!props.fleet.rsiSid &&
    props.fleet.rsiSid.toUpperCase() !== props.fleet.fid.toUpperCase(),
);

const activities = computed(() =>
  [props.fleet.primaryActivity, props.fleet.secondaryActivity].filter(
    (activity): activity is NonNullable<typeof activity> => !!activity,
  ),
);

const ALIGNMENT_VARIANTS: Record<string, `${PillVariantsEnum}`> = {
  lawful: PillVariantsEnum.DEFAULT,
  neutral: PillVariantsEnum.NEUTRAL,
  outlaw: PillVariantsEnum.DANGER,
};

const rows = computed(() =>
  [
    {
      key: "language",
      label: t("labels.fleetDirectory.language"),
      value: languageLabel(props.fleet.language),
      to: props.fleet.language
        ? filterLink("languageIn", props.fleet.language)
        : undefined,
    },
    {
      key: "commitment",
      label: t("labels.fleet.rsiProfile.commitment"),
      value: commitmentLabel(props.fleet.commitment),
    },
    {
      key: "timezone",
      label: t("labels.filters.fleetDirectory.timezone"),
      value: props.fleet.defaultTimezone,
    },
  ].filter((row) => !!row.value),
);
</script>

<template>
  <Panel class="fleet-directory-card" data-test="fleet-directory-card">
    <PanelHeading :level="HeadingLevelEnum.H2">
      <router-link
        class="fleet-directory-card__title"
        :to="{ name: 'fleet', params: { slug: fleet.slug } }"
      >
        <Avatar :avatar="fleet.logo?.smallUrl || undefined" />
        <span>
          {{ fleet.name }}
          <small class="fleet-directory-card__ids">
            {{ fleet.fid }}
            <template v-if="showSid">
              ·
              {{ t("labels.fleetDirectory.rsiSid", { sid: fleet.rsiSid }) }}
            </template>
          </small>
        </span>
      </router-link>
    </PanelHeading>

    <PanelBody>
      <div class="fleet-directory-card__pills">
        <router-link
          v-if="fleet.alignment"
          :to="filterLink('alignmentIn', fleet.alignment)"
        >
          <Pill :variant="ALIGNMENT_VARIANTS[fleet.alignment]">
            {{ alignmentLabel(fleet.alignment) }}
          </Pill>
        </router-link>
        <Pill
          v-if="fleet.recruiting !== null && fleet.recruiting !== undefined"
          :variant="
            fleet.recruiting
              ? PillVariantsEnum.SUCCESS
              : PillVariantsEnum.NEUTRAL
          "
        >
          {{
            fleet.recruiting
              ? t("labels.fleetDirectory.recruiting")
              : t("labels.fleetDirectory.notRecruiting")
          }}
        </Pill>
        <router-link
          v-if="fleet.roleplay"
          :to="filterLink('roleplayEq', 'true')"
        >
          <Pill :variant="PillVariantsEnum.NEUTRAL">
            {{ t("labels.fleetDirectory.roleplay") }}
          </Pill>
        </router-link>
      </div>

      <div class="metrics-card__hero">
        <div class="metrics-card__tile">
          <div class="metrics-card__tile__label">
            {{ t("labels.fleetDirectory.memberCount") }}
          </div>
          <div class="metrics-card__tile__value">
            {{ toNumber(fleet.memberCount, "integer") }}
          </div>
        </div>
        <div v-if="activities.length" class="metrics-card__tile">
          <div class="metrics-card__tile__label">
            {{ t("labels.filters.fleetDirectory.activity") }}
          </div>
          <div
            class="metrics-card__tile__value fleet-directory-card__activities"
          >
            <router-link
              v-for="activity in activities"
              :key="activity"
              :to="filterLink('activityIn', activity)"
            >
              {{ activityLabel(activity) }}
            </router-link>
          </div>
        </div>
      </div>

      <div v-if="rows.length" class="metrics-card__rows">
        <div v-for="row in rows" :key="row.key" class="metrics-card__row">
          <div class="metrics-card__row__label">{{ row.label }}</div>
          <div class="metrics-card__row__value">
            <router-link v-if="row.to" :to="row.to">{{
              row.value
            }}</router-link>
            <template v-else>{{ row.value }}</template>
          </div>
        </div>
      </div>
    </PanelBody>
  </Panel>
</template>

<style lang="scss" scoped>
@import "@/shared/components/metricsCard";

.fleet-directory-card__title {
  display: flex;
  align-items: center;
  gap: 12px;
}

.fleet-directory-card__ids {
  display: block;
  color: var(--color-text-dim);
  font-size: 0.8em;
}

.fleet-directory-card__pills {
  display: flex;
  flex-wrap: wrap;
  gap: 6px;
  margin-bottom: 12px;
}

.fleet-directory-card__activities {
  display: flex;
  flex-direction: column;
  font-size: 1rem;
}
</style>
