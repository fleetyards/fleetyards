<script lang="ts">
export default {
  name: "FormMarkdownEditor",
};
</script>

<script lang="ts" setup>
import { EditorContent, useEditor } from "@tiptap/vue-3";
import { BubbleMenu } from "@tiptap/vue-3/menus";
import type { Editor as TiptapEditor } from "@tiptap/core";
import HintIcon from "@/shared/components/base/HintIcon/index.vue";
import { defineAsyncComponent, type MaybeRef } from "vue";
import { useField, type RuleExpression } from "vee-validate";
import { v4 as uuidv4 } from "uuid";
import { useI18n } from "@/shared/composables/useI18n";
import LinkPanel from "./LinkPanel.vue";
import ImageSizePanel from "./ImageSizePanel.vue";
import type { MarkdownImageCreate } from "./ImageDialog.vue";
import type { CatalogueSearch } from "./catalogueTokens";
import {
  markdownExtensions,
  protectHtml,
  toMarkdown,
  type ImageSize,
} from "./extensions";

// Loaded when an image is first inserted: the uploader it holds is not small,
// and most edits never need it.
const ImageDialog = defineAsyncComponent(() => import("./ImageDialog.vue"));

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
  // Turns an uploaded image into the address to embed; the upload endpoint by
  // default.
  createImage?: MarkdownImageCreate;
  // Finds the catalogue items a `[*` token can name; the catalogue search by
  // default.
  searchCatalogue?: CatalogueSearch;
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
  createImage: undefined,
  searchCatalogue: undefined,
});

const emit = defineEmits(["update:modelValue"]);

const { t } = useI18n();

const id = `${props.name}-${uuidv4()}`;
const labelId = `${id}-label`;
const errorId = `${id}-error`;
const counterId = `${id}-counter`;

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

// What was last loaded, and what the editor writes for it. The two differ --
// the editor escapes characters and adds a paragraph to type into after a
// closing block -- so a transaction that changes nothing a reader would see
// (focusing the text is one) would otherwise hand the form a rewritten copy,
// and mark it changed without anyone touching it.
let loaded = props.modelValue ?? "";
let loadedAs: string | undefined;

const setMarkdown = (markdown: string) => {
  if (markdown === emitted) return;

  emitted = markdown;
  handleChange(markdown);
  emit("update:modelValue", markdown);
};

const editor = useEditor({
  extensions: markdownExtensions({ searchCatalogue: props.searchCatalogue }),
  content: protectHtml(props.modelValue ?? ""),
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
  onCreate: ({ editor: instance }) => {
    loadedAs = toMarkdown(instance);
  },
  onUpdate: ({ editor: instance }) => {
    const markdown = toMarkdown(instance);

    setMarkdown(markdown === loadedAs ? loaded : markdown);
  },
  onBlur: () => {
    handleBlur(undefined, true);
  },
});

const loadIntoEditor = (markdown: string) => {
  editor.value?.commands.setContent(protectHtml(markdown), {
    contentType: "markdown",
    emitUpdate: false,
  });

  loaded = markdown;
  loadedAs = editor.value ? toMarkdown(editor.value) : undefined;
};

// The markdown as written, for anyone who would rather type it than click it.
// Switching back hands the text to the editor, which shows what it means.
const sourceMode = ref(false);
const source = ref("");

const toggleSource = () => {
  if (sourceMode.value) {
    loadIntoEditor(source.value);
    sourceMode.value = false;
    void nextTick(() => editor.value?.commands.focus());
    return;
  }

  closePanels();
  source.value = inputValue.value ?? "";
  sourceMode.value = true;
};

const onSourceInput = (event: Event) => {
  source.value = (event.target as HTMLTextAreaElement).value;
  setMarkdown(source.value);
};

