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
  /**
   * Class the router applies while the link is active. Defaults to the router's
   * global `active`, which Btn styles; pass "" to opt out - the paginator does,
   * so its arrows are not highlighted just because they point at the current page.
   */
  routeActiveClass?: string;
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
  routeActiveClass: undefined,
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
    if (props.routeActiveClass === undefined) return { to: props.to };

    return {
      to: props.to,
      activeClass: props.routeActiveClass,
      exactActiveClass: props.routeActiveClass,
    };
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
    active: props.active,
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
/* min-width matches the height so an icon-only button stays square instead of
   collapsing to the width of its glyph - a fa-ellipsis-v is only a few px wide. */
.btn--sm {
  @apply h-[43px] min-w-[43px] px-3.5 text-[13px];
}
.btn--md {
  @apply h-12 min-w-12 px-4.5 text-[14.5px];
}
.btn--lg {
  @apply h-[55px] min-w-[55px] px-6 text-base;
}

/* ---------- end-caps ----------
   Always present. The inset is proportional so the cap holds a constant share
   of the width instead of collapsing on short buttons: the old fixed 14px each
   side left only 8px of cap on a 36px icon button. The 10px floor keeps it
   clear of the 8px corner radius.

   Geometry comes from the shared --cap-* tokens so a button cap and a panel cap
   are one motif rather than two that drifted. The button's height steps one
   below the panel's, and its radius steps down by the same ratio and is then
   held to half its own height - without that ceiling a 2px cap rounds far
   enough to read as a lozenge rather than a seam. Radius applies to the inward
   edge only, so the outward edge stays a line continuous with the border. */
