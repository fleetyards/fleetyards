<script lang="ts">
export default {
  name: "OauthBtn",
};
</script>

<script lang="ts" setup>
import { OmniauthProviderEnum } from "@/services/fyApi";
import { oauthProviderFeatureFlags } from "./types";
import citizenIdIconProd from "@/images/icons/citizenid.jpg";
import citizenIdIconDev from "@/images/icons/citizenid-dev.jpg";
import {
  BtnSizesEnum,
  BtnVariantsEnum,
  BtnTonesEnum,
  BtnTypesEnum,
} from "@/shared/components/base/Btn/types";
import { useI18n } from "@/shared/composables/useI18n";
import { useFeatures } from "@/frontend/composables/useFeatures";
import { csrfToken } from "@/shared/utils/Meta";
import { useRedirectBackStore } from "@/shared/stores/redirectBack";
import { useRouter } from "vue-router";

type Props = {
  provider: OmniauthProviderEnum;
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
  size: undefined,
  variant: undefined,
  block: false,
  inline: false,
  connected: false,
  onlyIcon: false,
  disconnectable: false,
  disconnecting: false,
});

const emit = defineEmits<{
  disconnect: [provider: OmniauthProviderEnum];
}>();

const { t } = useI18n();

const redirectBackStore = useRedirectBackStore();
const router = useRouter();

// The back route is persisted, so it can name a route a later release
// renamed. Resolving that throws, which would block signing in entirely.
const backRouteHref = () => {
  const backRoute = redirectBackStore.backRoute;
  if (!backRoute) {
    return undefined;
  }

  try {
    return router.resolve(backRoute).href;
  } catch {
    redirectBackStore.$reset();
    return undefined;
  }
};

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

  const backHref = backRouteHref();
  if (backHref) {
    const originInput = document.createElement("input");
    originInput.type = "hidden";
    originInput.name = "origin";
    originInput.value = window.location.origin + backHref;
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
  return isFeatureEnabled(oauthProviderFeatureFlags[props.provider]);
});

const isCitizenId = computed(
  () => props.provider === OmniauthProviderEnum.CITIZENID,
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
      :variant="variant"
      :tone="
        connected && disconnectable ? BtnTonesEnum.DANGER : BtnTonesEnum.NEUTRAL
      "
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
