<script lang="ts">
export default {
  name: "CompareBuildsPage",
};
</script>

<script lang="ts" setup>
import debounce from "lodash.debounce";
import AsyncData from "@/shared/components/AsyncData.vue";
import Alert from "@/shared/components/base/Alert/index.vue";
import { AlertVariantsEnum } from "@/shared/components/base/Alert/types";
import Btn from "@/shared/components/base/Btn/index.vue";
import { BtnSizesEnum } from "@/shared/components/base/Btn/types";
import Chip from "@/shared/components/base/Chip/index.vue";
import { ChipStatesEnum } from "@/shared/components/base/Chip/types";
import FormInput from "@/shared/components/base/FormInput/index.vue";
import Heading from "@/shared/components/base/Heading/index.vue";
import Select from "@/shared/components/base/Select/index.vue";
import CompareTabs from "@/frontend/components/Compare/Tabs/index.vue";
import DiffList from "@/frontend/components/Compare/Builds/List/index.vue";
import {
  buildLabel,
  defaultPair,
} from "@/frontend/components/Compare/Builds/format";
import copyText from "@/frontend/utils/CopyText";
import {
  ScDataDiffCatalogueEnum,
  ScDataDiffKindEnum,
  useScDataBuilds,
  useScDataDiffSummary,
  useScDataSources,
  type ScDataDiffCatalogue,
} from "@/services/fyApi";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";
import { useI18n } from "@/shared/composables/useI18n";
import { useMobile } from "@/shared/composables/useMobile";

const { t, toNumber } = useI18n();
const { displaySuccess, displayAlert } = useAppNotifications();

const route = useRoute();
const router = useRouter();
const mobile = useMobile();

const queryValue = (name: string) => {
  const value = route.query[name];

  return (Array.isArray(value) ? value[0] : value) || undefined;
};

const update = (changes: Record<string, string | undefined>) =>
  router.replace({
    query: { ...route.query, page: undefined, ...changes },
  });

const { data: buildList, ...buildsStatus } = useScDataBuilds();
const { data: sources, isPending: sourcesPending } = useScDataSources();

const builds = computed(() => buildList.value?.items || []);

const preset = computed(() =>
  sourcesPending.value
    ? undefined
    : defaultPair(builds.value, sources.value?.items || []),
);

const from = computed(() => queryValue("from") || preset.value?.from || "");
const to = computed(() => queryValue("to") || preset.value?.to || "");

// Both sides go into the link, so picking one never changes the other.
const pick = (side: "from" | "to", version: unknown) => {
  if (typeof version !== "string" || !version) return;

  void update({ from: from.value, to: to.value, [side]: version });
};

const swap = () => update({ from: to.value, to: from.value });

const buildOptions = computed(() =>
  builds.value.map((build) => ({
    label: buildLabel(build),
    value: build.version,
  })),
);

const comparable = computed(
  () => !!from.value && !!to.value && from.value !== to.value,
);

const { data: summary, ...summaryStatus } = useScDataDiffSummary(
  () => ({ from: from.value, to: to.value }),
  { query: { enabled: comparable } },
);

const total = ({ counts }: ScDataDiffCatalogue) =>
  counts.added + counts.removed + counts.changed;

const catalogues = computed(() =>
  (summary.value?.items || []).map((item) => ({
    key: item.catalogue,
    label: t(`labels.buildDiff.catalogues.${item.catalogue}`),
    total: total(item),
  })),
);

const isCatalogue = (value?: string): value is ScDataDiffCatalogueEnum =>
  Object.values<string>(ScDataDiffCatalogueEnum).includes(value || "");

const catalogue = computed<ScDataDiffCatalogueEnum>(() => {
  const asked = queryValue("catalogue");
  if (isCatalogue(asked)) return asked;

  return (
    catalogues.value.find((item) => item.total > 0)?.key ||
    ScDataDiffCatalogueEnum.models
  );
});

