import type { App, Directive, DirectiveBinding } from "vue";

interface TooltipOptions {
  content: string | false;
  placement: string;
  popperClass?: string;
  html?: boolean;
}

function parseBinding(binding: DirectiveBinding): TooltipOptions {
  const modifiers = Object.keys(binding.modifiers);
  const placement = modifiers[0] || "top";

  if (binding.value && typeof binding.value === "object") {
    return {
      content: binding.value.content,
      placement: binding.value.placement || placement,
      popperClass: binding.value.popperClass,
      html: binding.value.html,
    };
  }

  return {
    content: binding.value || false,
    placement,
  };
}

// Callers pass formatted i18n strings that carry markup — `toUEC` wraps its unit
// in a muted span — so without this the tags render as literal text.
function setContent(el: HTMLElement, options: TooltipOptions) {
  if (options.html) {
    el.innerHTML = String(options.content);

    return;
  }

  el.textContent = String(options.content);
}

const ARROW_SIZE = 6;
const FADE_DURATION = 150;

function createTooltipEl(options: TooltipOptions): HTMLElement {
  const el = document.createElement("div");
  el.setAttribute("data-tooltip", "");
  el.style.cssText = [
    "position:fixed",
    "z-index:10000",
    "pointer-events:none",
    "padding:7px 12px 6px",
    "color:#fff",
    "background:#272b30",
    "border-radius:6px",
    "font-size:14px",
    "line-height:1.4",
    "white-space:nowrap",
    "opacity:0",
    "display:none",
    `transition:opacity ${FADE_DURATION}ms ease`,
  ].join(";");
  setContent(el, options);

  const arrow = document.createElement("div");
  arrow.setAttribute("data-tooltip-arrow", "");
  arrow.style.cssText = [
    "position:absolute",
    "width:0",
    "height:0",
    "border-style:solid",
    `border-width:${ARROW_SIZE}px`,
    "border-color:transparent",
  ].join(";");
  el.appendChild(arrow);

  if (options.popperClass) {
    el.classList.add(options.popperClass);
  }

  document.body.appendChild(el);
  return el;
}

function positionArrow(tooltip: HTMLElement, placement: string) {
  const arrow = tooltip.querySelector(
    "[data-tooltip-arrow]",
  ) as HTMLElement | null;
  if (!arrow) return;

  // Reset all positioning
  arrow.style.top = "";
  arrow.style.bottom = "";
  arrow.style.left = "";
  arrow.style.right = "";
  arrow.style.borderColor = "transparent";

  switch (placement) {
    case "bottom":
      arrow.style.top = `${-ARROW_SIZE * 2}px`;
      arrow.style.left = `calc(50% - ${ARROW_SIZE}px)`;
      arrow.style.borderBottomColor = "#272b30";
      break;
    case "left":
      arrow.style.top = `calc(50% - ${ARROW_SIZE}px)`;
      arrow.style.right = `${-ARROW_SIZE * 2}px`;
      arrow.style.borderLeftColor = "#272b30";
      break;
    case "right":
      arrow.style.top = `calc(50% - ${ARROW_SIZE}px)`;
      arrow.style.left = `${-ARROW_SIZE * 2}px`;
      arrow.style.borderRightColor = "#272b30";
      break;
    default: // top
      arrow.style.bottom = `${-ARROW_SIZE * 2}px`;
      arrow.style.left = `calc(50% - ${ARROW_SIZE}px)`;
      arrow.style.borderTopColor = "#272b30";
      break;
  }
}

