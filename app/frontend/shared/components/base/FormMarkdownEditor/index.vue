<script lang="ts">
export default {
  name: "FormMarkdownEditor",
};
</script>

<script lang="ts" setup>
import { EditorContent, useEditor } from "@tiptap/vue-3";
import HintIcon from "@/shared/components/base/HintIcon/index.vue";
import { type MaybeRef } from "vue";
import { useField, type RuleExpression } from "vee-validate";
import { v4 as uuidv4 } from "uuid";
import { useI18n } from "@/shared/composables/useI18n";
import { isSafeMarkdownHref } from "@/shared/utils/MarkdownUrls";
import { markdownExtensions, toMarkdown } from "./extensions";

type Props = {
  name: string;
  modelValue?: string | null;
  rules?: MaybeRef<RuleExpression<string | null>>;
  translationKey?: string;
  label?: string;
  noLabel?: boolean;
  // Rendered beside the label, so it is absent when the label is.
  info?: string;
  // The limit the API enforces, drawn as a running count under the field.
  maxlength?: number;
  disabled?: boolean;
};

const props = withDefaults(defineProps<Props>(), {
  modelValue: undefined,
  rules: undefined,
  translationKey: undefined,
  label: undefined,
  noLabel: false,
  info: undefined,
  maxlength: undefined,
  disabled: false,
});

const emit = defineEmits(["update:modelValue"]);

const { t } = useI18n();

const id = `${props.name}-${uuidv4()}`;
const labelId = `${id}-label`;
const errorId = `${id}-error`;
const counterId = `${id}-counter`;
const linkInputId = `${id}-link`;

const innerLabel = computed(() => {
  if (props.label) {
    return props.label;
  }

  return t(`labels.${props.translationKey ?? props.name}`);
});

const {
  value: inputValue,
  errorMessage,
  meta,
  errors,
  handleChange,
  handleBlur,
  resetField,
} = useField<string | null>(props.name, props.rules, {
  initialValue: props.modelValue ?? null,
  label: innerLabel.value,
});

const hasErrors = computed(() => errors.value.length > 0 && meta.touched);

// Code points, as the API counts them -- see FormTextarea.
const characterCount = computed(
  () => [...String(inputValue.value ?? "")].length,
);

const overLimit = computed(
  () => !!props.maxlength && characterCount.value > props.maxlength,
);

// Both are always in the document -- the error line is empty until there is
// one -- so the description can be set once, when the editor is created.
const describedBy = [errorId, props.maxlength ? counterId : undefined]
  .filter(Boolean)
  .join(" ");

// The last markdown this field emitted. A model value coming back equal to it
// is the parent writing our own change back, and resetting the document then
// would throw the cursor to the start on every keystroke.
let emitted: string | null = props.modelValue ?? null;

const editor = useEditor({
  extensions: markdownExtensions(),
  content: props.modelValue ?? "",
  contentType: "markdown",
  editable: !props.disabled,
  editorProps: {
    attributes: {
      class: "base-markdown-editor__content markdown-content",
      role: "textbox",
      "aria-multiline": "true",
      "aria-labelledby": labelId,
      "aria-describedby": describedBy,
      "data-test": `input-${props.name}`,
    },
  },
  onUpdate: ({ editor: instance }) => {
    const markdown = toMarkdown(instance);

    emitted = markdown;
    handleChange(markdown);
    emit("update:modelValue", markdown);
  },
  onBlur: () => {
    handleBlur(undefined, true);
  },
});

watch(
  () => props.modelValue,
  (value) => {
    if ((value ?? null) !== emitted) {
      emitted = value ?? null;
      editor.value?.commands.setContent(value ?? "", {
        contentType: "markdown",
        emitUpdate: false,
      });
    }

    resetField({ value: value ?? null, touched: meta.touched });
  },
);

watch(
  () => props.disabled,
  (disabled) => editor.value?.setEditable(!disabled),
);

type ToolbarAction = {
  key: string;
  icon: string;
  isActive: () => boolean;
  run: () => void;
};

const chain = () => editor.value!.chain().focus();

const actions: ToolbarAction[] = [
  {
    key: "bold",
    icon: "fa-regular fa-bold",
    isActive: () => !!editor.value?.isActive("bold"),
    run: () => chain().toggleBold().run(),
  },
  {
    key: "italic",
    icon: "fa-regular fa-italic",
    isActive: () => !!editor.value?.isActive("italic"),
    run: () => chain().toggleItalic().run(),
  },
  {
    key: "heading",
    icon: "fa-regular fa-heading",
    isActive: () => !!editor.value?.isActive("heading"),
    run: () => chain().toggleHeading({ level: 2 }).run(),
  },
  {
    key: "bulletList",
    icon: "fa-regular fa-list-ul",
    isActive: () => !!editor.value?.isActive("bulletList"),
    run: () => chain().toggleBulletList().run(),
  },
  {
    key: "orderedList",
    icon: "fa-regular fa-list-ol",
    isActive: () => !!editor.value?.isActive("orderedList"),
    run: () => chain().toggleOrderedList().run(),
  },
  {
    key: "center",
    icon: "fa-regular fa-align-center",
    isActive: () => !!editor.value?.isActive("center"),
    run: () => chain().toggleCenter().run(),
  },
];

const linkOpen = ref(false);
const linkUrl = ref("");
const linkInvalid = ref(false);
const linkInput = ref<HTMLInputElement>();

