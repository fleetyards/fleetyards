<script lang="ts">
export default {
  name: "ComponentPage",
};
</script>

<script lang="ts" setup>
import AsyncData from "@/shared/components/AsyncData.vue";
import Heading from "@/shared/components/base/Heading/index.vue";
import { HeadingLevelEnum } from "@/shared/components/base/Heading/types";
import Panel from "@/shared/components/base/Panel/index.vue";
import PanelHeading from "@/shared/components/base/Panel/Heading/index.vue";
import PanelBody from "@/shared/components/base/Panel/Body/index.vue";
import Chip from "@/shared/components/base/Chip/index.vue";
import { ChipStatesEnum } from "@/shared/components/base/Chip/types";
import { useI18n } from "@/shared/composables/useI18n";
import { useMetaInfo } from "@/shared/composables/useMetaInfo";
import { useComponentStats } from "@/frontend/composables/useComponentStats";
import { useComponent as useComponentQuery } from "@/services/fyApi";

const { t } = useI18n();
const { updateMetaInfo } = useMetaInfo();
const route = useRoute();

const slug = computed(() => route.params.slug as string);

const { data: component, ...asyncStatus } = useComponentQuery(slug);

const stats = useComponentStats(component);

// Whatever the site holds about the item itself, as opposed to what it does.
// `size` and `grade` come back as bare strings, and a grade reads as a letter.
const identity = computed(() => {
  const value = component.value;
  if (!value) return [];

  return [
    { label: t("labels.hardpoint.size"), value: value.size },
    { label: t("labels.component.grade"), value: value.gradeLabel },
    { label: t("labels.component.itemClass"), value: value.itemClassLabel },
    { label: t("labels.component.category"), value: value.category },
    { label: t("labels.component.subType"), value: value.subType },
  ].filter((entry) => entry.value);
});

watch(
  component,
  (value) => {
    if (!value) return;

    updateMetaInfo({
      title: t("title.component", { name: value.name }),
      description: value.description ?? undefined,
    });
  },
  { immediate: true },
);
</script>

<template>
  <AsyncData :async-status="asyncStatus">
    <template #resolved>
      <div v-if="component">
        <Heading :level="HeadingLevelEnum.H1">
          {{ component.name }}
          <!-- A component the current build no longer describes. It stays
               reachable because a ship's older loadout points at it, so it says
               what it is rather than presenting stale figures as current. -->
          <Chip v-if="component.retired" :state="ChipStatesEnum.EXCLUDED">
            {{ t("labels.component.retired") }}
          </Chip>
        </Heading>

        <p v-if="component.manufacturer" class="component-page__manufacturer">
          {{ component.manufacturer.name }}
        </p>

        <p v-if="component.description" class="component-page__description">
          {{ component.description }}
        </p>

        <Panel v-if="identity.length">
          <PanelHeading>{{ t("headlines.component.identity") }}</PanelHeading>
          <PanelBody>
            <dl class="component-page__stats">
              <template v-for="entry in identity" :key="entry.label">
                <dt>{{ entry.label }}</dt>
                <dd>{{ entry.value }}</dd>
              </template>
            </dl>
          </PanelBody>
        </Panel>

        <Panel v-if="stats.length">
          <PanelHeading>{{ t("headlines.component.metrics") }}</PanelHeading>
          <PanelBody>
            <dl class="component-page__stats">
              <template v-for="stat in stats" :key="stat.label">
                <dt>{{ stat.label }}</dt>
                <dd>{{ stat.value }}</dd>
              </template>
            </dl>
          </PanelBody>
        </Panel>

        <!-- Said out loud rather than left as an empty panel: 301 components
             carry no metric keys at all, so nothing to show is the honest
             answer for them rather than a sign something failed to load. -->
        <Panel v-else>
          <PanelBody>
            {{ t("labels.component.noMetrics") }}
          </PanelBody>
        </Panel>

        <Panel v-if="component.requiredTags?.length">
          <PanelHeading>{{
            t("headlines.component.requiredTags")
          }}</PanelHeading>
          <PanelBody>
            <Chip v-for="tag in component.requiredTags" :key="tag">
              {{ tag }}
            </Chip>
          </PanelBody>
        </Panel>
      </div>
    </template>
  </AsyncData>
</template>

<style lang="scss" scoped>
@import "index";
</style>
