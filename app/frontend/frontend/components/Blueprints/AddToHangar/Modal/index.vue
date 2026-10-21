<script lang="ts">
export default {
  name: "BlueprintAddToHangarModal",
};
</script>

<script lang="ts" setup>
import { useQueryClient } from "@tanstack/vue-query";
import Modal from "@/shared/components/AppModal/Inner/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import { useComlink } from "@/shared/composables/useComlink";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";
import {
  type Blueprint,
  useOwnBlueprint,
  useUnownBlueprint,
  useWantBlueprint,
  useUnwantBlueprint,
} from "@/services/fyApi";

type Props = {
  blueprint: Blueprint;
};

const props = defineProps<Props>();

const { t } = useI18n();

const comlink = useComlink();

const queryClient = useQueryClient();

const { displaySuccess, displayAlert } = useAppNotifications();

const { mutateAsync: own } = useOwnBlueprint();
const { mutateAsync: unown } = useUnownBlueprint();
const { mutateAsync: want } = useWantBlueprint();
const { mutateAsync: unwant } = useUnwantBlueprint();

type Choice = {
  key: string;
  icon: string;
  title: string;
  hint: string;
  run: (args: { slug: string }) => Promise<unknown>;
  success: string;
};

const ownChoice = (): Choice => ({
  key: "own",
  icon: "fa-light fa-bookmark",
  title: t("actions.blueprint.own"),
  hint: t("texts.blueprintAddToHangar.ownHint"),
  run: own,
  success: "messages.blueprint.own.success",
});

const wantChoice = (): Choice => ({
  key: "want",
  icon: "fa-light fa-star",
  title: t("actions.addToWishlist"),
  hint: t("texts.blueprintAddToHangar.wishlistHint"),
  run: want,
  success: "messages.blueprint.want.success",
});

// Unmarked, the ship modal's pair. Wanted, getting it is the next step, so
// owning sits beside the way back off the wishlist. Held, a recipe once had
// is not lost, so the only thing left is removing the mark.
const choices = computed<Choice[]>(() => {
  if (props.blueprint.owned) {
    return [
      {
        key: "unown",
        icon: "fa-light fa-trash",
        title: t("actions.blueprint.unown"),
        hint: t("texts.blueprintAddToHangar.unownHint"),
        run: unown,
        success: "messages.blueprint.unown.success",
      },
    ];
  }

  if (props.blueprint.wanted) {
    return [
      ownChoice(),
      {
        key: "unwant",
        icon: "fa-light fa-trash",
        title: t("actions.blueprint.unwant"),
        hint: t("texts.blueprintAddToHangar.unwantHint"),
        run: unwant,
        success: "messages.blueprint.unwant.success",
      },
    ];
  }

  return [ownChoice(), wantChoice()];
});

const pending = ref(false);

// Both the catalogue and the detail response key on `blueprints`, and a fleet's
// lists of what its members hold and want key its slug in the middle -- a
// prefix cannot reach those, so they are matched by predicate.
const invalidate = () =>
  Promise.all([
    queryClient.invalidateQueries({ queryKey: ["blueprints"] }),
    queryClient.invalidateQueries({
      predicate: (query) =>
        query.queryKey[0] === "fleets" && query.queryKey[2] === "blueprints",
    }),
  ]);

const choose = async (choice: Choice) => {
  if (pending.value) return;

  pending.value = true;

  try {
    await choice.run({ slug: props.blueprint.slug });
    await invalidate();

    displaySuccess({
      text: t(choice.success, { blueprint: props.blueprint.name }),
    });

    comlink.emit("close-modal");
  } catch {
    displayAlert({ text: t("messages.error.blueprint.update") });
  } finally {
    pending.value = false;
  }
};
</script>

<template>
  <Modal
    :title="t('headlines.blueprintAddToHangar', { blueprint: blueprint.name })"
    :loading="pending"
  >
    <div class="add-to-hangar-choices">
      <button
        v-for="choice in choices"
        :key="choice.key"
        type="button"
        class="add-to-hangar-choice"
        :disabled="pending"
        :data-test="`blueprint-add-to-hangar-${choice.key}`"
        @click="choose(choice)"
      >
        <i :class="[choice.icon, 'add-to-hangar-choice__icon']" />
        <span class="add-to-hangar-choice__text">
          <span class="add-to-hangar-choice__title">{{ choice.title }}</span>
          <span class="add-to-hangar-choice__hint">{{ choice.hint }}</span>
        </span>
      </button>
    </div>
  </Modal>
</template>

<style lang="scss" scoped>
@import "@/frontend/components/Models/AddToHangar/Modal/choices";
</style>
