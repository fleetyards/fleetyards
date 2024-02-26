<template>
  <Btn
    :key="`add-to-hangar-${model.slug}`"
    v-tooltip.bottom="t('actions.addToHangar')"
    :variant="btnVariant"
    :size="btnSize"
    :inline="variant === 'menu'"
    data-test="add-to-hangar"
    @click="add"
  >
    <span v-show="inHangar || onWishlist">
      <i class="fa fa-bookmark" />
    </span>
    <span v-show="!inHangar && !onWishlist">
      <i class="fal fa-bookmark" />
    </span>
  </Btn>
</template>

<script lang="ts" setup>
import Btn from "@/shared/components/base/Btn/index.vue";
import type { Model } from "@/services/fyApi";
import { useSessionStore } from "@/frontend/stores/session";
import { useHangarStore } from "@/frontend/stores/hangar";
import { useWishlistStore } from "@/frontend/stores/wishlist";
import { useI18n } from "@/frontend/composables/useI18n";
import { useComlink } from "@/shared/composables/useComlink";
import { useNoty } from "@/shared/composables/useNoty";

type Props = {
  model: Model;
  variant?: "default" | "panel" | "menu";
};

const props = withDefaults(defineProps<Props>(), {
  variant: "default",
});

const { t } = useI18n();

const { displayWarning } = useNoty(t);

const sessionStore = useSessionStore();

const hangarStore = useHangarStore();

const wishlistStore = useWishlistStore();

const inHangar = computed(() => {
  return !!(hangarStore.ships || []).find((item) => item === props.model.slug);
});

const onWishlist = computed(() => {
  return !!(wishlistStore.ships || []).find(
    (item) => item === props.model.slug,
  );
});

const btnVariant = computed(() => {
  if (["panel", "menu"].includes(props.variant)) {
    return "link";
  }

  return "default";
});

const btnSize = computed(() => {
  if (["panel", "menu"].includes(props.variant)) {
    return "small";
  }

  return "default";
});

const comlink = useComlink();

const add = async () => {
  if (!sessionStore.isAuthenticated) {
    displayWarning({
      text: t("messages.error.hangar.accountRequired"),
    });

    return;
  }

  comlink.emit("open-modal", {
    component: () =>
      import("@/frontend/components/Models/AddToHangarModal/index.vue"),
    props: {
      model: props.model,
    },
  });
};
</script>

<script lang="ts">
export default {
  name: "AddToHangar",
};
</script>
