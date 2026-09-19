<script lang="ts">
export default {
  name: "BlueprintOwnToggle",
};
</script>

<script lang="ts" setup>
import { useQueryClient } from "@tanstack/vue-query";
import Btn from "@/shared/components/base/Btn/index.vue";
import {
  BtnSizesEnum,
  BtnVariantsEnum,
} from "@/shared/components/base/Btn/types";
import { useI18n } from "@/shared/composables/useI18n";
import { useSessionStore } from "@/frontend/stores/session";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";
import {
  type Blueprint,
  useOwnBlueprint,
  useUnownBlueprint,
} from "@/services/fyApi";

type Props = {
  blueprint: Blueprint;
  variant?: "default" | "row";
};

const props = withDefaults(defineProps<Props>(), {
  variant: "default",
});

const { t } = useI18n();

const sessionStore = useSessionStore();

const queryClient = useQueryClient();

const { displayWarning, displayAlert } = useAppNotifications();

const { mutateAsync: own } = useOwnBlueprint();
const { mutateAsync: unown } = useUnownBlueprint();

const saving = ref(false);

const owned = computed(() => props.blueprint.owned);

// Bare in both places. This sits beside a title or inside a list row, next to
// facts about the recipe rather than among the page's own controls, and a
// solid button there reads as the thing the page is for.
const btnSize = computed(() =>
  props.variant === "row" ? BtnSizesEnum.SM : BtnSizesEnum.MD,
);

const tooltip = computed(() =>
  owned.value ? t("actions.blueprint.unown") : t("actions.blueprint.own"),
);

// Both the catalogue and the detail response key on `blueprints`, and a fleet's
// list of what its members hold keys its slug in the middle -- a prefix cannot
// reach that one, so it is matched by predicate.
const invalidate = async () => {
  await Promise.all([
    queryClient.invalidateQueries({ queryKey: ["blueprints"] }),
    queryClient.invalidateQueries({
      predicate: (query) =>
        query.queryKey[0] === "fleets" && query.queryKey[2] === "blueprints",
    }),
  ]);
};

const toggle = async () => {
  if (!sessionStore.isAuthenticated) {
    displayWarning({ text: t("messages.error.blueprint.accountRequired") });

    return;
  }

  if (saving.value) return;

  saving.value = true;

  try {
    if (owned.value) {
      await unown({ slug: props.blueprint.slug });
    } else {
      await own({ slug: props.blueprint.slug });
    }

    await invalidate();
  } catch {
    displayAlert({ text: t("messages.error.blueprint.own") });
  } finally {
    saving.value = false;
  }
};
</script>

<template>
  <Btn
    v-tooltip.bottom="tooltip"
    :variant="BtnVariantsEnum.BARE"
    :size="btnSize"
    :active="owned"
    :disabled="saving"
    data-test="blueprint-own-toggle"
    :aria-pressed="owned"
    :aria-label="tooltip"
    @click.stop.prevent="toggle"
  >
    <i v-if="owned" class="fa fa-bookmark" />
    <i v-else class="fa-light fa-bookmark" />
  </Btn>
</template>