const pickCatalogue = (value: unknown) => {
  if (typeof value !== "string") return;

  applySearch.cancel();
  void update({
    from: from.value,
    to: to.value,
    catalogue: value,
    kind: undefined,
    field: undefined,
    search: undefined,
  });
  search.value = "";
};

const catalogueOptions = computed(() =>
  catalogues.value.map((item) => ({
    value: item.key,
    label: `${item.label} (${toNumber(item.total) || 0})`,
  })),
);

const isKind = (value?: string): value is ScDataDiffKindEnum =>
  Object.values<string>(ScDataDiffKindEnum).includes(value || "");

// The changes are what a reader came for, so they lead where there are any.
const KIND_ORDER = [
  ScDataDiffKindEnum.changed,
  ScDataDiffKindEnum.added,
  ScDataDiffKindEnum.removed,
];

const counts = computed(
  () =>
    summary.value?.items.find((item) => item.catalogue === catalogue.value)
      ?.counts,
);

const kind = computed(() => {
  const asked = queryValue("kind");
  if (isKind(asked)) return asked;

  return (
    KIND_ORDER.find((value) => counts.value?.[value]) ||
    ScDataDiffKindEnum.changed
  );
});

const field = computed(() => queryValue("field"));

const search = ref(queryValue("search") || "");

const applySearch = debounce(
  (value: string) => void update({ search: value || undefined }),
  300,
);

watch(search, (value) => {
  applySearch.cancel();
  if (value !== (queryValue("search") || "")) applySearch(value);
});

onBeforeUnmount(() => applySearch.cancel());

const kinds = computed(() =>
  KIND_ORDER.map((value) => ({
    value,
    count: counts.value?.[value] || 0,
  })),
);

const showField = (value: string) => update({ field: value });

const copyLink = () => {
  const { href } = router.resolve({
    query: {
      ...route.query,
      from: from.value,
      to: to.value,
      catalogue: catalogue.value,
    },
  });

  copyText(`${window.location.origin}${href}`).then(
    () => displaySuccess({ text: t("labels.buildDiff.copied") }),
    () => displayAlert({ text: t("labels.buildDiff.copyFailed") }),
  );
};
</script>