const linkActive = computed(() => !!editor.value?.isActive("link"));

const openLink = () => {
  linkUrl.value = editor.value?.getAttributes("link").href ?? "";
  linkInvalid.value = false;
  linkOpen.value = true;
  void nextTick(() => linkInput.value?.focus());
};

const closeLink = () => {
  linkOpen.value = false;
  editor.value?.commands.focus();
};

const applyLink = () => {
  const url = linkUrl.value.trim();

  if (!url) {
    chain().extendMarkRange("link").unsetLink().run();
    linkOpen.value = false;
    return;
  }

  if (!isSafeMarkdownHref(url)) {
    linkInvalid.value = true;
    return;
  }

  // With nothing selected there is no text to carry the link, so the address
  // becomes its own text.
  if (editor.value?.state.selection.empty && !linkActive.value) {
    chain()
      .insertContent({
        type: "text",
        text: url,
        marks: [{ type: "link", attrs: { href: url } }],
      })
      .run();
  } else {
    chain().extendMarkRange("link").setLink({ href: url }).run();
  }

  linkOpen.value = false;
};

const removeLink = () => {
  chain().extendMarkRange("link").unsetLink().run();
  linkOpen.value = false;
};

const focusEditor = () => {
  editor.value?.commands.focus();
};

defineExpose({ setFocus: focusEditor });
</script>

<template>
  <div
    class="base-textarea base-markdown-editor"
    :class="{
      'base-textarea--with-error': hasErrors,
      'base-textarea--disabled': disabled,
    }"
  >
    <div v-if="!noLabel" class="field-label">
      <!-- The text is a contenteditable, which a label cannot point at with
           `for`; it names the text through aria-labelledby, and a click on it
           focuses the text as a click on a textarea's label would. -->
      <!-- eslint-disable-next-line vuejs-accessibility/label-has-for -->
      <label :id="labelId" @click="focusEditor">{{ innerLabel }}</label>
      <HintIcon v-if="info" :text="info" />
    </div>
    <div class="base-textarea__wrapper">
      <div
        v-if="editor"
        class="base-markdown-editor__toolbar"
        role="toolbar"
        :aria-label="t('markdownEditor.toolbar')"
        :aria-controls="id"
      >
        <button
          v-for="action in actions"
          :key="action.key"
          v-tooltip.bottom="t(`markdownEditor.${action.key}`)"
          type="button"
          class="base-markdown-editor__action"
          :class="{ 'base-markdown-editor__action--active': action.isActive() }"
          :aria-pressed="action.isActive()"
          :aria-label="t(`markdownEditor.${action.key}`)"
          :disabled="disabled"
          :data-test="`markdown-editor-${action.key}`"
          @mousedown.prevent
          @click="action.run"
        >
          <i :class="action.icon" />
        </button>
        <button
          v-tooltip.bottom="t('markdownEditor.link')"
          type="button"
          class="base-markdown-editor__action"
          :class="{ 'base-markdown-editor__action--active': linkActive }"
          :aria-pressed="linkActive"
          :aria-expanded="linkOpen"
          :aria-label="t('markdownEditor.link')"
          :disabled="disabled"
          data-test="markdown-editor-link"
          @mousedown.prevent
          @click="linkOpen ? closeLink() : openLink()"
        >
          <i class="fa-regular fa-link" />
        </button>
      </div>
      <div
        v-if="linkOpen"
        class="base-markdown-editor__link"
        data-test="markdown-editor-link-form"
      >
        <label :for="linkInputId" class="sr-only">
          {{ t("markdownEditor.linkUrl") }}
        </label>
        <input
          :id="linkInputId"
          ref="linkInput"
          v-model="linkUrl"
          type="url"
          inputmode="url"
          :placeholder="t('markdownEditor.linkUrlPlaceholder')"
          :aria-invalid="linkInvalid"
          data-test="markdown-editor-link-url"
          @keydown.enter.prevent="applyLink"
          @keydown.esc.prevent="closeLink"
        />
        <button
          type="button"
          class="base-markdown-editor__link-action"
          data-test="markdown-editor-link-apply"
          @click="applyLink"
        >
          {{ t("markdownEditor.linkApply") }}
        </button>
        <button
          v-if="linkActive"
          type="button"
          class="base-markdown-editor__link-action"
          data-test="markdown-editor-link-remove"
          @click="removeLink"
        >
          {{ t("markdownEditor.linkRemove") }}
        </button>
        <p
          v-if="linkInvalid"
          class="base-markdown-editor__link-error"
          role="alert"
        >
          {{ t("markdownEditor.linkInvalid") }}
        </p>
      </div>
      <EditorContent
        :id="id"
        class="base-markdown-editor__scroller"
        :editor="editor"
      />
    </div>
    <div class="base-textarea__footer">
      <p
        :id="errorId"
        class="base-textarea__error"
        :class="{ 'base-textarea__error--shown': hasErrors }"
        role="alert"
      >
        <span>{{ errorMessage }}</span>
      </p>
      <span
        v-if="maxlength"
        :id="counterId"
        class="base-textarea__counter"
        :class="{ 'base-textarea__counter--over': overLimit }"
        :data-test="`counter-${name}`"
      >
        {{ characterCount }} / {{ maxlength }}
      </span>
    </div>
  </div>
</template>

<style lang="scss" scoped>
@import "index";
</style>

<style lang="scss">
@import "@/shared/components/Markdown/content";
</style>