function positionTooltip(
  target: HTMLElement,
  tooltip: HTMLElement,
  placement: string,
) {
  const rect = target.getBoundingClientRect();
  const tooltipRect = tooltip.getBoundingClientRect();
  const gap = 8;
  const margin = 4;

  let top = 0;
  let left = 0;

  switch (placement) {
    case "bottom":
      top = rect.bottom + gap;
      left = rect.left + rect.width / 2 - tooltipRect.width / 2;
      break;
    case "left":
      top = rect.top + rect.height / 2 - tooltipRect.height / 2;
      left = rect.left - tooltipRect.width - gap;
      break;
    case "right":
      top = rect.top + rect.height / 2 - tooltipRect.height / 2;
      left = rect.right + gap;
      break;
    default: // top
      top = rect.top - tooltipRect.height - gap;
      left = rect.left + rect.width / 2 - tooltipRect.width / 2;
      break;
  }

  left = Math.max(
    margin,
    Math.min(left, window.innerWidth - tooltipRect.width - margin),
  );
  top = Math.max(
    margin,
    Math.min(top, window.innerHeight - tooltipRect.height - margin),
  );

  tooltip.style.top = `${top}px`;
  tooltip.style.left = `${left}px`;

  positionArrow(tooltip, placement);

  return rect;
}

interface TooltipState {
  tooltipEl: HTMLElement | null;
  options: TooltipOptions;
  showHandler: () => void;
  hideHandler: () => void;
  focusHandler: () => void;
  fadeFrame: number;
  hideTimer: number;
  anchorRect: DOMRect | null;
}

const stateMap = new WeakMap<HTMLElement, TooltipState>();

// Only one tooltip is ever on screen, so a single anchor watcher and one set of
// global listeners cover whichever is currently up.
let activeEl: HTMLElement | null = null;
let watchFrame = 0;

function anchorMoved(previous: DOMRect, next: DOMRect) {
  return (
    Math.abs(next.top - previous.top) > 0.5 ||
    Math.abs(next.left - previous.left) > 0.5 ||
    Math.abs(next.width - previous.width) > 0.5 ||
    Math.abs(next.height - previous.height) > 0.5
  );
}

// A tooltip is only ever correct for the anchor's current box. Scrolling and
// reflow move that box, and an anchor can be hidden or torn down outside Vue
// without ever firing a leave event — in which case the tooltip would be left
// hanging in mid-air.
function watchAnchor() {
  watchFrame = requestAnimationFrame(() => {
    watchFrame = 0;

    const el = activeEl;
    if (!el) return;

    const state = stateMap.get(el);
    if (!state?.tooltipEl || !state.anchorRect) return;

    const rect = el.getBoundingClientRect();
    if (!el.isConnected || (!rect.width && !rect.height)) {
      hide(el);
      return;
    }

    if (anchorMoved(state.anchorRect, rect)) {
      state.anchorRect = positionTooltip(
        el,
        state.tooltipEl,
        state.options.placement,
      );
    }

    watchAnchor();
  });
}

function onPointerOver(event: Event) {
  const el = activeEl;
  if (!el) return;

  const target = event.target as Node | null;
  if (target && (el === target || el.contains(target))) return;

  hide(el);
}

function onKeydown(event: KeyboardEvent) {
  if (event.key === "Escape" && activeEl) hide(activeEl);
}

function onWindowHide() {
  if (activeEl) hide(activeEl);
}

function addGlobalListeners() {
  document.addEventListener("pointerover", onPointerOver, true);
  document.addEventListener("keydown", onKeydown, true);
  document.addEventListener("visibilitychange", onWindowHide);
  window.addEventListener("blur", onWindowHide);
}

function removeGlobalListeners() {
  document.removeEventListener("pointerover", onPointerOver, true);
  document.removeEventListener("keydown", onKeydown, true);
  document.removeEventListener("visibilitychange", onWindowHide);
  window.removeEventListener("blur", onWindowHide);
}

function deactivate() {
  if (watchFrame) {
    cancelAnimationFrame(watchFrame);
    watchFrame = 0;
  }

  activeEl = null;
  removeGlobalListeners();
}

