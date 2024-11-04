<script lang="ts">
export default {
  name: "RoadmapItemModal",
};
</script>

<script lang="ts" setup>
import Modal from "@/shared/components/AppModal/Inner/index.vue";
import Btn from "@/shared/components/base/Btn/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import { useComlink } from "@/shared/composables/useComlink";
import type { RoadmapItem } from "@/services/fyApi";
import RoadmapItemUpdates from "@/frontend/components/Roadmap/RoadmapItem/Updates/index.vue";
import RoadmapItemStatus from "@/frontend/components/Roadmap/RoadmapItem/Status/index.vue";

type Props = {
  item: RoadmapItem;
};

const props = defineProps<Props>();

const { t } = useI18n();

const storeImage = computed(() => {
  if (props.item.media.storeImage?.medium) {
    return props.item.media.storeImage.medium;
  }

  if (!props.item.image) {
    return undefined;
  }

  return `https://robertsspaceindustries.com${props.item.image}`;
});

const description = computed(() => {
  if (props.item.body) {
    return props.item.body;
  }

  return props.item.description;
});

const openImage = () => {
  window.open(storeImage.value, "_blank")?.focus();
};

const comlink = useComlink();

const router = useRouter();

const openDetail = () => {
  comlink.emit("close-modal");

  router
    .push({
      name: "ship",
      params: {
        slug: props.item.model?.slug,
      },
    })
    // eslint-disable-next-line @typescript-eslint/no-empty-function
    .catch(() => {});
};
</script>

<template>
  <Modal v-if="item" :title="item.name" class="roadmap-modal">
    <RoadmapItemStatus :item="item" :compact="false" />
    <br />
    <div v-if="storeImage" class="roadmap-modal-image" @click="openImage">
      <img :src="storeImage" :alt="item.name" />
    </div>
    <p>{{ description }}</p>
    <RoadmapItemUpdates :item="item" />

    <template #footer>
      <div class="float-sm-right">
        <Btn v-if="item.model" :inline="true" @click="openDetail">
          {{ t("actions.showMore") }}
        </Btn>
      </div>
    </template>
  </Modal>
</template>

<style lang="scss" scoped>
@import "index";
</style>
