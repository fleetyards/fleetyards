<script lang="ts">
export default {
  name: "AdminFeaturePage",
};
</script>

<script lang="ts" setup>
import { useAdminFeature } from "@/services/fyAdminApi";
import AsyncData from "@/shared/components/AsyncData.vue";
import BreadCrumbs from "@/shared/components/BreadCrumbs/index.vue";
import { type Crumb } from "@/shared/components/BreadCrumbs/types";
import Heading from "@/shared/components/base/Heading/index.vue";
import BasePill from "@/shared/components/base/Pill/index.vue";
import Btn from "@/shared/components/base/Btn/index.vue";
import BtnConfirm from "@/shared/components/base/BtnConfirm/index.vue";
import {
  BtnSizesEnum,
  BtnTonesEnum,
  BtnVariantsEnum,
} from "@/shared/components/base/Btn/types";
import Panel from "@/shared/components/base/Panel/index.vue";
import PanelHeading from "@/shared/components/base/Panel/Heading/index.vue";
import PanelBody from "@/shared/components/base/Panel/Body/index.vue";
import OnFor from "@/admin/components/Features/OnFor/index.vue";
import RolloutPanel from "@/admin/components/Features/RolloutPanel/index.vue";
import ActorsPanel from "@/admin/components/Features/ActorsPanel/index.vue";
import FeatureHistory from "@/admin/components/FeatureHistory/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import { useFeatureState } from "@/admin/composables/useFeatureState";
import { useFeatureActions } from "@/admin/composables/useFeatureActions";

const HISTORY_PREVIEW = 5;

const route = useRoute();
const { t, l, timeDistance } = useI18n();
const { stateVariant, stateLabel, daysOpen } = useFeatureState();

const featureName = computed(() => route.params.name as string);

const { data: feature, ...asyncStatus } = useAdminFeature(featureName);

const actions = useFeatureActions(featureName);

const isOn = computed(() => feature.value?.state === "on");
const isOff = computed(() => feature.value?.state === "off");

const openDays = computed(() =>
  feature.value && isOn.value ? daysOpen(feature.value) : null,
);

const crumbs = computed<Crumb[]>(() => [
  {
    to: { name: "admin-features" },
    label: t("headlines.admin.features.index"),
  },
]);
</script>

<template>
  <AsyncData :async-status="asyncStatus">
    <template #resolved>
      <div v-if="feature" class="feature-page">
        <header class="feature-page__header">
          <div class="feature-page__title">
            <BreadCrumbs :crumbs="crumbs" />
            <Heading hero data-test="feature-heading">
              <span class="feature-page__name">
                {{ feature.name }}
                <BasePill
                  :variant="stateVariant(feature.state)"
                  uppercase
                  data-test="feature-state"
                >
                  {{ stateLabel(feature.state) }}
                </BasePill>
                <BasePill v-if="feature.permanent">
                  {{ t("labels.features.permanent") }}
                </BasePill>
              </span>
            </Heading>
            <p class="feature-page__meta" data-test="feature-last-changed">
              <template v-if="openDays !== null">
                {{ t("labels.features.openFor", { count: openDays }) }} ·
              </template>
              <template v-if="feature.lastChangedAt">
                <time
                  :datetime="feature.lastChangedAt"
                  :title="l(feature.lastChangedAt)"
                >
                  {{
                    t("labels.features.lastChanged", {
                      date: timeDistance(feature.lastChangedAt),
                    })
                  }}
                </time>
                <template v-if="feature.lastChangedSource">
                  ·
                  {{
                    t(`labels.features.sources.${feature.lastChangedSource}`)
                  }}
                  <template v-if="feature.lastChangedBy">
                    {{
                      t("labels.features.historyBy", {
                        actor: feature.lastChangedBy,
                      })
                    }}
                  </template>
                </template>
              </template>
            </p>
          </div>

          <div class="feature-page__actions">
            <Btn
              v-if="!isOn"
              :size="BtnSizesEnum.MD"
              :loading="actions.busy.value"
              data-test="feature-enable"
              @click="actions.setGlobal(true)"
            >
              <i class="fa-light fa-globe" aria-hidden="true" />
              {{ t("labels.features.openToEveryone") }}
            </Btn>
            <BtnConfirm
              v-if="!isOff"
              :size="BtnSizesEnum.MD"
              :tone="BtnTonesEnum.DANGER"
              :variant="BtnVariantsEnum.GHOST"
              :question="t('labels.features.turnOffQuestion')"
              :disabled="actions.busy.value"
              data-test="feature-disable"
              @confirm="actions.setGlobal(false)"
            >
              <i class="fa-light fa-power-off" aria-hidden="true" />
              {{ t("labels.features.turnOff") }}
            </BtnConfirm>
          </div>
        </header>

        <OnFor :feature="feature" />

        <div class="feature-page__columns">
          <RolloutPanel :feature="feature" class="feature-page__main" />

          <Panel :outer-spacing="false" class="feature-page__aside">
            <PanelHeading>
              {{ t("headlines.admin.features.history") }}
            </PanelHeading>
            <PanelBody>
              <FeatureHistory :name="feature.name" :limit="HISTORY_PREVIEW" />
            </PanelBody>
          </Panel>
        </div>

        <ActorsPanel :feature="feature" />
      </div>
    </template>
  </AsyncData>
</template>

<style lang="scss" scoped>
.feature-page {
  display: flex;
  flex-direction: column;
  gap: 1.5rem;
}

.feature-page__header {
  display: flex;
  flex-wrap: wrap;
  align-items: flex-end;
  justify-content: space-between;
  gap: 1rem 1.5rem;
}

.feature-page__title {
  display: flex;
  flex-direction: column;
  gap: 0.5rem;
  min-width: 0;
}

.feature-page__name {
  display: flex;
  flex-wrap: wrap;
  align-items: center;
  gap: 0.75rem;
  overflow-wrap: anywhere;
}

.feature-page__meta {
  margin: 0;
  font-size: 14px;
  color: var(--color-text-dim);
}

.feature-page__actions {
  display: flex;
  flex-wrap: wrap;
  gap: 0.5rem;
}

.feature-page__columns {
  display: flex;
  flex-wrap: wrap;
  align-items: flex-start;
  gap: 1.5rem;
}

.feature-page__main {
  flex: 999 1 560px;
  min-width: 0;
}

.feature-page__aside {
  flex: 1 1 320px;
  min-width: 0;
}
</style>
