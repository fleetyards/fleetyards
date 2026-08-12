<script lang="ts">
export default {
  name: "BaseBtn",
};
</script>

<script lang="ts" setup>
import SmallLoader from "@/shared/components/SmallLoader/index.vue";
import { type SpinnerAlignment } from "@/shared/components/SmallLoader/index.vue";
import { type RouterLinkProps } from "vue-router";
import {
  BtnTypesEnum,
  BtnVariantsEnum,
  BtnTonesEnum,
  BtnSizesEnum,
} from "@/shared/components/base/Btn/types";
import { BTN_CONTAINER } from "@/shared/components/base/Btn/context";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";
import { useI18n } from "@/shared/composables/useI18n";

export type Props = {
  to?: RouterLinkProps["to"];
  href?: string;
  target?: HTMLAnchorElement["target"];
  type?: `${BtnTypesEnum}`;
  loading?: boolean;
  spinner?: boolean | `${SpinnerAlignment}`;
  variant?: `${BtnVariantsEnum}`;
  tone?: `${BtnTonesEnum}`;
  /** Defaults to `sm`, or to the size set by a containing BtnGroup. */
  size?: `${BtnSizesEnum}`;
  block?: boolean;
  mobileIconOnly?: boolean;
  active?: boolean;
  disabled?: boolean;
  confirm?: boolean | string;
};

const props = withDefaults(defineProps<Props>(), {
  to: undefined,
  href: undefined,
  target: undefined,
  type: BtnTypesEnum.BUTTON,
  loading: false,
  spinner: false,
  variant: BtnVariantsEnum.SOLID,
  tone: BtnTonesEnum.NEUTRAL,
  size: undefined,
  block: false,
  mobileIconOnly: false,
  active: false,
  disabled: false,
  confirm: false,
});

const emit = defineEmits(["click"]);

const { t } = useI18n();

const container = inject(BTN_CONTAINER, null);

const size = computed(
  () => props.size ?? container?.size.value ?? BtnSizesEnum.SM,
);

const internalDisabled = ref(props.disabled);

watch(
  () => props.disabled,
  (value) => {
    internalDisabled.value = value;
  },
);

onMounted(() => {
  if (props.confirm && props.type === BtnTypesEnum.SUBMIT) {
    throw new Error(
      "BaseBtn: 'confirm' prop is not supported with type 'submit'",
    );
  }
});

// A disabled link is not disabled: `disabled` has no effect on <a>, so the old
// component left disabled href buttons fully clickable and focusable. Anything
// disabled renders as a real <button> instead.
const inert = computed(() => internalDisabled.value || props.loading);

const btnType = computed(() => {
  if (inert.value) return "button";

  if (props.to) return "router-link";

  if (props.href) return "a";

  return "button";
});

const btnProps = computed(() => {
  if (inert.value) {
    return { type: props.type, disabled: true };
  }

  if (props.to) {
    return { to: props.to };
  }

  if (props.href) {
    return {
      href: props.href,
      target: props.target ?? "_blank",
      rel: "noopener",
    };
  }

  return { type: props.type };
});

const cssClasses = computed(() => [
  `btn--${props.variant}`,
  `btn--${size.value}`,
  `btn--tone-${props.tone}`,
  {
    "btn--block": props.block,
    "btn--mobile-icon-only": props.mobileIconOnly,
    "btn--grouped": container?.container === "group",
    "btn--grouped-block":
      container?.container === "group" && container.block.value,
    "btn--menu-item": container?.container === "menu",
    "is-active": props.active,
    "is-loading": props.loading,
  },
]);

const spinnerAlignment = computed(() =>
  typeof props.spinner === "boolean" ? "right" : props.spinner,
);

const { displayConfirm } = useAppNotifications();

const handleClick = (event: MouseEvent) => {
  if (!props.confirm) {
    emit("click", event);
    return;
  }

  event.preventDefault();
  event.stopPropagation();

  internalDisabled.value = true;

  displayConfirm({
    text: props.confirm === true ? undefined : props.confirm,
    onConfirm: () => {
      internalDisabled.value = false;
      if (props.href) {
        window.open(props.href, props.target ?? "_blank");
      } else {
        emit("click", event);
      }
    },
    onClose: () => {
      internalDisabled.value = false;
    },
  });
};
</script>

