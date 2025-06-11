<script lang="ts">
export default {
  name: "OauthBtn",
};
</script>

<script lang="ts" setup>
import { OauthBtnProvidersEnum } from "./types";
import {
  BtnSizesEnum,
  BtnVariantsEnum,
  BtnTypesEnum,
} from "@/shared/components/base/Btn/types";
import { useI18n } from "@/shared/composables/useI18n";
import { useFeatures } from "@/frontend/composables/useFeatures";
import { csrfToken } from "@/shared/utils/Meta";

type Props = {
  provider: `${OauthBtnProvidersEnum}`;
  size?: BtnSizesEnum;
  variant?: BtnVariantsEnum;
  block?: boolean;
  inline?: boolean;
  connected?: boolean;
  onlyIcon?: boolean;
};

const props = withDefaults(defineProps<Props>(), {
  size: BtnSizesEnum.DEFAULT,
  variant: BtnVariantsEnum.DEFAULT,
  block: false,
  inline: false,
  connected: false,
  onlyIcon: false,
});

const { t } = useI18n();

const handleClick = () => {
  const form = document.createElement("form");

  form.method = "POST";
  form.action = `/users/auth/${props.provider}`;

  const csrfInput = document.createElement("input");
  csrfInput.type = "hidden";
  csrfInput.name = "authenticity_token";
  csrfInput.value = csrfToken();
  form.appendChild(csrfInput);

  document.body.appendChild(form);

  form.submit();

  document.body.removeChild(form);
};

const label = computed(() => {
  if (props.connected) {
    return t(`actions.oauth.connected.${props.provider}`);
  }

  return t(`actions.oauth.${props.provider}`);
});

const { isFeatureEnabled } = useFeatures();

const providerActive = computed(() => {
  return isFeatureEnabled(`oauth-${props.provider}`);
});
</script>

<template>
  <Transition name="fade" mode="out-in">
    <Btn
      v-if="providerActive"
      :size="size"
      :block="block"
      :variant="variant"
      :inline="inline"
      :type="BtnTypesEnum.BUTTON"
      class="oauth-btn"
      data-test="oauth-btn"
      :disabled="connected"
      @click="handleClick"
    >
      <slot>
        <i :class="`fab fa-${provider}`" />
        <span v-if="!onlyIcon">{{ label }}</span>
        <i v-if="connected" class="fal fa-check text-success" />
      </slot>
    </Btn>
  </Transition>
</template>
