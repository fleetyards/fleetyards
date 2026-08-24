<script lang="ts">
export default {
  name: "BtnConfirm",
};
</script>

<script lang="ts" setup>
import Btn from "@/shared/components/base/Btn/index.vue";
import BtnGroup from "@/shared/components/base/BtnGroup/index.vue";
import {
  BtnSizesEnum,
  BtnTonesEnum,
  BtnVariantsEnum,
} from "@/shared/components/base/Btn/types";
import { useI18n } from "@/shared/composables/useI18n";

/*
 * A confirm that asks where the action is, instead of over the whole page. The
 * modal AppConfirm interrupts everything, which is right for "delete all 284
 * ships" and far too much for one row in a table.
 *
 * Armed, it becomes a BtnGroup holding a label segment and two actions - the
 * shape the paginator already uses, so the inline question is built from the
 * vocabulary that exists rather than a new one. That also means the three
 * segments read as a single control, which is what stops a stray click landing
 * on "yes" when the eye expected the trigger.
 */
type Props = {
  /** The question. Kept short: it has to fit where the trigger stood. */
  question?: string;
  confirmText?: string;
  cancelText?: string;
  size?: `${BtnSizesEnum}`;
  tone?: `${BtnTonesEnum}`;
  variant?: `${BtnVariantsEnum}`;
  disabled?: boolean;
  /** Hides the question, for a cell too narrow to hold one. */
  hideQuestion?: boolean;
};

const props = withDefaults(defineProps<Props>(), {
  question: undefined,
  confirmText: undefined,
  cancelText: undefined,
  size: undefined,
  tone: BtnTonesEnum.NEUTRAL,
  variant: BtnVariantsEnum.SOLID,
  disabled: false,
  hideQuestion: false,
});

const emit = defineEmits<{
  confirm: [];
  cancel: [];
}>();

const { t } = useI18n();

const armed = ref(false);

const root = ref<HTMLElement | null>(null);

const question = computed(
  () => props.question || t("baseBtn.confirm.question"),
);

const confirmLabel = computed(
  () => props.confirmText || t("baseBtn.confirm.yes"),
);

const cancelLabel = computed(() => props.cancelText || t("baseBtn.confirm.no"));

/*
 * The click that arms must not disarm. Vue removes the trigger the moment
 * `armed` flips, so by the time the same event reaches the document listener its
 * target is a detached node - which `root.contains()` reports as outside, and the
 * question closes in the frame it opened. Holding the event and skipping it once
 * is exact, where deferring the listener by a frame would only be likely.
 */
let armingEvent: MouseEvent | null = null;

const disarm = () => {
  armed.value = false;
};

const arm = (event: MouseEvent) => {
  armingEvent = event;
  armed.value = true;

  void nextTick(() => {
    cancelRef.value?.$el?.focus();
  });
};

const onConfirm = () => {
  disarm();
  emit("confirm");
};

const onCancel = () => {
  disarm();
  emit("cancel");
};

const cancelRef = ref<{ $el?: HTMLElement } | null>(null);

/*
 * Escape listens on the window, not on the wrapper: arming removes the trigger,
 * so the element that had focus is gone and focus falls to the body - a keydown
 * there never reaches a handler bound inside this component.
 *
 * And focus moves to the declining half, unlike the modal, which focuses the
 * committing one. A modal stops everything, so Enter there is deliberate; an
 * inline confirm appears in a list someone may be tabbing through, and an Enter
 * meant for something else must not delete a row.
 */
const onKeyDown = (event: KeyboardEvent) => {
  if (!armed.value) return;
  if (event.key !== "Escape") return;

  event.stopPropagation();
  onCancel();
};

const onDocumentClick = (event: MouseEvent) => {
  if (event === armingEvent) {
    armingEvent = null;
    return;
  }

  if (!armed.value) return;
  if (root.value?.contains(event.target as Node)) return;

  disarm();
};

onMounted(() => {
  document.addEventListener("click", onDocumentClick);
  window.addEventListener("keydown", onKeyDown);
});

onUnmounted(() => {
  document.removeEventListener("click", onDocumentClick);
  window.removeEventListener("keydown", onKeyDown);
});
</script>

<template>
  <span ref="root" class="btn-confirm">
    <Btn
      v-if="!armed"
      :size="size"
      :tone="tone"
      :variant="variant"
      :disabled="disabled"
      data-test="btn-confirm-trigger"
      @click="arm"
    >
      <slot />
    </Btn>

    <BtnGroup v-else :size="size">
      <span v-if="!hideQuestion" data-test="btn-confirm-question">
        {{ question }}
      </span>
      <!-- Always danger-toned: an inline confirm guards a removal, so the
           committing half is the destructive one whatever the trigger looked
           like. -->
      <Btn
        :tone="BtnTonesEnum.DANGER"
        data-test="btn-confirm-yes"
        @click="onConfirm"
      >
        {{ confirmLabel }}
      </Btn>
      <Btn ref="cancelRef" data-test="btn-confirm-no" @click="onCancel">
        {{ cancelLabel }}
      </Btn>
    </BtnGroup>
  </span>
</template>

<style scoped>
.btn-confirm {
  display: inline-flex;
}
</style>
