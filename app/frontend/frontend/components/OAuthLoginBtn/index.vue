<template>
  <Btn
    :variant="variant"
    :size="size"
    :inline="inline"
    :block="block"
    @click.native="openProvider"
  >
    <slot name="label">
      <i :class="`fab fa-${provider}`"></i>
      {{ t(`labels.oauth.${provider}.label`) }}
    </slot>
  </Btn>
</template>

<script lang="ts" setup>
import Btn from "@/frontend/core/components/Btn/index.vue";
import type {
  Props as BtnProps,
  BtnSizes,
  BtnVariants,
} from "@/frontend/core/components/Btn/index.vue";
import { useI18n } from "@/frontend/composables/useI18n";

const { t } = useI18n();

interface Props extends BtnProps {
  provider: string;
  block?: boolean;
  size?: BtnSizes;
  inline?: boolean;
  variant?: BtnVariants;
  label?: string;
}

const props = defineProps<Props>();

const basePath = computed(() => `/users/auth/${props.provider}/`);

const openProvider = () => {
  const form = document.createElement("form");
  form.method = "post";
  form.action = basePath.value;

  const typeField = document.createElement("input");
  typeField.type = "hidden";
  typeField.name = "authenticity_token";
  typeField.value = (
    document.querySelector('meta[name="csrf-token"]') as HTMLMetaElement
  )?.content;
  form.appendChild(typeField);

  document.body.appendChild(form);

  form.submit();

  document.body.removeChild(form);
};
</script>

<script lang="ts">
export default {
  name: "OAuthLoginBtn",
};
</script>
```
