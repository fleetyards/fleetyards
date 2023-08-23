<template>
  <Modal>
    <template #title>
      <h1>
        <template v-if="hangarStore.empty">
          {{ t("headlines.hangarGuideEmpty") }}
          <small class="text-muted">
            {{ t("sublines.hangarGuide.headline") }}
          </small>
        </template>
        <template v-else>
          {{ t("headlines.hangarGuide") }}
        </template>
      </h1>
    </template>

    <h2>{{ t("sublines.hangarGuide.add") }}</h2>
    <div class="hangar-guide-topic">
      <div class="hangar-guide-text">
        <p v-html="t('texts.hangarGuide.add')" />
        <div class="hangar-guide-highlight">
          {{ t("texts.hangarGuide.icon") }}
          <i class="fal fa-bookmark" />
        </div>
      </div>
      <div class="hangar-guide-video">
        <VideoEmbed :video="videos.add" />
      </div>
    </div>
    <hr />
    <h2>{{ t("sublines.hangarGuide.edit") }}</h2>
    <div class="hangar-guide-topic">
      <div class="hangar-guide-text">
        <p v-html="t('texts.hangarGuide.edit')" />
        <div class="hangar-guide-highlight">
          {{ t("texts.hangarGuide.icon") }}
          <i class="fa fa-pencil" />
        </div>
      </div>
      <div class="hangar-guide-video">
        <VideoEmbed :video="videos.edit" class="hangar-guide-video" />
      </div>
    </div>
    <hr />
    <h2>{{ t("sublines.hangarGuide.wishlist") }}</h2>
    <div class="hangar-guide-topic">
      <div class="hangar-guide-text">
        <p v-html="t('texts.hangarGuide.wishlist')" />
        <div class="hangar-guide-highlight">
          {{ t("texts.hangarGuide.icon") }}
          <i class="fal fa-bookmark" />
        </div>
      </div>
      <div class="hangar-guide-video">
        <VideoEmbed :video="videos.edit" class="hangar-guide-video" />
      </div>
    </div>
    <hr />
    <h2>{{ t("sublines.hangarGuide.public") }}</h2>
    <div class="hangar-guide-topic">
      <div class="hangar-guide-text">
        <p v-html="t('texts.hangarGuide.public')" />
      </div>
      <div class="hangar-guide-video">
        <VideoEmbed :video="videos.public" class="hangar-guide-video" />
      </div>
    </div>
    <hr />
    <h2>{{ t("sublines.hangarGuide.fleetchart") }}</h2>
    <div class="hangar-guide-topic">
      <div class="hangar-guide-text">
        <p v-html="t('texts.hangarGuide.fleetchart')" />
      </div>
      <div class="hangar-guide-video">
        <VideoEmbed :video="videos.fleetchart" />
      </div>
    </div>
    <hr />
    <h2>{{ t("sublines.hangarGuide.groups") }}</h2>
    <div class="hangar-guide-topic">
      <div class="hangar-guide-text">
        <p v-html="t('texts.hangarGuide.groups.add')" />
        <p v-html="t('texts.hangarGuide.groups.edit')" />
      </div>
      <div class="hangar-guide-video">
        <VideoEmbed :video="videos.groups" class="hangar-guide-video" />
      </div>
    </div>
  </Modal>
</template>

<script lang="ts" setup>
import Modal from "@/shared/components/AppModal/Inner/index.vue";
import { useI18n } from "@/frontend/composables/useI18n";
import VideoEmbed from "@/frontend/core/components/Video/index.vue";
import { useHangarStore } from "@/frontend/stores/hangar";

const hangarStore = useHangarStore();

const { t } = useI18n();

type VideoList = {
  [key: string]: TVideo;
};

const videos = computed<VideoList>(() => ({
  add: {
    videoId: "eWS8korWw58",
    type: "youtube",
    url: "https://www.youtube-nocookie.com/embed/eWS8korWw58",
  },
  edit: {
    videoId: "6IR251NRb54",
    type: "youtube",
    url: "https://www.youtube-nocookie.com/embed/6IR251NRb54",
  },
  wishlist: {
    videoId: "eJ5wSE2Yy6w",
    type: "youtube",
    url: "https://www.youtube-nocookie.com/embed/eJ5wSE2Yy6w",
  },
  public: {
    videoId: "_FW1OrErciA",
    type: "youtube",
    url: "https://www.youtube-nocookie.com/embed/_FW1OrErciA",
  },
  fleetchart: {
    videoId: "EMgyE6oKyd0",
    type: "youtube",
    url: "https://www.youtube-nocookie.com/embed/EMgyE6oKyd0",
  },
  groups: {
    videoId: "1-ssNQRjVIA",
    type: "youtube",
    url: "https://www.youtube-nocookie.com/embed/1-ssNQRjVIA",
  },
}));
</script>

<script lang="ts">
export default {
  name: "HangarGuideModal",
};
</script>

<style lang="scss" scoped>
@import "index";
</style>
