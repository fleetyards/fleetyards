import type { App, Directive, DirectiveBinding } from "vue";

interface TooltipOptions {
  content: string | false;
  placement: string;
  popperClass?: string;
}

function parseBinding(binding: DirectiveBinding): TooltipOptions {
  const modifiers = Object.keys(binding.modifiers);
  const placement = modifiers[0] || "top";

  if (binding.value && typeof binding.value === "object") {
    return {
      content: binding.value.content,
      placement: binding.value.placement || placement,
      popperClass: binding.value.popperClass,
    };
  }

  return {
    content: binding.value || false,
    placement,
  };
}

const ARROW_SIZE = 6;

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
    "transition:opacity .15s ease",
  ].join(";");
  el.textContent = String(options.content);

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
}

interface TooltipState {
  tooltipEl: HTMLElement | null;
  options: TooltipOptions;
  showHandler: () => void;
  hideHandler: () => void;
  scrollHandler: () => void;
  scrollParents: EventTarget[];
}

const stateMap = new WeakMap<HTMLElement, TooltipState>();

function getScrollParents(el: HTMLElement): EventTarget[] {
  const parents: EventTarget[] = [window];
  let current: HTMLElement | null = el.parentElement;

  while (current) {
    const { overflow, overflowX, overflowY } = getComputedStyle(current);
    if (/(auto|scroll|overlay)/.test(overflow + overflowX + overflowY)) {
      parents.push(current);
    }
    current = current.parentElement;
  }

  return parents;
}

function show(el: HTMLElement) {
  const state = stateMap.get(el);
  if (!state || !state.options.content) return;

  if (!state.tooltipEl) {
    state.tooltipEl = createTooltipEl(state.options);
  }

  const tip = state.tooltipEl;

  // Update text (keep arrow element)
  const arrow = tip.querySelector("[data-tooltip-arrow]");
  tip.textContent = String(state.options.content);
  if (arrow) tip.appendChild(arrow);

  // Measure at 0 opacity
  tip.style.opacity = "0";
  tip.style.display = "block";

  positionTooltip(el, tip, state.options.placement);

  // Fade in
  requestAnimationFrame(() => {
    tip.style.opacity = "1";
  });

  state.scrollParents = getScrollParents(el);
  for (const parent of state.scrollParents) {
    parent.addEventListener("scroll", state.scrollHandler, { passive: true });
  }
}

function hide(el: HTMLElement) {
  const state = stateMap.get(el);
  if (!state?.tooltipEl) return;

  state.tooltipEl.style.opacity = "0";

  for (const parent of state.scrollParents) {
    parent.removeEventListener("scroll", state.scrollHandler);
  }
  state.scrollParents = [];
}

function cleanup(el: HTMLElement) {
  const state = stateMap.get(el);
  if (!state) return;

  el.removeEventListener("mouseenter", state.showHandler);
  el.removeEventListener("mouseleave", state.hideHandler);
  el.removeEventListener("focus", state.showHandler);
  el.removeEventListener("blur", state.hideHandler);

  for (const parent of state.scrollParents) {
    parent.removeEventListener("scroll", state.scrollHandler);
  }

  state.tooltipEl?.remove();
  stateMap.delete(el);
}

const vTooltip: Directive = {
  mounted(el: HTMLElement, binding: DirectiveBinding) {
    const options = parseBinding(binding);

    const state: TooltipState = {
      tooltipEl: null,
      options,
      showHandler: () => show(el),
      hideHandler: () => hide(el),
      scrollHandler: () => hide(el),
      scrollParents: [],
    };

    stateMap.set(el, state);

    el.addEventListener("mouseenter", state.showHandler);
    el.addEventListener("mouseleave", state.hideHandler);
    el.addEventListener("focus", state.showHandler);
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
