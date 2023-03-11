<template>
  <Btn
    :key="`add-to-hangar-${model.slug}`"
    v-tooltip.bottom="$t('actions.addToHangar')"
    :variant="btnVariant"
    :size="btnSize"
    :inline="variant === 'menu'"
    data-test="add-to-hangar"
    @click.native="add"
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
import { computed } from "vue";
import Btn from "@/frontend/core/components/Btn/index.vue";
import { displayWarning } from "@/frontend/lib/Noty";
import { useHangarStore } from "@/frontend/stores/Hangar";
import { useWishlistStore } from "@/frontend/stores/Wishlist";
import { useSessionStore } from "@/frontend/stores/Session";
import { useI18n } from "@/frontend/composables/useI18n";
import { useComlink } from "@/frontend/composables/useComlink";

interface Props {
  model: Model;
  variant?: "default" | "panel" | "menu";
}

const props = withDefaults(defineProps<Props>(), {
  variant: "default",
});

const hangarStore = useHangarStore();

const inHangar = computed(
  () => !!(hangarStore.ships || []).find((item) => item === props.model.slug)
);

const wishlistStore = useWishlistStore();

const onWishlist = computed(
  () => !!(wishlistStore.ships || []).find((item) => item === props.model.slug)
);

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

const sessionStore = useSessionStore();
const { t } = useI18n();
const comlink = useComlink();

const add = async () => {
  if (!sessionStore.isAuthenticated) {
    displayWarning({
      text: t("messages.error.hangar.accountRequired"),
    });
    return;
  }

  comlink.$emit("open-modal", {
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
