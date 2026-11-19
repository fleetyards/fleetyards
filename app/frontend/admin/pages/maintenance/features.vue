<script lang="ts">
export default {
  name: "AdminFeaturesPage",
};
</script>

<script lang="ts" setup>
import { useI18n } from "@/shared/composables/useI18n";
import Heading from "@/shared/components/base/Heading/index.vue";
import BasePill from "@/shared/components/base/Pill/index.vue";
import Btn from "@/shared/components/base/Btn/index.vue";
import BtnGroup from "@/shared/components/base/BtnGroup/index.vue";
import FormInput from "@/shared/components/base/FormInput/index.vue";
import Loader from "@/shared/components/Loader/index.vue";
import { useAdminFeatures, type Feature } from "@/services/fyAdminApi";
import { useFeatureState } from "@/admin/composables/useFeatureState";

const { t, l, timeDistance } = useI18n();
const { stateVariant, stateLabel, summaryParts, daysOpen } = useFeatureState();

const { data: features, isLoading, isError } = useAdminFeatures();

const tabs = ["all", "rollout", "permanent"] as const;

type FeatureTab = (typeof tabs)[number];

const route = useRoute();
const router = useRouter();

function isFeatureTab(value: unknown): value is FeatureTab {
  return tabs.includes(value as FeatureTab);
}

const activeTab = computed<FeatureTab>(() => {
  const fromQuery = route.query.tab;

  return isFeatureTab(fromQuery) ? fromQuery : "all";
});

const setActiveTab = (tab: FeatureTab) => {
  void router.replace({
    query: { ...route.query, tab: tab === "all" ? undefined : tab },
  });
};

const inTab = (feature: Feature, tab: FeatureTab) => {
  switch (tab) {
    case "permanent":
      return feature.permanent;
    case "rollout":
      return !feature.permanent;
    default:
      return true;
  }
};

const tabCount = (tab: FeatureTab) =>
  (features.value ?? []).filter((feature) => inTab(feature, tab)).length;

const filter = ref<string>();

const visibleFeatures = computed(() => {
  const needle = filter.value?.trim().toLowerCase();

  return (features.value ?? []).filter(
    (feature) =>
      inTab(feature, activeTab.value) &&
      (!needle || feature.name.toLowerCase().includes(needle)),
  );
});

const kind = (feature: Feature) => {
  const label = feature.permanent
    ? t("labels.features.permanent")
    : t("labels.features.tabs.rollout");
  const days = feature.state === "on" ? daysOpen(feature) : null;

  return days === null
    ? label
    : `${label} · ${t("labels.features.openFor", { count: days })}`;
};

const onFor = (feature: Feature) => {
  const parts = summaryParts(feature);

  if (!parts.length) return t("labels.features.nobody");

  return parts.map((part) => part.label).join(" · ");
};

const emptyText = computed(() => {
  if (isError.value) return t("labels.features.loadError");
  if (!features.value?.length) return t("labels.features.emptyRegistry");

  return t("labels.features.noMatches");
});
</script>