.btn--solid::before,
.btn--solid::after,
.btn--ghost::before,
.btn--ghost::after {
  content: "";
  position: absolute;
  left: max(10px, var(--cap-inset, 12%));
  right: max(10px, var(--cap-inset, 12%));
  height: var(--cap-h-btn, 2px);
  /* Colour comes through a variable so the interaction states can stay on the
     element - a pseudo-element cannot be selected by :hover/:focus-visible
     without restating the whole selector four times over. The fallbacks are
     spelled out because a bare var() gets none from Tailwind and the embed
     bundle never registers :root. */
  background-color: var(--btn-cap, var(--color-endcap, #7a8288));
  transition: background-color 150ms ease-in-out;
}
.btn--solid::before,
.btn--ghost::before {
  top: -1px;
  border-radius: 0 0 var(--cap-r-btn, 1px) var(--cap-r-btn, 1px);
}
.btn--solid::after,
.btn--ghost::after {
  bottom: -1px;
  border-radius: var(--cap-r-btn, 1px) var(--cap-r-btn, 1px) 0 0;
}
.btn--lg::before {
  height: var(--cap-h-btn-lg, 3px);
  border-radius: 0 0 var(--cap-r-btn-lg, 1.5px) var(--cap-r-btn-lg, 1.5px);
}
.btn--lg::after {
  height: var(--cap-h-btn-lg, 3px);
  border-radius: var(--cap-r-btn-lg, 1.5px) var(--cap-r-btn-lg, 1.5px) 0 0;
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

/*
 * Hover, press and focus light the end-cap and leave the frame alone. Recolouring
 * the border swapped the entire outline of the control, which in a toolbar reads
 * as the button changing shape rather than responding; the cap is already this
 * component's signature, so it is the piece that answers. Same call the panel
 * made for tone - see docs/exec-plans/panel-redesign.md.
 */
.btn--solid:hover:not([disabled]),
.btn--solid.active {
  @apply bg-control-hover text-lifted;
  --btn-cap: var(--color-primary, #428bca);
}
.btn--ghost:hover:not([disabled]),
.btn--ghost.active {
  @apply bg-control-hover text-lifted;
  --btn-cap: var(--color-primary, #428bca);
}
.btn--bare:hover:not([disabled]),
.btn--bare.active {
  @apply text-lifted;
  background-color: rgb(122 130 136 / 0.12);
}

.btn--solid:active:not([disabled]),
.btn--ghost:active:not([disabled]) {
  @apply bg-control-press;
  /* Dimmer than hover, so the press reads as the control receding along with
     its surface rather than as a second, brighter hover. */
  --btn-cap: rgb(66 139 202 / 0.6);
}

/* The outline stays - see the focus rule below. This only brings the cap along,
   so a keyboard-focused button and a hovered one are lit the same way. */
.btn--solid:focus-visible,
.btn--ghost:focus-visible {
  --btn-cap: var(--color-primary, #428bca);
}

/* ---------- tone ----------
 * The cap carries the tone, and only the cap. The frame, the surface and the
 * label all stay exactly as a neutral button's, so a destructive control reads
 * as an ordinary one wearing a red signature. The earlier #f0a8ae label tint is
 * gone: pink text on the neutral surface read as a disabled or error state
 * rather than as an available action.
 *
 * Consequence worth knowing: bare, grouped and menu-item set `content: none` on
 * their caps, so those variants carry no resting marker at all and rely on their
 * hover tint below.
 */
.btn--tone-danger {
  --btn-cap: var(--color-danger, #dc3545);
}
/*
 * A danger button floods on hover, so it cannot borrow the primary cap the
 * neutral states use - blue on that red surface. Its cap follows the label to
 * white instead, which keeps the signature legible through the flood. The
 * tone-plus-variant pair outranks the neutral hover/press/focus rules.
 */
.btn--tone-danger.btn--solid:hover:not([disabled]),
.btn--tone-danger.btn--ghost:hover:not([disabled]) {
  @apply bg-danger border-danger text-white;
  --btn-cap: rgb(255 255 255 / 0.65);
}
.btn--tone-danger.btn--solid:focus-visible,
.btn--tone-danger.btn--ghost:focus-visible {
  --btn-cap: rgb(255 255 255 / 0.65);
}
.btn--tone-danger.btn--bare:hover:not([disabled]) {
  @apply text-white;
  background-color: rgb(220 53 69 / 0.18);
}

/* ---------- states ---------- */
.btn[disabled] {
  @apply cursor-default;
}

/*
 * Dim the content, not the whole element. Element-wide opacity makes an opaque
 * surface translucent, so a disabled member of a BtnGroup let the lighter track
 * show through and read *lighter* than its enabled siblings - the pagination
 * arrows looked highlighted rather than dimmed.
 */
.btn[disabled] .btn__content {
  @apply opacity-45;
}

.btn--solid[disabled],
.btn--ghost[disabled] {
  @apply border-edge-soft;
}

.btn--solid[disabled]::before,
.btn--solid[disabled]::after,
.btn--ghost[disabled]::before,
.btn--ghost[disabled]::after {
  @apply opacity-50;
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
/* Same surface as a standalone button, so a group does not read as a different
   material. The track's fill only shows through the 1px gaps, as dividers. */
.btn--grouped {
  @apply bg-control rounded-none border-0;
}
.btn--grouped::before,
.btn--grouped::after {
  content: none;
}
.btn--grouped:hover:not([disabled]) {
  @apply text-lifted;
  background-color: #2b3034;
}
/* Same reasoning as the menu item: a group member is a flat fill inside one
   shared surface, so flooding it edge to edge breaks the control it sits in. */
.btn--grouped.btn--tone-danger:hover:not([disabled]) {
  @apply text-white;
  background-color: rgb(220 53 69 / 0.35);
}
.btn--grouped.active,
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
/*
 * A menu item has no surface of its own, so the solid variant's danger hover -
 * which floods bg-danger edge to edge - turns a dropdown row into a solid red
 * block. `bare` already carries the tint treatment for exactly this reason; the
 * menu context needs it too, since `variant` defaults to solid and a dropdown
 * item is almost never given one explicitly.
 *
 * Equal specificity to the solid rule, so this has to stay below it.
 */
.btn--menu-item.btn--tone-danger:hover:not([disabled]) {
  @apply text-white;
  background-color: rgb(220 53 69 / 0.18);
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