<template>
  <component
    :is="btnType"
    class="btn"
    :class="cssClasses"
    :aria-busy="loading || undefined"
    v-bind="btnProps"
    @click="handleClick"
  >
    <span class="btn__content">
      <slot />
    </span>
    <SmallLoader
      v-if="loading && spinner"
      class="btn__loader"
      :loading="loading"
      :alignment="spinnerAlignment"
    />
    <!-- Announced for every loading button, not just the 11 that opt into a
         visible spinner. The visible label is never replaced. -->
    <span v-if="loading" class="btn__status" role="status">
      {{ t("baseBtn.labels.loading") }}
    </span>
  </component>
</template>

<!--
  Plain CSS, not lang="scss", on purpose: @apply and @reference are silently
  dropped when sass preprocesses the block first (they reach the minifier as
  unknown at-rules). Compiling them here inlines each theme token with its
  literal fallback, which is what lets these styles work inside the embed
  bundle, where tailwind.css is never loaded.
-->
<style scoped>
@reference "../../../../entrypoints/tailwind.css";

.btn {
  @apply relative inline-flex items-center justify-center gap-2;
  @apply font-semibold whitespace-nowrap no-underline;
  @apply cursor-pointer border border-transparent bg-transparent;
  @apply transition-[background-color,border-color,color,outline-color] duration-150 ease-in-out;

  /* No margins. The old component shipped margin-right:10px/margin-bottom:20px,
     which is why 112 call sites passed `inline` purely to cancel it. Spacing is
     the parent's job - BtnGroup and page-actions use gap. */
  margin: 0;
}

.btn__content {
  @apply inline-flex items-center gap-2;
  /* min-w-0 lets the label shrink so text-ellipsis can engage inside the flex
     row. leading-tight rather than leading-none: with overflow hidden, a
     line-height of 1 clips glyph descenders - the "p" in "Grouped". */
  @apply min-w-0 overflow-hidden leading-tight text-ellipsis;
}

/*
 * The only remaining :deep rules, and both point at slot content this component
 * is laying out - never at another component's internals. Reaching across a
 * component boundary to restyle it is what produced the 118-line
 * `> :deep(.panel-btn)` override file this redesign deletes; if you need that,
 * add a prop or use BTN_CONTAINER instead.
 */
.btn :deep(img) {
  @apply block max-h-full w-4 max-w-full;
}

/* ---------- sizes ----------
   Heights match the form controls in FormInput (43px, and 55px for its large
   variant) so a button sits flush next to an input, and they preserve the
   historical button scale: old small 42px, default 48px, large 55px. */
.btn--sm {
  @apply h-[43px] px-3.5 text-[13px];
}
.btn--md {
  @apply h-12 px-4.5 text-[14.5px];
}
.btn--lg {
  @apply h-[55px] px-6 text-base;
}

/* ---------- end-caps ----------
   Always present. The inset is proportional so the cap holds a constant share
   of the width instead of collapsing on short buttons: the old fixed 14px each
   side left only 8px of cap on a 36px icon button. The 10px floor keeps it
   clear of the 8px corner radius. */
.btn--solid::before,
.btn--solid::after,
.btn--ghost::before,
.btn--ghost::after {
  content: "";
  position: absolute;
  left: max(10px, 18%);
  right: max(10px, 18%);
  height: 2px;
  @apply bg-endcap rounded-[1px];
  transition: background-color 150ms ease-in-out;
}
.btn--solid::before,
.btn--ghost::before {
  top: -1px;
}
.btn--solid::after,
.btn--ghost::after {
  bottom: -1px;
}
.btn--lg::before,
.btn--lg::after {
  height: 3px;
}

/* ---------- variants ---------- */
.btn--solid {
  @apply bg-control border-edge text-text rounded-control;
}
.btn--ghost {
  @apply border-edge text-text rounded-control bg-transparent;
}
.btn--bare {
  @apply text-text rounded-control-bare border-transparent bg-transparent;
}

