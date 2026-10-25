<script lang="ts">
export default {
  name: "ItemViews",
};
</script>

<script lang="ts" setup>
import MetricsCard from "@/frontend/components/Models/MetricsCard/index.vue";
import LazyImage from "@/shared/components/LazyImage/index.vue";
import { type ItemMedia, type MediaFile } from "@/services/fyApi";
import { useGallery } from "@/shared/composables/useGallery";
import { useI18n } from "@/shared/composables/useI18n";

type Props = {
  media?: ItemMedia;
  name: string;
};

const props = defineProps<Props>();

const VIEWS = [
  "angledView",
  "angledRearView",
  "frontView",
  "rearView",
  "portView",
  "starboardView",
  "topView",
  "bottomView",
] as const;

const { t } = useI18n();

const views = computed(() =>
  VIEWS.flatMap((key) => {
    const file: MediaFile | null | undefined = props.media?.[key];

    return file?.url ? [{ key, file }] : [];
  }),
);

useGallery(".item-views__grid", ".gallery-image");
</script>

<template>
  <MetricsCard
    v-if="views.length"
    :title="t('labels.metrics.views')"
    variant="slim"
    data-test="item-views"
  >
    <div class="item-views__grid">
      <LazyImage
        v-for="view in views"
        :key="view.key"
        :src="view.file.mediumUrl || view.file.url"
        :href="view.file.url"
        :width="view.file.width ?? undefined"
        :height="view.file.height ?? undefined"
        :alt="`${name} – ${t(`labels.model.${view.key}`)}`"
        :caption="t(`labels.model.${view.key}`)"
        transparent
        gallery
      />
    </div>
  </MetricsCard>
</template>

<style lang="scss" scoped>
@import "index";
</style>