function show(el: HTMLElement) {
  const state = stateMap.get(el);
  if (!state || !state.options.content || !el.isConnected) return;

  if (activeEl && activeEl !== el) hide(activeEl);

  if (!state.tooltipEl) {
    state.tooltipEl = createTooltipEl(state.options);
  }

  const tip = state.tooltipEl;

  // Update text (keep arrow element)
  const arrow = tip.querySelector("[data-tooltip-arrow]");
  setContent(tip, state.options);
  if (arrow) tip.appendChild(arrow);

  window.clearTimeout(state.hideTimer);

  // Measure at 0 opacity
  tip.style.opacity = "0";
  tip.style.display = "block";

  state.anchorRect = positionTooltip(el, tip, state.options.placement);

  activeEl = el;
  addGlobalListeners();

  // Fade in
  if (state.fadeFrame) cancelAnimationFrame(state.fadeFrame);
  state.fadeFrame = requestAnimationFrame(() => {
    state.fadeFrame = 0;
    // A hide within the same frame must win, otherwise the tooltip fades back
    // in with nothing left to dismiss it.
    if (activeEl !== el) return;
    tip.style.opacity = "1";
  });

  if (!watchFrame) watchAnchor();
}

function hide(el: HTMLElement) {
  if (activeEl === el) deactivate();

  const state = stateMap.get(el);
  if (!state?.tooltipEl) return;

  if (state.fadeFrame) {
    cancelAnimationFrame(state.fadeFrame);
    state.fadeFrame = 0;
  }

  const tip = state.tooltipEl;
  tip.style.opacity = "0";
  state.anchorRect = null;

  window.clearTimeout(state.hideTimer);
  state.hideTimer = window.setTimeout(() => {
    tip.style.display = "none";
  }, FADE_DURATION);
}

function cleanup(el: HTMLElement) {
  const state = stateMap.get(el);
  if (!state) return;

  if (activeEl === el) deactivate();

  el.removeEventListener("mouseenter", state.showHandler);
  el.removeEventListener("mouseleave", state.hideHandler);
  el.removeEventListener("pointerleave", state.hideHandler);
  el.removeEventListener("click", state.hideHandler);
  el.removeEventListener("focus", state.focusHandler);
  el.removeEventListener("blur", state.hideHandler);

  if (state.fadeFrame) cancelAnimationFrame(state.fadeFrame);
  window.clearTimeout(state.hideTimer);

  state.tooltipEl?.remove();
  stateMap.delete(el);
}

// Pointer focus already gets the tooltip from `mouseenter`; showing it on every
// focus also pops one up when focus is restored after a modal closes, far away
// from the cursor.
function isKeyboardFocus(el: HTMLElement) {
  try {
    return el.matches(":focus-visible");
  } catch {
    return true;
  }
}

const vTooltip: Directive = {
  mounted(el: HTMLElement, binding: DirectiveBinding) {
    cleanup(el);

    const options = parseBinding(binding);

    const state: TooltipState = {
      tooltipEl: null,
      options,
      showHandler: () => show(el),
      hideHandler: () => hide(el),
      focusHandler: () => {
        if (isKeyboardFocus(el)) show(el);
      },
      fadeFrame: 0,
      hideTimer: 0,
      anchorRect: null,
    };

    stateMap.set(el, state);

    el.addEventListener("mouseenter", state.showHandler);
    el.addEventListener("mouseleave", state.hideHandler);
    el.addEventListener("pointerleave", state.hideHandler);
    el.addEventListener("click", state.hideHandler);
    el.addEventListener("focus", state.focusHandler);
    el.addEventListener("blur", state.hideHandler);
  },

  updated(el: HTMLElement, binding: DirectiveBinding) {
    const state = stateMap.get(el);
    if (!state) return;

    state.options = parseBinding(binding);

    if (state.tooltipEl && !state.options.content) {
      hide(el);
    }
  },

  beforeUnmount(el: HTMLElement) {
    cleanup(el);
  },
};

export default {
  install(app: App) {
    app.directive("tooltip", vTooltip);
  },
};
