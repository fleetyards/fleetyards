<script lang="ts" setup>
import Btn from "@/frontend/core/components/Btn/index.vue";
import { useComlink } from "@/frontend/composables/useComlink";
import { useI18n } from "@/frontend/composables/useI18n";

const { t } = useI18n();

const comlink = useComlink();

const open = () => {
  comlink.$emit("open-modal", {
    component: () => import("@/frontend/components/Support/Modal/index.vue"),
    wide: true,
  });
};

const route = useRoute();

onMounted(() => {
  if (route.query.support) {
    open();
  }
});
</script>

<template>
  <Btn size="small" class="support-button" @click.native="open">
    {{ t("actions.supportUs") }}
  </Btn>
</template>

<script lang="ts">
export default {
  name: "SupportBtn",
};
</script>