watch(
  () => props.modelValue,
  (value) => {
    if ((value ?? null) !== emitted) {
      emitted = value ?? null;
      source.value = value ?? "";
      loadIntoEditor(value ?? "");
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
    key: "item",
    icon: "fa-regular fa-cube",
    isActive: () => false,
    // Opens the item search, as typing the two characters would.
    run: () => chain().insertContent("[*").run(),
  },
  {
    key: "center",
    icon: "fa-regular fa-align-center",
    isActive: () => !!editor.value?.isActive("center"),
    run: () => chain().toggleCenter().run(),
  },
];

const panel = ref<"link">();
const imageDialogOpen = ref(false);

const closePanels = () => {
  panel.value = undefined;
};

const togglePanel = (name: "link") => {
  if (panel.value === name) {
    closePanel();
    return;
  }

  panel.value = name;
};

const closePanel = () => {
  closePanels();
  editor.value?.commands.focus();
};

const linkActive = computed(() => !!editor.value?.isActive("link"));

const linkHref = () =>
  (editor.value?.getAttributes("link").href as string | undefined) ?? "";

const applyLink = (url: string) => {
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

  closePanels();
};

const removeLink = () => {
  chain().extendMarkRange("link").unsetLink().run();
  closePanels();
};

const openImageDialog = () => {
  closePanels();
  imageDialogOpen.value = true;
};

const closeImageDialog = () => {
  imageDialogOpen.value = false;
  editor.value?.commands.focus();
};

// A selected image offers its size in a small toolbar over it -- while the
// text is being edited, not because a description opens on an image.
const imageSizeToolbar = ref<InstanceType<typeof ImageSizePanel>>();

// Focus inside the toolbar counts as editing too: a keyboard user tabs from
// the image into its buttons, and the text no longer has focus then.
const showImageSize = ({
  editor: instance,
  view,
}: {
  editor: TiptapEditor;
  view: TiptapEditor["view"];
}) =>
  instance.isEditable &&
  !props.disabled &&
  !sourceMode.value &&
  instance.isActive("image") &&
  (view.hasFocus() || !!imageSizeToolbar.value?.containsFocus());

// The menu plugin makes its wrapper a tab stop of its own, which would leave an
// empty stop between the image and the buttons. It hands focus on instead:
// into the buttons coming from the text, back to the text coming out of them.
const onImageSizeWrapperFocus = (event: FocusEvent) => {
  if (imageSizeToolbar.value?.contains(event.relatedTarget as Node | null)) {
    editor.value?.commands.focus();
    return;
  }

  imageSizeToolbar.value?.focusFirst();
};

// Inside the image's top edge rather than above it: above, it would sit on the
// editor's own toolbar whenever the image is at the top of the text.
const imageSizeMenuOptions = {
  placement: "top" as const,
  offset: -44,
  shift: { padding: 8 },
};

const imageSize = computed(
  () => (editor.value?.getAttributes("image").size as ImageSize | null) ?? null,
);

const setImageSize = (size: ImageSize | null) => {
  if (props.disabled) return;

  editor.value?.chain().updateAttributes("image", { size }).run();
};

// The dialog closes itself after an insert, once its animation has run.
const insertImage = (image: { src: string; alt?: string }) => {
  chain().setImage(image).run();
};

const focusEditor = () => {
  if (sourceMode.value) {
    sourceInput.value?.focus();
  } else {
    editor.value?.commands.focus();
  }
};

const sourceInput = ref<HTMLTextAreaElement>();

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
          :class="{
            'base-markdown-editor__action--active':
              !sourceMode && action.isActive(),
          }"
          :aria-pressed="!sourceMode && action.isActive()"
          :aria-label="t(`markdownEditor.${action.key}`)"
          :disabled="disabled || sourceMode"
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
          :class="{
            'base-markdown-editor__action--active': !sourceMode && linkActive,
          }"
          :aria-pressed="!sourceMode && linkActive"
          :aria-expanded="panel === 'link'"
          :aria-label="t('markdownEditor.link')"
          :disabled="disabled || sourceMode"
          data-test="markdown-editor-link"
          @mousedown.prevent
          @click="togglePanel('link')"
        >
          <i class="fa-regular fa-link" />
        </button>
        <button
          v-tooltip.bottom="t('markdownEditor.image')"
          type="button"
          class="base-markdown-editor__action"
          aria-haspopup="dialog"
          :aria-label="t('markdownEditor.image')"
          :disabled="disabled || sourceMode"
          data-test="markdown-editor-image"
          @mousedown.prevent
          @click="openImageDialog"
        >
          <i class="fa-regular fa-image" />
        </button>
        <button
          v-tooltip.bottom="t('markdownEditor.source')"
          type="button"
          class="base-markdown-editor__action base-markdown-editor__action--end"
          :class="{ 'base-markdown-editor__action--active': sourceMode }"
          :aria-pressed="sourceMode"
          :aria-label="t('markdownEditor.source')"
          :disabled="disabled"
          data-test="markdown-editor-source"
          @mousedown.prevent
          @click="toggleSource"
        >
          <i class="fa-brands fa-markdown" />
        </button>
      </div>
      <LinkPanel
        v-if="panel === 'link'"
        :name="name"
        :initial-url="linkHref()"
        :active="linkActive"
        @apply="applyLink"
        @remove="removeLink"
        @close="closePanel"
      />
      <Teleport to="body">
        <ImageDialog
          v-if="imageDialogOpen"
          :name="name"
          :create-image="createImage"
          @insert="insertImage"
          @close="closeImageDialog"
        />
      </Teleport>
      <textarea
        v-if="sourceMode"
        :id="`${id}-source`"
        ref="sourceInput"
        class="base-markdown-editor__scroller base-markdown-editor__source"
        :value="source"
        :aria-labelledby="labelId"
        :aria-describedby="describedBy"
        :disabled="disabled"
        spellcheck="false"
        :data-test="`source-${name}`"
        @input="onSourceInput"
        @blur="handleBlur(undefined, true)"
      />
      <BubbleMenu
        v-if="editor"
        :editor="editor"
        plugin-key="markdownEditorImageSize"
        @focus="onImageSizeWrapperFocus"
        :should-show="showImageSize"
        :update-delay="0"
        :options="imageSizeMenuOptions"
      >
        <ImageSizePanel
          ref="imageSizeToolbar"
          :size="imageSize"
          :disabled="disabled"
          @select="setImageSize"
        />
      </BubbleMenu>
      <EditorContent
        v-show="!sourceMode"
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
