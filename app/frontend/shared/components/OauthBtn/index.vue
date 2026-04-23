<script lang="ts">
export default {
  name: "OauthBtn",
};
</script>

<script lang="ts" setup>
import { OauthBtnProvidersEnum } from "./types";
import citizenIdIconProd from "@/images/icons/citizenid.jpg";
import citizenIdIconDev from "@/images/icons/citizenid-dev.jpg";
import {
  BtnSizesEnum,
  BtnVariantsEnum,
  BtnTypesEnum,
} from "@/shared/components/base/Btn/types";
import { useI18n } from "@/shared/composables/useI18n";
import { useFeatures } from "@/frontend/composables/useFeatures";
import { csrfToken } from "@/shared/utils/Meta";
import { useRedirectBackStore } from "@/shared/stores/redirectBack";
import { useRouter } from "vue-router";

type Props = {
  provider: `${OauthBtnProvidersEnum}`;
  size?: BtnSizesEnum;
  variant?: BtnVariantsEnum;
  block?: boolean;
  inline?: boolean;
  connected?: boolean;
  onlyIcon?: boolean;
  disconnectable?: boolean;
  disconnecting?: boolean;
};

const props = withDefaults(defineProps<Props>(), {
  size: BtnSizesEnum.DEFAULT,
  variant: BtnVariantsEnum.DEFAULT,
  block: false,
  inline: false,
  connected: false,
  onlyIcon: false,
  disconnectable: false,
  disconnecting: false,
});

const emit = defineEmits<{
  disconnect: [provider: `${OauthBtnProvidersEnum}`];
}>();

const { t } = useI18n();

const redirectBackStore = useRedirectBackStore();
const router = useRouter();

const handleClick = () => {
  if (props.connected && props.disconnectable) {
    emit("disconnect", props.provider);
    return;
  }

  const form = document.createElement("form");

  form.method = "POST";
  form.action = `/users/auth/${props.provider}`;

  const csrfInput = document.createElement("input");
  csrfInput.type = "hidden";
  csrfInput.name = "authenticity_token";
  csrfInput.value = csrfToken();
  form.appendChild(csrfInput);

  const backRoute = redirectBackStore.backRoute;
  if (backRoute) {
    const originInput = document.createElement("input");
    originInput.type = "hidden";
    originInput.name = "origin";
    originInput.value = window.location.origin + router.resolve(backRoute).href;
    form.appendChild(originInput);
  }

  document.body.appendChild(form);

  form.submit();

  document.body.removeChild(form);
};

const label = computed(() => {
  if (props.connected && props.disconnectable) {
    return t(`actions.oauth.disconnect.${props.provider}`);
  }

  if (props.connected) {
    return t(`actions.oauth.connected.${props.provider}`);
  }

  return t(`actions.oauth.${props.provider}`);
});

const { isFeatureEnabled } = useFeatures();

const providerActive = computed(() => {
  return isFeatureEnabled(`oauth-${props.provider}`);
});

const isCitizenId = computed(
  () => props.provider === OauthBtnProvidersEnum.CITIZENID,
);

const citizenIdIcon = computed(() =>
  window.NODE_ENV === "production" ? citizenIdIconProd : citizenIdIconDev,
);
</script>

<template>
  <Transition name="fade" mode="out-in">
    <Btn
      v-if="providerActive"
      :size="size"
      :block="block"
      :variant="connected && disconnectable ? BtnVariantsEnum.DANGER : variant"
      :inline="inline"
      :type="BtnTypesEnum.BUTTON"
      class="oauth-btn"
      :class="{ inline: inline }"
      data-test="oauth-btn"
      :disabled="(connected && !disconnectable) || disconnecting"
      :loading="disconnecting"
      @click="handleClick"
    >
      <slot>
        <template v-if="isCitizenId">
          <img
            :src="citizenIdIcon"
            alt="Citizen iD"
            class="oauth-icon--citizenid"
          />
          <span v-if="onlyIcon">
            {{ t("actions.oauth.signInWith") }} {{ label }}
          </span>
          <span v-else>{{ label }}</span>
        </template>
        <template v-else>
          <i :class="`fa-brands fa-${provider}`" />
          <span v-if="!onlyIcon">{{ label }}</span>
        </template>
        <i
          v-if="connected && !disconnectable"
          class="fa-light fa-check text-success"
        />
      </slot>
    </Btn>
  </Transition>
</template>

<style lang="scss" scoped>
@import "index";
</style>
