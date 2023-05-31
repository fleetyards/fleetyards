<template>
  <Btn
    v-tooltip="variant !== 'dropdown' && t('actions.share')"
    :variant="variant"
    :size="size"
    :inline="inline"
    @click="share"
  >
    <i class="fad fa-share-square" />
    <span v-if="variant === 'dropdown'">{{ t("actions.share") }}</span>
  </Btn>
</template>

<script lang="ts" setup>
import Btn from "@/frontend/core/components/Btn/index.vue";
import type {
  Props as BtnProps,
  BtnVariants,
  BtnSizes,
} from "@/frontend/core/components/Btn/index.vue";
import copyText from "@/frontend/utils/CopyText";
import { displayAlert, displaySuccess } from "@/frontend/lib/Noty";
import { useI18n } from "@/frontend/composables/useI18n";

interface Props extends BtnProps {
  url: string;
  title: string;
  variant?: BtnVariants;
  size?: BtnSizes;
  inline?: boolean;
}

const props = withDefaults(defineProps<Props>(), {
  variant: "default",
  size: "default",
  inline: false,
});

const { t } = useI18n();

const share = () => {
  if (navigator.canShare && navigator.canShare({ url: props.url })) {
    navigator
      .share({
        title: props.title,
        url: props.url,
      })
      .then(() => console.info("Share was successful."))
      .catch((error) => console.info("Sharing failed", error));
  } else {
    copyShareUrl();
  }
};

const copyShareUrl = () => {
  if (!props.url) {
    displayAlert({
      text: t("messages.copyShareUrl.failure"),
    });
  }

  copyText(props.url).then(
    () => {
      displaySuccess({
        text: t("messages.copyShareUrl.success", {
          url: props.url,
        }),
      });
    },
    () => {
      displayAlert({
        text: t("messages.copyShareUrl.failure"),
      });
    }
  );
};
</script>

<script lang="ts">
export default {
  name: "ShareBtn",
};
</script>
