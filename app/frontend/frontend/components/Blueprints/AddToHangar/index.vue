<script lang="ts">
export default {
  name: "BlueprintAddToHangar",
};
</script>

<script lang="ts" setup>
import Btn from "@/shared/components/base/Btn/index.vue";
import {
  BtnSizesEnum,
  BtnVariantsEnum,
} from "@/shared/components/base/Btn/types";
import { useI18n } from "@/shared/composables/useI18n";
import { useComlink } from "@/shared/composables/useComlink";
import { useSessionStore } from "@/frontend/stores/session";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";
import { type Blueprint } from "@/services/fyApi";

type Props = {
  blueprint: Blueprint;
  variant?: "default" | "row";
};

const props = withDefaults(defineProps<Props>(), {
  variant: "default",
});

const { t } = useI18n();

const sessionStore = useSessionStore();

const comlink = useComlink();

const { displayWarning } = useAppNotifications();

const marked = computed(() => props.blueprint.owned || props.blueprint.wanted);

// Bare in both places. This sits beside a title or inside a list row, next to
// facts about the recipe rather than among the page's own controls, and a
// solid button there reads as the thing the page is for.
const btnSize = computed(() =>
  props.variant === "row" ? BtnSizesEnum.SM : BtnSizesEnum.MD,
);

const open = () => {
  if (!sessionStore.isAuthenticated) {
    displayWarning({ text: t("messages.error.blueprint.accountRequired") });

    return;
  }

  comlink.emit("open-modal", {
    component: () =>
      import("@/frontend/components/Blueprints/AddToHangar/Modal/index.vue"),
    props: { blueprint: props.blueprint },
  });
};
</script>

<!-- The ship catalogue's bookmark: solid once the recipe is held or wanted,
     outlined otherwise, and a click asks which of the two it is. -->
<template>
  <Btn
    v-tooltip.bottom="t('actions.addToHangar')"
    :variant="BtnVariantsEnum.BARE"
    :size="btnSize"
    data-test="blueprint-add-to-hangar"
    :aria-label="t('actions.addToHangar')"
    @click.stop.prevent="open"
  >
    <i v-if="marked" class="fa fa-bookmark" />
    <i v-else class="fa-light fa-bookmark" />
  </Btn>
</template>
