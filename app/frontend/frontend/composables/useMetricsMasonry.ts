import { onBeforeUnmount, onMounted, watch, type Ref } from "vue";

// Masonry packing for the metrics cards: each card spans as many rows of a
// fine-grained grid as it is tall, which lets `grid-auto-flow: dense` backfill a
// short column with a later card. Multi-column flow cannot do this — it fills
// columns in document order, so a card can never move up into an earlier column
// and every short column keeps its gap.
const ROW_HEIGHT = 4;
// Counted into the span so the trailing rows of a card's area form the gap to
// the next one; the cards themselves carry no margin in the grid.
const CARD_SPACING = 20;

export function useMetricsMasonry(
  container: Ref<HTMLElement | null | undefined>,
) {
  let resizeObserver: ResizeObserver | undefined;
  let mutationObserver: MutationObserver | undefined;

  const applySpan = (element: Element) => {
    if (!(element instanceof HTMLElement)) {
      return;
    }

    const span = Math.ceil((element.offsetHeight + CARD_SPACING) / ROW_HEIGHT);

    element.style.setProperty("--metrics-card-span", `${span}`);
  };

  const observeChildren = () => {
    if (!resizeObserver) {
      return;
    }

    resizeObserver.disconnect();

    for (const child of container.value?.children || []) {
      resizeObserver.observe(child);
      applySpan(child);
    }
  };

  const attach = () => {
    mutationObserver?.disconnect();

    if (container.value) {
      mutationObserver?.observe(container.value, { childList: true });
    }

    observeChildren();
  };

  onMounted(() => {
    if (typeof ResizeObserver === "undefined") {
      return;
    }

    // eslint-disable-next-line compat/compat
    resizeObserver = new ResizeObserver((entries) => {
      for (const entry of entries) {
        applySpan(entry.target);
      }
    });
    mutationObserver = new MutationObserver(attach);

    attach();
  });

  watch(container, attach);

  onBeforeUnmount(() => {
    resizeObserver?.disconnect();
    mutationObserver?.disconnect();
  });
}
