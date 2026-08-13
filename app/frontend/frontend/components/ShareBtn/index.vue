<script lang="ts">
export default {
  name: "ShareBtn",
};
</script>

<script lang="ts" setup>
import Btn from "@/shared/components/base/Btn/index.vue";
import copyText from "@/frontend/utils/CopyText";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";
import { useI18n } from "@/shared/composables/useI18n";
import {
  BtnSizesEnum,
  BtnVariantsEnum,
} from "@/shared/components/base/Btn/types";
import { useMobile } from "@/shared/composables/useMobile";

// Only what the wrapper forwards. Anything else a caller sets - `disabled`,
// `loading`, `to` - falls through to the Btn below on its own.
type Props = {
  url: string;
  title: string;
  variant?: BtnVariantsEnum;
  size?: BtnSizesEnum;
  block?: boolean;
  mobileIconOnly?: boolean;
  noLabel?: boolean;
};

const props = withDefaults(defineProps<Props>(), {
  variant: undefined,
  size: undefined,
  block: false,
  mobileIconOnly: false,
  noLabel: false,
});

const { t } = useI18n();

const { displayAlert, displaySuccess } = useAppNotifications();

const isMobile = useMobile();

const share = () => {
  if (
    isMobile.value &&
    navigator.canShare &&
    navigator.canShare({ url: props.url })
  ) {
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
    },
  );
};
</script>

<template>
  <Btn
    v-tooltip="noLabel && t('actions.share')"
    :variant="variant"
    :size="size"
    :block="block"
    :mobile-icon-only="mobileIconOnly"
    @click="share"
  >
    <i class="fa-duotone fa-share-square" />
    <span v-if="!noLabel">{{ t("actions.share") }}</span>
  </Btn>
</template>
