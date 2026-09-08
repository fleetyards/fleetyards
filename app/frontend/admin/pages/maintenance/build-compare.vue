<script lang="ts">
export default {
  name: "MaintenanceBuildComparePage",
};
</script>

<script lang="ts" setup>
import Heading from "@/shared/components/base/Heading/index.vue";
import HeadingSmall from "@/shared/components/base/Heading/Small/index.vue";
import BasePanel from "@/shared/components/base/Panel/index.vue";
import BasePill from "@/shared/components/base/Pill/index.vue";
import BaseSelect from "@/shared/components/base/Select/index.vue";
import SmallLoader from "@/shared/components/SmallLoader/index.vue";

import { PillVariantsEnum } from "@/shared/components/base/Pill/types";
import { useI18n } from "@/shared/composables/useI18n";
import {
  useScDataBuilds,
  useScDataCompare,
  type ScDataBuildsItemsItem,
} from "@/services/fyApi";

const { t } = useI18n();

const { data: buildList, isPending: buildsPending } = useScDataBuilds();

const builds = computed<ScDataBuildsItemsItem[]>(
  () => buildList.value?.items || [],
);

const buildLabel = (build: ScDataBuildsItemsItem) =>
  `${build.environment} · ${build.version}`;

const buildOptions = computed(() =>
  builds.value.map((build) => ({
    label: buildLabel(build),
    value: build.version,
  })),
);

const from = ref<string | null>(null);
const to = ref<string | null>(null);

/*
 * The two newest, which is the patch diff for whichever environment loaded
 * last. It is a starting point rather than the interesting question -- a
 * preview is live against ptu, and the list is ordered by build rather than
 * grouped by environment, so no default can pick that pair on its own.
 */
watch(
  builds,
  (list) => {
    if (from.value || to.value || list.length < 2) return;

    to.value = list[0].version;
    from.value = list[1].version;
  },
  { immediate: true },
);

const compareParams = computed(() => ({
  from: from.value as string,
  to: to.value as string,
}));

const comparable = computed(
  () => !!from.value && !!to.value && from.value !== to.value,
);

const {
  data: comparison,
  isPending: comparePending,
  isError: compareFailed,
} = useScDataCompare(compareParams, {
  query: { enabled: comparable },
});

const CATALOGUES = [
  "components",
  "equipment",
  "commodities",
  "models",
] as const;

type CatalogueName = (typeof CATALOGUES)[number];

// The four catalogues are structurally identical but generated as four distinct
// types, one per property of the response object, so the shared shape is spelled
// out here rather than picked from any one of them.
type Entry = { id: string; name?: string | null };
type Change = { id: string; name?: string | null; fields: string[] };
type Catalogue = {
  recorded: boolean;
  counts: { appeared: number; vanished: number; changed: number };
  appeared: Entry[];
  vanished: Entry[];
  changed: Change[];
};

const catalogueFor = (name: CatalogueName): Catalogue | undefined =>
  comparison.value?.catalogues?.[name] as Catalogue | undefined;

/*
 * A changed list runs to hundreds of rows -- 359 components on the pair this was
 * built against -- and a page that renders every one of them is a page nobody
 * scrolls to the bottom of. What is cut off is stated rather than trimmed away
 * silently.
 */
const LIST_LIMIT = 25;

const shown = <T,>(list: T[]) => list.slice(0, LIST_LIMIT);
const hidden = (list: unknown[]) => Math.max(0, list.length - LIST_LIMIT);

const entryName = (entry: Entry | Change) => entry.name || entry.id;
</script>

