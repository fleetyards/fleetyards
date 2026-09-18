<script lang="ts">
export default {
  name: "BlueprintSources",
};
</script>

<script lang="ts" setup>
import MetricsCard from "@/frontend/components/Models/MetricsCard/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import { useMissionName } from "@/frontend/composables/useMissionName";
import { type BlueprintSource } from "@/services/fyApi";

type Props = {
  sources: BlueprintSource[];
  sourceUnknown?: boolean;
};

const props = defineProps<Props>();

const { t } = useI18n();

const { segments, isTokenOnly } = useMissionName();

const open = ref<Record<string, boolean>>({});

// A title the export never resolves says less than the kind already does.
const titleFor = (entry: BlueprintSource) => {
  const name = entry.missionName;
  if (!name || isTokenOnly(name)) return undefined;

  return segments(name);
};

const anyPlaceholder = computed(() =>
  props.sources.some((source) =>
    (titleFor(source) || []).some((segment) => segment.slot),
  ),
);

// Grouped by who hands the recipe out. One blueprint in the build carries 29
// sources; flat, that is the whole rail.
//
// An org that names no missions still gets a group: nine source entries sit
// in a generator that names more than one faction and are deliberately left
// unattributed rather than guessed at.
const groups = computed(() => {
  const byOrg = new Map<string, BlueprintSource[]>();

  props.sources.forEach((source) => {
    const key = source.orgName || "";
    byOrg.set(key, [...(byOrg.get(key) || []), source]);
  });

  return [...byOrg.entries()].map(([key, entries]) => ({
    key,
    name: key || t("labels.blueprint.unattributed"),
    entries,
    count: entries.length,
  }));
});

const isOpen = (key: string) => open.value[key] ?? false;

const toggle = (key: string) => {
  open.value = { ...open.value, [key]: !isOpen(key) };
};

// The first group opens on its own, so the shape of an expanded one is
// visible without a click.
watch(
  groups,
  (value) => {
    if (!value.length) return;
    if (Object.keys(open.value).length) return;

    open.value = { [value[0].key]: true };
  },
  { immediate: true },
);

const summary = computed(() =>
  t("labels.blueprint.sourceSummary", {
    count: props.sources.length,
    orgs: groups.value.length,
  }),
);
</script>

<template>
  <MetricsCard
    class="blueprint-sources"
    :title="t('labels.blueprint.whereItDrops')"
    variant="slim"
  >
    <template v-if="sources.length" #head>
      <span class="blueprint-sources__summary">{{ summary }}</span>
    </template>

    <!-- Said outright, not left to an empty list. 901 of the 1,607 recipes in
         the build appear in no reward pool, which is more of the catalogue
         than the other case -- an empty panel would read as our data being
         missing rather than the game's. -->
    <div v-if="sourceUnknown" class="blueprint-sources__none">
      <p class="blueprint-sources__none-lead">
        {{ t("labels.blueprint.noSourceLead") }}
      </p>
      <p class="blueprint-sources__none-body">
        {{ t("labels.blueprint.noSourceBody") }}
      </p>
    </div>

    <div v-else class="blueprint-sources__groups">
      <div
        v-for="group in groups"
        :key="group.key"
        class="blueprint-sources__group"
      >
        <button
          type="button"
          class="blueprint-sources__group-head"
          :aria-expanded="isOpen(group.key)"
          @click="toggle(group.key)"
        >
          <i
            class="fa-duotone fa-chevron-right blueprint-sources__chevron"
            :class="{ 'blueprint-sources__chevron--open': isOpen(group.key) }"
          />
          <span class="blueprint-sources__org">{{ group.name }}</span>
          <span class="blueprint-sources__count">{{ group.count }}</span>
        </button>

        <div v-if="isOpen(group.key)" class="blueprint-sources__missions">
          <div
            v-for="(entry, index) in group.entries"
            :key="`${group.key}-${index}`"
            class="blueprint-sources__mission"
          >
            <div class="blueprint-sources__mission-name">
              <template v-if="titleFor(entry)">
                <template
                  v-for="(segment, at) in titleFor(entry)"
                  :key="`${group.key}-${index}-${at}`"
                >
                  <span v-if="segment.slot" class="blueprint-sources__slot">{{
                    segment.text
                  }}</span>
                  <template v-else>{{ segment.text }}</template>
                </template>
              </template>
              <template v-else>
                {{ t(`labels.blueprint.kinds.${entry.kind}`) }}
              </template>
            </div>
            <div class="blueprint-sources__mission-meta">
              <!-- A contract states the reputation band it is offered in; the
                   scenario states the points that unlock the tier instead. -->
              <span v-if="entry.minStanding">
                {{ entry.minStanding }}
                <template
                  v-if="
                    entry.maxStanding && entry.maxStanding !== entry.minStanding
                  "
                >
                  &rarr; {{ entry.maxStanding }}
                </template>
              </span>
              <span v-else-if="entry.minPoints">
                {{
                  t("labels.blueprint.minPoints", { points: entry.minPoints })
                }}
              </span>
            </div>
          </div>
        </div>
      </div>

      <p v-if="anyPlaceholder" class="blueprint-sources__legend">
        {{ t("labels.blueprint.missionSlotsHint") }}
      </p>
    </div>
  </MetricsCard>
</template>

<style lang="scss" scoped>
@import "index";
</style>