<template>
  <Heading hidden>{{ t("headlines.compare.builds") }}</Heading>

  <div class="build-diff">
    <CompareTabs />

    <AsyncData :async-status="buildsStatus">
      <template #resolved>
        <div class="build-diff__picker">
          <Select
            name="from"
            class="build-diff__build"
            :model-value="from"
            :options="buildOptions"
            :label="t('labels.buildDiff.from')"
            :nullable="false"
            unsorted
            data-test="build-diff-from"
            @update:model-value="pick('from', $event)"
          />
          <Btn
            :size="BtnSizesEnum.SM"
            :aria-label="t('labels.buildDiff.swap')"
            data-test="build-diff-swap"
            @click="swap"
          >
            <i class="fa-light fa-arrow-right-arrow-left" aria-hidden="true" />
          </Btn>
          <Select
            name="to"
            class="build-diff__build"
            :model-value="to"
            :options="buildOptions"
            :label="t('labels.buildDiff.to')"
            :nullable="false"
            unsorted
            data-test="build-diff-to"
            @update:model-value="pick('to', $event)"
          />
          <Btn :size="BtnSizesEnum.SM" @click="copyLink">
            <i class="fa-light fa-link" aria-hidden="true" />
            {{ t("labels.buildDiff.copyLink") }}
          </Btn>
        </div>

        <Alert
          v-if="!comparable && !sourcesPending"
          :variant="AlertVariantsEnum.INFO"
        >
          {{ t("labels.buildDiff.needsTwo") }}
        </Alert>

        <AsyncData v-else :async-status="summaryStatus">
          <template #resolved>
            <div class="build-diff__body">
              <Select
                v-if="mobile"
                name="catalogue"
                :model-value="catalogue"
                :options="catalogueOptions"
                :label="t('labels.buildDiff.catalogue')"
                :nullable="false"
                unsorted
                @update:model-value="pickCatalogue"
              />
              <nav
                v-else
                class="build-diff__catalogues"
                :aria-label="t('labels.buildDiff.catalogue')"
              >
                <button
                  v-for="item in catalogues"
                  :key="item.key"
                  type="button"
                  class="build-diff__catalogue"
                  :class="{
                    'build-diff__catalogue--active': item.key === catalogue,
                  }"
                  :aria-pressed="item.key === catalogue"
                  data-test="build-diff-catalogue"
                  @click="pickCatalogue(item.key)"
                >
                  <span>{{ item.label }}</span>
                  <span class="build-diff__count">
                    {{ item.total ? toNumber(item.total) : 0 }}
                  </span>
                </button>
              </nav>

              <div class="build-diff__list">
                <div class="build-diff__filters">
                  <Chip
                    v-for="item in kinds"
                    :key="item.value"
                    :state="
                      kind === item.value
                        ? ChipStatesEnum.INCLUDED
                        : ChipStatesEnum.NEUTRAL
                    "
                    :count="item.count"
                    @toggle="
                      update({
                        kind: kind === item.value ? undefined : item.value,
                        field: undefined,
                      })
                    "
                  >
                    {{ t(`labels.buildDiff.kinds.${item.value}`) }}
                  </Chip>
                  <Btn
                    v-if="field"
                    :size="BtnSizesEnum.SM"
                    @click="update({ field: undefined })"
                  >
                    <i class="fa-light fa-arrow-left" aria-hidden="true" />
                    {{ t("labels.buildDiff.all") }}
                  </Btn>
                  <FormInput
                    v-model="search"
                    name="build-diff-search"
                    class="build-diff__search"
                    :placeholder="t('labels.buildDiff.search')"
                    :aria-label="t('labels.buildDiff.search')"
                    no-label
                    clearable
                  />
                </div>
                <DiffList
                  :key="`${catalogue}-${from}-${to}`"
                  :catalogue="catalogue"
                  :from="from"
                  :to="to"
                  :kind="kind"
                  :field="field"
                  :search="queryValue('search')"
                  @show-field="showField"
                />
              </div>
            </div>
          </template>
        </AsyncData>
      </template>
    </AsyncData>
  </div>
</template>

<style lang="scss" scoped>
.build-diff {
  display: flex;
  flex-direction: column;
  gap: 20px;
}

.build-diff__picker {
  display: flex;
  flex-wrap: wrap;
  gap: 12px;
  align-items: flex-end;
  margin-bottom: 20px;
}

.build-diff__build {
  flex: 1 1 260px;
  min-width: 0;
  margin: 0;
}

.build-diff__body {
  display: grid;
  grid-template-columns: minmax(0, 1fr);
  gap: 24px;

  @media (min-width: 992px) {
    grid-template-columns: 250px minmax(0, 1fr);
  }
}

.build-diff__catalogues {
  display: flex;
  flex-direction: column;
  gap: 8px;
}

.build-diff__catalogue {
  display: flex;
  gap: 12px;
  align-items: center;
  justify-content: space-between;
  min-height: 48px;
  padding: 0 14px;
  font: inherit;
  color: var(--color-text);
  text-align: left;
  background: var(--color-control);
  border: 1px solid var(--color-edge-soft);
  border-radius: var(--radius-control);

  &:hover {
    color: var(--color-lifted);
    background: var(--color-control-hover);
  }
}

.build-diff__catalogue--active {
  color: var(--color-lifted);
  border-color: var(--color-primary);
}

.build-diff__count {
  color: var(--color-text-dim);
}

.build-diff__list {
  display: flex;
  flex-direction: column;
  gap: 8px;
  min-width: 0;
}

.build-diff__filters {
  display: flex;
  flex-wrap: wrap;
  gap: 8px 12px;
  align-items: center;
  margin-bottom: 8px;
}

.build-diff__search {
  flex: 1 1 220px;
  min-width: 0;
  margin: 0;
}
</style>
