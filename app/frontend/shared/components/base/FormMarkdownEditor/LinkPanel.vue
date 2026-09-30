<script lang="ts">
export default {
  name: "FormMarkdownEditorLinkPanel",
};
</script>

<script lang="ts" setup>
import Btn from "@/shared/components/base/Btn/index.vue";
import FormInput from "@/shared/components/base/FormInput/index.vue";
import {
  BtnSizesEnum,
  BtnVariantsEnum,
} from "@/shared/components/base/Btn/types";
import {
  InputSizesEnum,
  InputTypesEnum,
} from "@/shared/components/base/FormInput/types";
import { useI18n } from "@/shared/composables/useI18n";
import { isSafeMarkdownHref } from "@/shared/utils/MarkdownUrls";

type Props = {
  name: string;
  initialUrl?: string;
  // The selection is already a link, so it can be removed.
  active?: boolean;
};

const props = withDefaults(defineProps<Props>(), {
  initialUrl: "",
  active: false,
});

const emit = defineEmits<{
  apply: [url: string];
  remove: [];
  close: [];
}>();

const { t } = useI18n();

const url = ref(props.initialUrl);
const invalid = ref(false);
const input = ref<InstanceType<typeof FormInput>>();

onMounted(() => input.value?.setFocus());

// Only an edit clears the message: the field also re-emits its value when it
// loses focus, which is exactly what clicking Apply does.
watch(url, () => {
  invalid.value = false;
});

const apply = () => {
  const value = String(url.value ?? "").trim();

  if (!value) {
    emit("remove");
    return;
  }

  if (!isSafeMarkdownHref(value)) {
    invalid.value = true;
    return;
  }

  emit("apply", value);
};
</script>

<template>
  <div
    class="base-markdown-editor__panel"
    data-test="markdown-editor-link-form"
    @keydown.esc.prevent.stop="emit('close')"
  >
    <FormInput
      ref="input"
      v-model="url"
      :name="`${name}-link-url`"
      :label="t('markdownEditor.linkUrl')"
      :placeholder="t('markdownEditor.linkUrlPlaceholder')"
      :size="InputSizesEnum.MEDIUM"
      :type="InputTypesEnum.URL"
      data-test="markdown-editor-link-url"
      standalone
      no-label
      class="base-markdown-editor__panel-field"
      @keydown.enter.prevent="apply"
    />
    <div class="base-markdown-editor__panel-actions">
      <Btn
        :size="BtnSizesEnum.MD"
        data-test="markdown-editor-link-apply"
        @click="apply"
      >
        {{ t("markdownEditor.linkApply") }}
      </Btn>
      <Btn
        v-if="active"
        :size="BtnSizesEnum.MD"
        :variant="BtnVariantsEnum.GHOST"
        data-test="markdown-editor-link-remove"
        @click="emit('remove')"
      >
        {{ t("markdownEditor.linkRemove") }}
      </Btn>
      <Btn
        :size="BtnSizesEnum.MD"
        :variant="BtnVariantsEnum.BARE"
        :aria-label="t('markdownEditor.close')"
        data-test="markdown-editor-link-close"
        @click="emit('close')"
      >
        <i class="fa-light fa-times" />
      </Btn>
    </div>
    <p v-if="invalid" class="base-markdown-editor__panel-error" role="alert">
      {{ t("markdownEditor.linkInvalid") }}
    </p>
  </div>
</template>

<style lang="scss" scoped>
@import "./panel";
</style>
