<script lang="ts">
export default {
  name: "AdminFeaturesPage",
};
</script>

<script lang="ts" setup>
import { useI18n } from "@/shared/composables/useI18n";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";
import Heading from "@/shared/components/base/Heading/index.vue";
import InlineEditableList from "@/shared/components/InlineEditableList/index.vue";
import BasePill from "@/shared/components/base/Pill/index.vue";
import { BtnVariantsEnum } from "@/shared/components/base/Btn/types";
import TabNavView from "@/shared/components/TabNavView/index.vue";
import TabNavViewAnchorItems from "@/shared/components/TabNavView/AnchorItems/index.vue";
import {
  useAdminFeatures,
  getAdminFeaturesQueryKey,
  enableAdminFeature,
  disableAdminFeature,
  type Feature,
} from "@/services/fyAdminApi";
import { useQueryClient } from "@tanstack/vue-query";
import { useFeatureState } from "@/admin/composables/useFeatureState";

const { t } = useI18n();
const { stateVariant, stateLabel } = useFeatureState();
const { displaySuccess, displayAlert } = useAppNotifications();

const { data: features, isLoading } = useAdminFeatures();
const queryClient = useQueryClient();
const invalidateFeatures = () =>
  queryClient.invalidateQueries({ queryKey: getAdminFeaturesQueryKey() });

interface FeatureItem extends Feature {
  id: string;
}

const featureItems = computed<FeatureItem[]>(() => {
  if (!features.value) return [];
  return features.value.map((f) => ({ ...f, id: f.name }));
});

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

const setActiveTab = (tab: string) => {
  void router.replace({
    query: { ...route.query, tab: tab === "all" ? undefined : tab },
  });
};

const tabItems = computed(() =>
  tabs.map((tab) => ({ id: tab, label: t(`labels.features.tabs.${tab}`) })),
);

const visibleFeatureItems = computed<FeatureItem[]>(() => {
  switch (activeTab.value) {
    case "permanent":
      return featureItems.value.filter((item) => item.permanent);
    case "rollout":
      return featureItems.value.filter((item) => !item.permanent);
    default:
      return featureItems.value;
  }
});

const toggleFeature = async (feature: FeatureItem) => {
  try {
    if (feature.state === "on") {
      await disableAdminFeature(feature.name);
    } else {
      await enableAdminFeature(feature.name);
    }
    void invalidateFeatures();
    displaySuccess({ text: t("messages.features.updated") });
  } catch {
    displayAlert({ text: t("messages.features.error") });
  }
};

// Whole days open, which is what the removal decision is made on. The date
// itself is in the history panel for anyone who wants it.
const daysOpen = (fullyOnSince?: string | null) => {
  if (!fullyOnSince) return null;

  return Math.floor(
    (Date.now() - new Date(fullyOnSince).getTime()) / (1000 * 60 * 60 * 24),
  );
};
</script>

<template>
  <Heading hero>{{ t("headlines.admin.features.index") }}</Heading>

  <p class="text-muted">{{ t("labels.features.registryHint") }}</p>

  <TabNavView :active-key="activeTab">
    <template #nav>
      <TabNavViewAnchorItems
        :items="tabItems"
        :active-id="activeTab"
        @update:active-id="setActiveTab"
      />
    </template>

    <template #content>
      <InlineEditableList
        empty-name="features"
        :loading="isLoading"
        :items="visibleFeatureItems"
        hide-destroy
        hide-edit
      >
        <template #display="{ item }">
          <BasePill :variant="stateVariant(item.state)" uppercase margin-right>
            {{ stateLabel(item.state) }}
          </BasePill>
          <router-link
            :to="{ name: 'admin-feature', params: { name: item.name } }"
            class="feature-name"
            data-test="feature-name"
          >
            {{ item.name }}
          </router-link>
          <BasePill v-if="item.permanent" margin-right>
            {{ t("labels.features.permanent") }}
          </BasePill>
          <BasePill v-if="item.selfServiceUser" margin-right>
            {{ t("labels.features.selfServiceUser") }}
          </BasePill>
          <BasePill v-if="item.selfServiceFleet" margin-right>
            {{ t("labels.features.selfServiceFleet") }}
          </BasePill>
          <BasePill v-if="item.percentageOfActors > 0" margin-right>
            {{ item.percentageOfActors }}%
            {{ t("labels.features.percentageOfActors") }}
          </BasePill>
          <BasePill v-if="item.percentageOfTime > 0" margin-right>
            {{ item.percentageOfTime }}%
            {{ t("labels.features.percentageOfTime") }}
          </BasePill>
          <BasePill v-if="item.groups.length > 0" margin-right>
            {{ item.groups.join(", ") }}
          </BasePill>
          <BasePill v-if="item.actors.length > 0" margin-right>
            {{ item.actors.length }} {{ t("labels.features.actors") }}
          </BasePill>
          <BasePill
            v-if="item.fullyOnSince && !item.permanent"
            margin-right
            data-test="feature-open-for"
          >
            {{
              t("labels.features.openFor", {
                days: daysOpen(item.fullyOnSince),
              })
            }}
          </BasePill>
        </template>

        <template #actions="{ item, mobile }">
          <Btn
            v-tooltip="t('actions.edit')"
            :to="{ name: 'admin-feature', params: { name: item.name } }"
            :variant="BtnVariantsEnum.GHOST"
            :aria-label="`${t('actions.edit')} ${item.name}`"
            data-test="edit-feature"
          >
            <i class="fa-duotone fa-pencil" />
            <span v-if="mobile">{{ t("actions.edit") }}</span>
          </Btn>
          <Btn
            v-tooltip="t('labels.features.toggle')"
            data-test="toggle-feature"
            @click="toggleFeature(item)"
            :variant="BtnVariantsEnum.GHOST"
          >
            <i
              class="fa-duotone fa-power-off"
              :class="item.state === 'on' ? 'text-success' : 'text-muted'"
            />
            <span v-if="mobile">{{ t("labels.features.toggle") }}</span>
          </Btn>
        </template>
      </InlineEditableList>
    </template>
  </TabNavView>
</template>

<style lang="scss" scoped>
.feature-name {
  font-weight: 600;
  margin-right: 0.5rem;
}
</style>