.btn--solid:hover:not([disabled]),
.btn--solid.is-active {
  @apply bg-control-hover border-primary text-lifted;
}
.btn--ghost:hover:not([disabled]),
.btn--ghost.is-active {
  @apply bg-control-hover border-primary text-lifted;
}
.btn--bare:hover:not([disabled]),
.btn--bare.is-active {
  @apply text-lifted;
  background-color: rgb(122 130 136 / 0.12);
}

.btn--solid:active:not([disabled]),
.btn--ghost:active:not([disabled]) {
  @apply bg-control-press;
  border-color: rgb(66 139 202 / 0.6);
}

/* ---------- tone ---------- */
.btn--tone-danger.btn--solid,
.btn--tone-danger.btn--ghost {
  border-color: rgb(220 53 69 / 0.55);
  color: #f0a8ae;
}
.btn--tone-danger.btn--bare {
  color: #f0a8ae;
}
.btn--tone-danger.btn--solid:hover:not([disabled]),
.btn--tone-danger.btn--ghost:hover:not([disabled]) {
  @apply bg-danger border-danger text-white;
}
.btn--tone-danger.btn--bare:hover:not([disabled]) {
  @apply text-white;
  background-color: rgb(220 53 69 / 0.18);
}

/* ---------- states ---------- */
.btn[disabled] {
  @apply cursor-default opacity-40;
}

/* The old component set outline:none with no replacement, so keyboard focus was
   invisible. outline follows border-radius and is never clipped, unlike the
   box-shadow ring a clip-path or overflow:hidden parent would crop. */
.btn:focus-visible {
  @apply outline-primary outline-2 outline-offset-2;
}

.btn--block {
  @apply w-full;
}

/* ---------- inside a BtnGroup ----------
   The group draws one border, one radius and one pair of end-caps for the whole
   control, so members carry no chrome at all. Applied here rather than from
   BtnGroup's stylesheet, so Btn owns its own appearance in every context. */
.btn--grouped {
  @apply bg-segment rounded-none border-0;
}
.btn--grouped::before,
.btn--grouped::after {
  content: none;
}
.btn--grouped:hover:not([disabled]) {
  @apply text-lifted;
  background-color: #2b3034;
}
.btn--grouped.is-active,
.btn--grouped[aria-pressed="true"] {
  @apply text-white;
  background-color: rgb(66 139 202 / 0.22);
}
.btn--grouped:focus-visible {
  @apply outline-offset-[-2px];
}

/* Set by BtnGroup via context rather than by a `> :deep(*)` rule from the
   group's stylesheet, so the member still owns its own layout. */
.btn--grouped-block {
  @apply flex-1;
}
/* No :first-child/:last-child radii here on purpose: BtnGroup's inner track
   clips the end corners, so a member never needs to know its position - which
   also survives a member being wrapped by another component. */

/* ---------- inside a BtnDropdown list ---------- */
.btn--menu-item {
  @apply w-full justify-start rounded-none border-0 bg-transparent;
}
.btn--menu-item::before,
.btn--menu-item::after {
  content: none;
}
.btn--menu-item:hover:not([disabled]) {
  @apply text-lifted;
  background-color: rgb(122 130 136 / 0.16);
}

/* ---------- loading ---------- */
/* The label is kept. The old component replaced it with "Loading", which
   changed the accessible name mid-interaction. */
.btn__loader {
  @apply pointer-events-none;
}

.btn__status {
  @apply sr-only;
}

@media (prefers-reduced-motion: reduce) {
  .btn,
  .btn--solid::before,
  .btn--solid::after,
  .btn--ghost::before,
  .btn--ghost::after {
    transition-duration: 1ms;
  }
}

@media (max-width: 992px) {
  /* Visually icon-only, but the label stays in the accessibility tree so the
     button keeps its accessible name. font-size:0 rather than hiding an element,
     because slot labels are usually bare text nodes, not wrapped in a span. */
  .btn--mobile-icon-only {
    @apply px-2.5;
  }

  .btn--mobile-icon-only .btn__content {
    @apply gap-0 text-[0px];
  }

  .btn--mobile-icon-only .btn__content :deep(i),
  .btn--mobile-icon-only .btn__content :deep(svg),
  .btn--mobile-icon-only .btn__content :deep(img) {
    @apply text-base;
  }
}
</style>
