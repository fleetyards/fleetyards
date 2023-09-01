<template>
  <AsyncData :async-status="asyncStatus">
    <template v-if="celestialObject" #resolved>
      <div class="row">
        <div class="col-12">
          <BreadCrumbs :crumbs="crumbs" />
          <h1 v-if="celestialObject">
            {{ celestialObject.name }}
            <small class="text-muted">{{ celestialObject.designation }}</small>
          </h1>
        </div>
      </div>
      <div class="row">
        <div class="col-12 col-lg-8">
          <blockquote v-if="celestialObject.description" class="description">
            <p v-html="celestialObject.description" />
          </blockquote>
        </div>
        <div class="col-12 col-lg-4">
          <Panel>
            <CelestialObjectMetrics
              :celestial-object="celestialObject"
              padding
            />
          </Panel>
        </div>
      </div>
      <div class="row">
        <div
          v-if="celestialObject && celestialObject.moons?.length"
          class="col-12"
        >
          <h2>{{ t("headlines.moons") }}</h2>
          <transition-group name="fade-list" class="row" tag="div" appear>
            <div
              v-for="moon in celestialObject.moons"
              :key="moon.slug"
              class="col-12 col-md-6 col-lg-3 fade-list-item"
            >
              <CelestialObjectItem
                :item="moon"
                :route="{
                  name: 'celestial-object',
                  params: {
                    starsystem: celestialObject.starsystem?.slug,
                    slug: moon.slug,
                  },
                }"
              />
            </div>
          </transition-group>
        </div>
      </div>
      <StationsList :celestial-object-slug="celestialObject.slug" />
    </template>
  </AsyncData>
</template>

<script lang="ts" setup>
import Panel from "@/shared/components/Panel/index.vue";
import StationsList from "@/frontend/components/CelestialObjects/StationsList/index.vue";
import CelestialObjectItem from "@/frontend/components/CelestialObjects/Item/index.vue";
import BreadCrumbs from "@/shared/components/BreadCrumbs/index.vue";
import type { Crumb } from "@/shared/components/BreadCrumbs/index.vue";
import AsyncData from "@/shared/components/AsyncData.vue";
import CelestialObjectMetrics from "@/frontend/components/CelestialObjects/Metrics/index.vue";
import { useMetaInfo } from "@/shared/composables/useMetaInfo";
import { useI18n } from "@/frontend/composables/useI18n";
import { useApiClient } from "@/frontend/composables/useApiClient";
import { useQuery } from "@tanstack/vue-query";
import { useRoute } from "vue-router";

const { t, currentLocale } = useI18n();

const { updateMetaInfo } = useMetaInfo(t);

const crumbs = computed(() => {
  if (!celestialObject.value) {
    return undefined;
  }

  const crumbs: Crumb[] = [
    {
      to: {
        name: "starsystems",
        hash: `#${celestialObject.value.starsystem?.slug}`,
      },
      label: t("nav.starsystems"),
    },
    {
      to: {
        name: "starsystem",
        params: {
          slug: celestialObject.value.starsystem?.slug,
        },
        hash: `#${celestialObject.value.slug}`,
      },
      label: celestialObject.value.starsystem?.name,
    },
  ];

  if (celestialObject.value.parent) {
    crumbs.push({
      to: {
        name: "celestial-object",
        params: {
          starsystem: celestialObject.value.starsystem?.slug,
          slug: celestialObject.value.parent.slug,
        },
      },
      label: celestialObject.value.parent.name,
    });
  }

  return crumbs;
});

const { celestialObjects: celestialObjectsService } = useApiClient();

const route = useRoute();

const { data: celestialObject, ...asyncStatus } = useQuery({
  queryKey: ["celestialObject", route.params.slug],
  queryFn: () =>
    celestialObjectsService.detail({
      slug: route.params.slug?.toString(),
    }),
});

watch(
  () => celestialObject.value,
  () => {
    if (!celestialObject.value) {
      return;
    }

    updateMetaInfo({
      title: t("title.celestialObject", {
        celestialObject: celestialObject.value.name,
        starsystem: celestialObject.value.starsystem?.name || "",
      }),
      description: celestialObject.value.description || undefined,
      image: celestialObject.value.media.storeImage?.medium || undefined,
      type: "article",
    });
  },
);
</script>

<script lang="ts">
export default {
  name: "CelestialObjectPage",
};
</script>
