<template>
  <AsyncData :async-status="asyncStatus">
    <template #resolved>
      <div class="row">
        <div class="col-12">
          <BreadCrumbs :crumbs="crumbs" />
          <h1 v-if="starsystem">
            {{ t("headlines.starsystem", { starsystem: starsystem.name }) }}
          </h1>
        </div>
      </div>
      <div v-if="starsystem" class="row">
        <div class="col-12 col-lg-8">
          <blockquote v-if="starsystem.description" class="description">
            <p v-html="starsystem.description" />
          </blockquote>
        </div>
        <div class="col-12 col-lg-4">
          <Panel>
            <StarsystemBaseMetrics :starsystem="starsystem" padding />
            <StarsystemLevelsMetrics :starsystem="starsystem" padding />
          </Panel>
        </div>
      </div>
      <CelestialObjectsList :starsystem-slug="String(route.params.slug)" />
    </template>
  </AsyncData>
</template>

<script lang="ts" setup>
import Panel from "@/shared/components/Panel/index.vue";
import CelestialObjectsList from "@/frontend/components/CelestialObjects/List/index.vue";
import StarsystemBaseMetrics from "@/frontend/components/Starsystems/BaseMetrics/index.vue";
import StarsystemLevelsMetrics from "@/frontend/components/Starsystems/LevelsMetrics/index.vue";
import BreadCrumbs from "@/shared/components/BreadCrumbs/index.vue";
import type { Crumb } from "@/shared/components/BreadCrumbs/index.vue";
import AsyncData from "@/shared/components/AsyncData.vue";
import { useMetaInfo } from "@/shared/composables/useMetaInfo";
import { useI18n } from "@/shared/composables/useI18n";
import { useApiClient } from "@/frontend/composables/useApiClient";
import { useQuery } from "@tanstack/vue-query";

const { t, currentLocale } = useI18n();

const { updateMetaInfo } = useMetaInfo(t);

const { starsystems: starsystemsService } = useApiClient();

const route = useRoute();

const crumbs = computed<Crumb[] | undefined>(() => {
  if (!starsystem.value) {
    return undefined;
  }

  return [
    {
      to: {
        name: "starsystems",
        hash: `#${starsystem.value.slug}`,
      },
      label: t("nav.starsystems"),
    },
  ];
});

const { data: starsystem, ...asyncStatus } = useQuery({
  queryKey: ["starsystem", route.params.slug],
  queryFn: () =>
    starsystemsService.starsystem({
      slug: String(route.params.slug),
    }),
});

watch(
  () => starsystem.value,
  () => {
    if (!starsystem.value) {
      return;
    }

    updateMetaInfo({
      title: t("title.starsystem", { starsystem: starsystem.value.name }),
      description: starsystem.value.description || undefined,
      image: starsystem.value.media?.storeImage?.medium || undefined,
      type: "article",
    });
  },
);
</script>

<script lang="ts">
export default {
  name: "StarsystemPage",
};
</script>
