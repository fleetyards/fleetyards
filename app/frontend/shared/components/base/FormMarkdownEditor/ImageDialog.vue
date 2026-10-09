<script lang="ts">
export default {
  name: "FormMarkdownEditorImageDialog",
};
</script>

<script lang="ts" setup>
import ModalInner from "@/shared/components/AppModal/Inner/index.vue";
import Btn from "@/shared/components/base/Btn/index.vue";
import FormInput from "@/shared/components/base/FormInput/index.vue";
import DirectUploadUploader, {
  type FileUpload,
} from "@/shared/components/DirectUpload/Uploader/index.vue";
import { BtnVariantsEnum } from "@/shared/components/base/Btn/types";
import { createMarkdownImage } from "@/services/fyApi";
import { useI18n } from "@/shared/composables/useI18n";
import { validationErrorFrom } from "@/shared/utils/ApiErrors";

// Turns an uploaded blob into the address of the image a description embeds.
export type MarkdownImageCreate = (signedId: string) => Promise<string>;

type Props = {
  name: string;
  createImage?: MarkdownImageCreate;
};

const props = withDefaults(defineProps<Props>(), {
  createImage: undefined,
});

const emit = defineEmits<{
  insert: [image: { src: string; alt?: string }];
  close: [];
}>();

// What the upload endpoint accepts. SVG is not among them: it is markup, and
// can carry a script.
const ACCEPTED_TYPES = ["image/png", "image/jpeg", "image/webp", "image/gif"];
const MAX_SIZE_MB = 10;

const { t } = useI18n();

const dialog = ref<HTMLDialogElement>();
const alt = ref("");
const signedId = ref<string>();
const uploading = ref(false);
const inserting = ref(false);
const failure = ref<string>();

const shown = ref(false);

// A native dialog in the top layer rather than the app's modal: the editor is
// often already inside that modal, and there is only one of it -- opening this
// through it would throw away the form underneath. It moves as the app's modal
// does, fading in from a little above.
onMounted(() => {
  dialog.value?.showModal?.();
  requestAnimationFrame(() => {
    shown.value = true;
  });
});

const TRANSITION_MS = 300;

const close = () => {
  if (!shown.value) return;

  shown.value = false;

  const reduced = window.matchMedia?.(
    "(prefers-reduced-motion: reduce)",
  ).matches;

  window.setTimeout(
    () => {
      dialog.value?.close?.();
      emit("close");
    },
    reduced ? 0 : TRANSITION_MS,
  );
};

const defaultCreateImage: MarkdownImageCreate = async (id) =>
  (await createMarkdownImage({ file: id })).url;

const onUploadStart = () => {
  uploading.value = true;
  signedId.value = undefined;
  failure.value = undefined;
};

const onUploadDone = (files: FileUpload[]) => {
  uploading.value = false;
  signedId.value = files[0]?.blob?.signed_id;
};

const onUploadError = () => {
  uploading.value = false;
};

const onClear = () => {
  signedId.value = undefined;
};

const insert = async () => {
  if (!signedId.value || inserting.value) return;

  inserting.value = true;
  failure.value = undefined;

  try {
    const src = await (props.createImage ?? defaultCreateImage)(signedId.value);

    emit("insert", { src, alt: String(alt.value ?? "").trim() || undefined });
    close();
  } catch (error) {
    // The reason the server gave -- the daily limit, a file that is not an
    // image -- says what to do next, where the generic line cannot.
    const { errors, message } = validationErrorFrom(error);

    failure.value =
      errors[0]?.messages[0]?.message ||
      message ||
      t("markdownEditor.imageUploadFailed");
  } finally {
    inserting.value = false;
  }
};
</script>

