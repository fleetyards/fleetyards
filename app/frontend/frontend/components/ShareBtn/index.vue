<script lang="ts">
export default {
  name: "ShareBtn",
};
</script>

<script lang="ts" setup>
import Btn from "@/shared/components/base/Btn/index.vue";
import copyText from "@/frontend/utils/CopyText";
import { useNoty } from "@/shared/composables/useNoty";
import { useI18n } from "@/shared/composables/useI18n";
import type { SpinnerAlignment } from "@/shared/components/SmallLoader/index.vue";
import type { RouteLocationRaw } from "vue-router";
import {
  BtnSizesEnum,
  BtnVariantsEnum,
} from "@/shared/components/base/Btn/types";
import { useMobile } from "@/shared/composables/useMobile";

type Props = {
  url: string;
  title: string;
  to?: RouteLocationRaw;
  href?: string;
  type?: "button" | "submit";
  loading?: boolean;
  spinner?: boolean | SpinnerAlignment;
  variant?: BtnVariantsEnum;
  size?: BtnSizesEnum;
  exact?: boolean;
  block?: boolean;
  mobileBlock?: boolean;
  inline?: boolean;
  textInline?: boolean;
  active?: boolean;
  disabled?: boolean;
  routeActiveClass?: string;
  inGroup?: boolean;
  noLabel?: boolean;
};

const props = withDefaults(defineProps<Props>(), {
  to: undefined,
  href: undefined,
  type: "button",
  loading: false,
  spinner: false,
  variant: BtnVariantsEnum.DEFAULT,
  size: BtnSizesEnum.DEFAULT,
  exact: false,
  block: false,
  mobileBlock: false,
  inline: false,
  textInline: false,
  active: false,
  disabled: false,
  routeActiveClass: undefined,
  inGroup: false,
  noLabel: false,
});

const { t } = useI18n();

const { displayAlert, displaySuccess } = useNoty();

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
    :inline="inline"
    @click="share"
  >
    <i class="fad fa-share-square" />
    <span v-if="!noLabel">{{ t("actions.share") }}</span>
  </Btn>
</template>
