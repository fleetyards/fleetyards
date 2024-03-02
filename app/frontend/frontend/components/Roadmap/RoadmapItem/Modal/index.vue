<template>
  <Modal v-if="item" :title="item.name" class="roadmap-modal">
    <small class="roadmap-modal-subheadline">
      <div class="text-muted">
        <span>
          {{ t("labels.roadmap.lastUpdate") }}:
          {{ item.lastVersionChangedAtLabel }}
        </span>
        <i class="far fa-clock" />
      </div>
      <div v-if="item.committed" class="roadmap-item-committed">
        <span class="text-muted">{{ t("labels.roadmap.committed") }}</span>
        <i class="far fa-check" />
      </div>
    </small>
    <div class="roadmap-modal-image" @click="openImage">
      <img :src="storeImage" :alt="item.name" />
    </div>
    <p>{{ description }}</p>
    <ul v-if="item.lastVersion">
      <li v-for="(update, index) in updates" :key="index">
        <template v-if="update.key === 'release' && !update.old">
          {{
            t("labels.roadmap.lastVersion.addedToRelease", {
              release: update.new,
            })
          }}
        </template>
        <template v-else-if="update.key === 'commited'">
          {{ t(`labels.roadmap.lastVersion.committed`) }}
        </template>
        <template v-else-if="update.key === 'active'">
          {{ t(`labels.roadmap.lastVersion.active.${update.change}`) }}
        </template>
        <template v-else>
          {{
            t(`labels.roadmap.lastVersion.${update.key}`, {
              old: update.old,
              new: update.new,
              count: update.count,
            })
          }}
        </template>
      </li>
    </ul>

    <template #footer>
      <div class="float-sm-right">
        <Btn v-if="item.model" :inline="true" @click="openDetail">
          {{ t("actions.showMore") }}
        </Btn>
      </div>
    </template>
  </Modal>
</template>

<script lang="ts" setup>
import Modal from "@/shared/components/AppModal/Inner/index.vue";
import Btn from "@/shared/components/base/Btn/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import { useComlink } from "@/shared/composables/useComlink";
import type { RoadmapItem } from "@/services/fyApi";

type Props = {
  item: RoadmapItem;
};

const props = defineProps<Props>();

const { t } = useI18n();

const storeImage = computed(() => {
  if (props.item.storeImage) {
    return props.item.storeImage;
  }

  return `https://robertsspaceindustries.com${props.item.image}`;
});

const description = computed(() => {
  if (props.item.body) {
    return props.item.body;
  }

  return props.item.description;
});

const updates = computed(() => {
  if (!props.item) {
    return [];
  }

  const { lastVersion } = props.item;

  if (!lastVersion) {
    return [];
  }

  const changesetKeys = [
    "committed",
    "release",
    "active",
  ] as (keyof typeof lastVersion)[];

  return changesetKeys
    .filter((key) => lastVersion[key])
    .map((key) => {
      const change = lastVersion[key] || [];
      const count = parseInt(change[1] - change[0], 10);

      return {
        key,
        change: count < 0 ? "decreased" : "increased",
        old: lastVersion[key][0],
        new: lastVersion[key][1],
        count,
      };
    })
    .filter(
      (update) =>
        update.key !== "commited" || (update.key === "commited" && update.old),
    )
    .filter(
      (update) =>
        update.key !== "active" || (update.key === "active" && update.old),
    );
});

const openImage = () => {
  window.open(storeImage.value, "_blank").focus();
};

const comlink = useComlink();

const router = useRouter();

const openDetail = () => {
  comlink.emit("close-modal");

  router
    .push({
      name: "model",
      params: {
        slug: props.item.model?.slug,
      },
    })
    // eslint-disable-next-line @typescript-eslint/no-empty-function
    .catch(() => {});
};
</script>

<script lang="ts">
export default {
  name: "RoadmapItemModal",
};
</script>