<template>
  <div class="features-page">
    <Heading hero>{{ t("headlines.admin.features.index") }}</Heading>

    <p class="features-page__hint">{{ t("labels.features.registryHint") }}</p>

    <div class="features-page__toolbar">
      <FormInput
        v-model="filter"
        name="features-filter"
        :label="t('labels.features.filter')"
        :placeholder="t('labels.features.filter')"
        no-label
        inline
        standalone
        clearable
        class="features-page__filter"
        data-test="features-filter"
      />
      <div class="features-page__tabs">
        <BtnGroup segmented block>
          <Btn
            v-for="tab in tabs"
            :key="tab"
            :active="activeTab === tab"
            :data-test="`features-tab-${tab}`"
            @click="setActiveTab(tab)"
          >
            {{ t(`labels.features.tabs.${tab}`) }}
            <span class="features-page__count">· {{ tabCount(tab) }}</span>
          </Btn>
        </BtnGroup>
      </div>
    </div>

    <Loader v-if="isLoading" />

    <p
      v-else-if="!visibleFeatures.length"
      class="features-page__empty"
      data-test="features-empty"
    >
      {{ emptyText }}
    </p>

    <div v-else class="features-table">
      <!-- Column labels for sighted readers only: each row is a link whose
           text already reads in order, and table roles on a link would hide
           that it is one. -->
      <div class="features-table__head" aria-hidden="true">
        <span>{{ t("labels.features.columns.state") }}</span>
        <span>{{ t("labels.features.columns.flag") }}</span>
        <span>{{ t("labels.features.onFor") }}</span>
        <span>{{ t("labels.features.columns.lastChange") }}</span>
      </div>

      <ul
        class="features-table__rows"
        :aria-label="t('headlines.admin.features.index')"
      >
        <li v-for="feature in visibleFeatures" :key="feature.name">
          <router-link
            :to="{ name: 'admin-feature', params: { name: feature.name } }"
            class="features-table__row"
            data-test="feature-row"
          >
            <span>
              <BasePill :variant="stateVariant(feature.state)" uppercase>
                {{ stateLabel(feature.state) }}
              </BasePill>
            </span>
            <span class="features-table__flag">
              <span class="features-table__name" data-test="feature-name">
                {{ feature.name }}
              </span>
              <span class="features-table__kind" data-test="feature-kind">
                {{ kind(feature) }}
              </span>
            </span>
            <span class="features-table__on-for" data-test="feature-on-for">
              {{ onFor(feature) }}
            </span>
            <span class="features-table__changed">
              <time
                v-if="feature.lastChangedAt"
                :datetime="feature.lastChangedAt"
                :title="l(feature.lastChangedAt)"
              >
                {{ timeDistance(feature.lastChangedAt) }}
              </time>
              <template v-if="feature.lastChangedBy">
                · {{ feature.lastChangedBy }}
              </template>
            </span>
            <i
              class="fa-light fa-chevron-right features-table__chevron"
              aria-hidden="true"
            />
          </router-link>
        </li>
      </ul>
    </div>
  </div>
</template>

<style lang="scss" scoped>
.features-page {
  display: flex;
  flex-direction: column;
  gap: 1.25rem;
}

.features-page__hint,
.features-page__empty {
  margin: 0;
  color: var(--color-text-dim);
}

.features-page__toolbar {
  display: flex;
  flex-wrap: wrap;
  align-items: center;
  justify-content: space-between;
  gap: 0.75rem 1rem;
}

.features-page__filter {
  flex: 0 1 22rem;
  min-width: 14rem;
}

.features-page__tabs {
  flex: 1 1 100%;

  @media (min-width: $desktop-breakpoint) {
    flex: 0 0 auto;
  }
}

// Three segments with counts do not fit a phone; the list below counts itself.
.features-page__count {
  display: none;

  @media (min-width: $desktop-breakpoint) {
    display: inline;
  }
}

.features-table {
  display: flex;
  flex-direction: column;
  gap: 8px;
}

.features-table__rows {
  display: flex;
  flex-direction: column;
  gap: 8px;
  list-style: none;
  margin: 0;
  padding: 0;
}

.features-table__head,
.features-table__row {
  display: grid;
  grid-template-columns: minmax(0, 1fr) auto;
  gap: 0.5rem 1rem;
  align-items: center;

  @media (min-width: $desktop-breakpoint) {
    grid-template-columns: 130px minmax(0, 1.1fr) minmax(0, 2fr) 170px 1rem;
  }
}

.features-table__head {
  display: none;
  padding: 0 1.125rem;
  font-family: "Orbitron", sans-serif;
  font-size: 10px;
  letter-spacing: 0.16em;
  text-transform: uppercase;
  color: var(--color-text-dim);

  @media (min-width: $desktop-breakpoint) {
    display: grid;
  }
}

.features-table__row {
  min-height: 56px;
  padding: 0.5rem 1.125rem;
  color: var(--color-text);
  text-decoration: none;
  background: var(--color-control);
  border: 1px solid var(--color-edge-soft);
  border-radius: 12px;
  transition: background-color 150ms ease;

  &:hover,
  &:focus-visible {
    color: var(--color-text);
    background: var(--color-control-hover);
  }

  > * {
    grid-column: 1 / -1;

    @media (min-width: $desktop-breakpoint) {
      grid-column: auto;
    }
  }
}

.features-table__flag {
  display: flex;
  flex-direction: column;
  gap: 0.125rem;
  min-width: 0;
}

.features-table__name {
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
  font-weight: 600;
  color: var(--color-lifted);
}

.features-table__kind,
.features-table__changed {
  font-size: 13px;
  color: var(--color-text-dim);
}

.features-table__on-for {
  font-size: 14px;
}

.features-table__chevron {
  display: none;
  color: var(--color-text-dim);

  @media (min-width: $desktop-breakpoint) {
    display: block;
  }
}
</style>