<template>
  <Heading hero>
    {{ t("headlines.admin.buildCompare.index") }}
    <HeadingSmall v-if="comparison">
      {{ comparison.from.version }} → {{ comparison.to.version }}
    </HeadingSmall>
  </Heading>

  <div class="build-compare__picker">
    <BaseSelect
      v-model="from"
      name="compare-from"
      :options="buildOptions"
      :nullable="false"
      :disabled="buildsPending"
      :label="t('labels.buildCompare.from')"
    />
    <BaseSelect
      v-model="to"
      name="compare-to"
      :options="buildOptions"
      :nullable="false"
      :disabled="buildsPending"
      :label="t('labels.buildCompare.to')"
    />
  </div>

  <p v-if="!buildsPending && builds.length < 2" class="text-muted">
    {{ t("labels.buildCompare.needsTwoBuilds") }}
  </p>

  <p v-else-if="!comparable" class="text-muted">
    {{ t("labels.buildCompare.pickTwoBuilds") }}
  </p>

  <p v-else-if="compareFailed" class="text-muted">
    {{ t("labels.buildCompare.failed") }}
  </p>

  <SmallLoader v-else-if="comparePending" />

  <div v-else class="build-compare__catalogues">
    <BasePanel
      v-for="name in CATALOGUES"
      :key="name"
      class="build-compare__catalogue"
      data-test="build-compare-catalogue"
      :data-catalogue="name"
    >
      <h3>{{ t(`labels.buildCompare.catalogues.${name}`) }}</h3>

      <!--
        A catalogue with no rows on one side was never recorded for that build.
        Saying so is the whole point: without it the answer reads as "nothing
        changed", which is a different and wrong statement.
      -->
      <p
        v-if="!catalogueFor(name)?.recorded"
        class="text-muted"
        data-test="build-compare-not-recorded"
      >
        {{ t("labels.buildCompare.notRecorded") }}
      </p>

      <template v-else>
        <div class="build-compare__counts">
          <BasePill
            :variant="PillVariantsEnum.SUCCESS"
            uppercase
            data-test="build-compare-count-appeared"
          >
            {{ t("labels.buildCompare.appeared") }}
            {{ catalogueFor(name)?.counts.appeared }}
          </BasePill>
          <BasePill
            :variant="PillVariantsEnum.DANGER"
            uppercase
            data-test="build-compare-count-vanished"
          >
            {{ t("labels.buildCompare.vanished") }}
            {{ catalogueFor(name)?.counts.vanished }}
          </BasePill>
          <BasePill
            :variant="PillVariantsEnum.WARNING"
            uppercase
            data-test="build-compare-count-changed"
          >
            {{ t("labels.buildCompare.changed") }}
            {{ catalogueFor(name)?.counts.changed }}
          </BasePill>
        </div>

        <template
          v-for="list in [
            { key: 'appeared', entries: catalogueFor(name)?.appeared || [] },
            { key: 'vanished', entries: catalogueFor(name)?.vanished || [] },
          ]"
          :key="list.key"
        >
          <div v-if="list.entries.length" class="build-compare__list">
            <h4>{{ t(`labels.buildCompare.${list.key}`) }}</h4>
            <ul>
              <li
                v-for="entry in shown(list.entries)"
                :key="entry.id"
                data-test="build-compare-entry"
              >
                {{ entryName(entry) }}
              </li>
            </ul>
            <p
              v-if="hidden(list.entries)"
              class="text-muted"
              data-test="build-compare-more"
            >
              {{
                t("labels.buildCompare.andMore", {
                  count: hidden(list.entries),
                })
              }}
            </p>
          </div>
        </template>

        <div
          v-if="catalogueFor(name)?.changed.length"
          class="build-compare__list"
        >
          <h4>{{ t("labels.buildCompare.changed") }}</h4>
          <ul>
            <li
              v-for="change in shown(catalogueFor(name)?.changed || [])"
              :key="change.id"
              data-test="build-compare-change"
            >
              {{ entryName(change) }}
              <span class="text-muted">{{ change.fields.join(", ") }}</span>
            </li>
          </ul>
          <p
            v-if="hidden(catalogueFor(name)?.changed || [])"
            class="text-muted"
            data-test="build-compare-more"
          >
            {{
              t("labels.buildCompare.andMore", {
                count: hidden(catalogueFor(name)?.changed || []),
              })
            }}
          </p>
        </div>
      </template>
    </BasePanel>
  </div>
</template>

<style lang="scss" scoped>
.build-compare__picker {
  display: flex;
  flex-wrap: wrap;
  gap: 1rem;
  margin-bottom: 2rem;

  > * {
    flex: 1 1 18rem;
  }
}

.build-compare__catalogues {
  display: grid;
  gap: 1rem;
  grid-template-columns: repeat(auto-fit, minmax(20rem, 1fr));
}

.build-compare__counts {
  display: flex;
  flex-wrap: wrap;
  gap: 0.5rem;
  margin-bottom: 1rem;
}

.build-compare__list {
  margin-top: 1rem;

  ul {
    list-style: none;
    margin: 0;
    padding: 0;
  }

  li {
    display: flex;
    gap: 0.5rem;
    justify-content: space-between;
  }
}
</style>
