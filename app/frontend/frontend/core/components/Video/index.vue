<template>
  <div class="video embed-responsive embed-responsive-16by9">
    <template v-if="video.type === 'youtube' && youtubeEnabled">
      <iframe :src="video.url" class="embed-responsive-item" />
    </template>
    <div v-else-if="video.type === 'youtube'" class="youtube-placeholder">
      <i class="fab fa-youtube" />
      <div class="youtube-placeholder-buttons">
        <Btn :inline="true" @click.native="enableYoutube">
          Allow video embeds
        </Btn>
        <Btn :inline="true" @click.native="copyVideoUrl(video)">
          Copy Youtube URL
        </Btn>
      </div>
    </div>
  </div>
</template>

<script lang="ts" setup>
import Btn from "@/frontend/core/components/Btn/index.vue";
import Store from "@/frontend/lib/Store";
import copyText from "@/frontend/utils/CopyText";
import { displaySuccess, displayAlert } from "@/frontend/lib/Noty";
import { useI18n } from "@/frontend/composables/useI18n";
import { useComlink } from "@/frontend/composables/useComlink";

type Props = {
  video: TVideo;
};

defineProps<Props>();

const cookies = computed(() => Store.getters["cookies/cookies"]);

const youtubeEnabled = computed(() => cookies.value.youtube);

const { t } = useI18n();

const copyVideoUrl = (video: TVideo) => {
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
    }
  );
};

const comlink = useComlink();

const enableYoutube = () => {
  comlink.$emit("open-privacy-settings");
};
</script>
