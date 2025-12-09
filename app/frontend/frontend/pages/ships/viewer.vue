<script lang="ts">
export default {
  name: "ViewerPage",
};
</script>

<script lang="ts" setup>
import { useModels } from "@/services/fyApi";
import Btn from "@/shared/components/base/Btn/index.vue";
import AsyncData from "@/shared/components/AsyncData.vue";
import { useComlink } from "@/shared/composables/useComlink";

const comlink = useComlink();

const { data: models, ...asyncStatus } = useModels({
  perPage: "2",
  q: {
    slugIn: ["corsair", "buccaneer"],
  },
});

const holoModels = computed(() => {
  return models.value?.items
    .map((model) => {
      return {
        path: model.media.holo?.url,
        length: model.metrics.fleetchartOffsetLength,
      };
    })
    .filter((model) => model.path);
});

const openModal = () => {
  comlink.emit("open-modal", {
    component: () => import("@/shared/components/HoloViewer/Modal/index.vue"),
    fullscreen: true,
    props: {
      models: holoModels.value,
    },
  });
};
</script>

<template>
  <AsyncData :async-status="asyncStatus">
    <template #resolved>
      <Btn @click="openModal">Open HoloViewer Modal</Btn>
    </template>
  </AsyncData>
</template>
