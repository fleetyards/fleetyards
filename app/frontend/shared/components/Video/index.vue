<template>
  <div v-if="video" class="video embed-responsive embed-responsive-16by9">
    <template v-if="video.type === 'youtube' && youtubeAccepted">
      <iframe :src="video.url" class="embed-responsive-item" />
    </template>
    <div v-else-if="video.type === 'youtube'" class="youtube-placeholder">
      <i class="fab fa-youtube" />
      <div class="youtube-placeholder-buttons">
        <Btn :inline="true" @click="acceptYoutube"> Allow video embeds </Btn>
        <Btn :inline="true" @click="copyVideoUrl(video)">
          Copy Youtube URL
        </Btn>
      </div>
    </div>
  </div>
</template>

<script lang="ts" setup>
import Btn from "@/shared/components/base/Btn/index.vue";
import copyText from "@/frontend/utils/CopyText";
import { useI18n } from "@/shared/composables/useI18n";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";
import { useComlink } from "@/shared/composables/useComlink";
import { Video } from "@/services/fyApi";
import { useCookiesStore } from "@/frontend/stores/cookies";
import { storeToRefs } from "pinia";

type Props = {
  video: Partial<Video>;
};

defineProps<Props>();

const cookiesStore = useCookiesStore();

const { youtubeAccepted } = storeToRefs(cookiesStore);

const { t } = useI18n();

const { displaySuccess, displayAlert } = useAppNotifications();

const copyVideoUrl = (video: Partial<Video>) => {
  copyText(`https://www.youtube.com/watch?v=${video.videoId}`).then(
    () => {
      displaySuccess({
        text: t("messages.copyVideoUrl.success"),
      });
    },
    () => {
      displayAlert({
        text: t("messages.copyVideoUrl.failure"),
      });
    },
  );
};

const comlink = useComlink();

const acceptYoutube = () => {
  comlink.emit("open-privacy-settings");
};
</script>