<template>
  <dialog
    ref="dialog"
    class="markdown-image-dialog"
    :class="{ 'markdown-image-dialog--shown': shown }"
    data-test="markdown-editor-image-dialog"
    @cancel.prevent="close"
    @click.self="close"
  >
    <ModalInner :title="t('markdownEditor.imageTitle')" :on-close="close">
      <DirectUploadUploader
        :allowed-types="ACCEPTED_TYPES"
        :allowed-size-mb="MAX_SIZE_MB"
        class="markdown-image-dialog__uploader"
        data-test="markdown-editor-image-uploader"
        @upload:start="onUploadStart"
        @upload:done="onUploadDone"
        @upload:error="onUploadError"
        @clear="onClear"
      />
      <FormInput
        v-model="alt"
        :name="`${name}-image-alt`"
        :label="t('markdownEditor.imageAlt')"
        :info="t('markdownEditor.imageAltHint')"
        data-test="markdown-editor-image-alt"
        class="markdown-image-dialog__alt"
        standalone
        @keydown.enter.prevent="insert"
      />
      <p v-if="failure" class="markdown-image-dialog__error" role="alert">
        {{ failure }}
      </p>
      <template #footer>
        <Btn
          :variant="BtnVariantsEnum.BARE"
          data-test="markdown-editor-image-cancel"
          @click="close"
        >
          {{ t("markdownEditor.cancel") }}
        </Btn>
        <Btn
          :disabled="!signedId || uploading"
          :loading="inserting"
          data-test="markdown-editor-image-apply"
          @click="insert"
        >
          {{ t("markdownEditor.imageApply") }}
        </Btn>
      </template>
    </ModalInner>
  </dialog>
</template>

<style lang="scss" scoped>
// Sized and dimmed like the app's own modal, whose rules it cannot share: they
// are written for the app modal's container.
.markdown-image-dialog {
  box-sizing: border-box;
  width: 600px;
  max-width: calc(100vw - 32px);
  max-height: calc(100vh - 60px);
  margin: 30px auto auto;
  padding: 0;
  overflow: visible;
  color: inherit;
  background: transparent;
  border: none;

  opacity: 0;
  transform: translate(0, -25%);
  transition:
    opacity 0.3s ease-in-out,
    transform 0.3s ease-in-out;

  &:focus,
  &:focus-visible {
    outline: none;
  }

  &::backdrop {
    background-color: rgb(0 0 0 / 0.7);
    opacity: 0;
    transition: opacity 0.3s ease-in-out;
  }

  &--shown {
    opacity: 1;
    transform: translate(0, 0);

    &::backdrop {
      opacity: 1;
    }
  }

  @media (prefers-reduced-motion: reduce) {
    transition: none;

    &::backdrop {
      transition: none;
    }
  }

  @media (max-width: $tablet-breakpoint) {
    width: 100%;
    max-width: 100%;
    margin: auto 0 0;
  }
}

// The uploader's single-file look is an overlay for an image already shown --
// invisible until hovered, with a scrim that would cover this whole dialog.
// Here nothing is shown yet, so it is the plain drop box the multi-file
// uploader draws.
.markdown-image-dialog__uploader {
  position: relative;
  padding: 0;

  :deep(.direct-upload__dropzone) {
    position: relative;
    height: 150px;
    opacity: 1;
    border: 2px dashed var(--color-edge, rgb(122 130 136 / 0.5));
    transition: border-color 150ms ease;

    &::before {
      display: none;
    }
  }

  :deep(.direct-upload__dropzone--dragging) {
    border-color: var(--color-primary, #428bca);
  }

  // In flow, not laid over the drop box it replaces, and no taller than the
  // drop box was.
  :deep(.direct-upload__preview-file) {
    position: relative;
    inset: auto;
    display: flex;
    justify-content: center;
    width: 100%;
    height: 200px;
  }

  :deep(.direct-upload__preview-file img) {
    object-fit: contain;
  }
}

.markdown-image-dialog__alt {
  margin-top: 16px;
}

.markdown-image-dialog__error {
  margin: 8px 0 0;
  font-size: 0.875rem;
  color: var(--color-danger, #dc3545);
}
</style>
