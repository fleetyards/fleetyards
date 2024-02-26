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
import Btn from "@/shared/components/base/Btn/index.vue";
import type {
  BtnVariants,
  BtnSizes,
} from "@/shared/components/base/Btn/index.vue";
import copyText from "@/frontend/utils/CopyText";
import { useNoty } from "@/shared/composables/useNoty";
import { useI18n } from "@/frontend/composables/useI18n";
import type { SpinnerAlignment } from "@/shared/components/SmallLoader/index.vue";
import type { RouteLocationRaw } from "vue-router";

type Props = {
  url: string;
  title: string;
  to?: RouteLocationRaw;
  href?: string;
  type?: "button" | "submit";
  loading?: boolean;
  spinner?: boolean | SpinnerAlignment;
  variant?: BtnVariants;
  size?: BtnSizes;
  exact?: boolean;
  block?: boolean;
  mobileBlock?: boolean;
  inline?: boolean;
  textInline?: boolean;
  active?: boolean;
  disabled?: boolean;
  routeActiveClass?: string;
  inGroup?: boolean;
};

const props = withDefaults(defineProps<Props>(), {
  to: undefined,
  href: undefined,
  type: "button",
  loading: false,
  spinner: false,
  variant: "default",
  size: "default",
  exact: false,
  block: false,
  mobileBlock: false,
  inline: false,
  textInline: false,
  active: false,
  disabled: false,
  routeActiveClass: undefined,
  inGroup: false,
});

const { t } = useI18n();

const { displayAlert, displaySuccess } = useNoty(t);

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
    },
  );
};
</script>

<script lang="ts">
export default {
  name: "ShareBtn",
};
</script>
