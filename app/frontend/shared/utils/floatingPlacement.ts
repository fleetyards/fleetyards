export type FloatingPlacement = "top" | "bottom" | "left" | "right";

export interface FloatingPosition {
  top: number;
  left: number;
  placement: FloatingPlacement;
}

interface FloatingOptions {
  // Space between the anchor and the box.
  gap?: number;
  // How close to the viewport edge the box may go.
  margin?: number;
  // Move a top/bottom box to the other side when it does not fit and the other
  // side has more room. Off by default: a one-line tooltip always fits, and
  // jumping sides between two hovers of the same anchor reads as jitter.
  flip?: boolean;
  // Move a top/bottom box beside the anchor when it fits on neither, rather than
  // sliding it back inside the viewport and over the anchor. It then runs down
  // from the anchor's top, as far as the viewport lets it.
  sideways?: boolean;
  avoidOverlap?: boolean;
  // The sides avoidOverlap may move the box to.
  sides?: FloatingPlacement[];
}

interface Size {
  width: number;
  height: number;
}

const flipped = (
  anchor: DOMRect,
  box: Size,
  placement: FloatingPlacement,
  gap: number,
  margin: number,
): FloatingPlacement => {
  const below = window.innerHeight - anchor.bottom - gap - margin;
  const above = anchor.top - gap - margin;

  if (placement === "bottom" && box.height > below && above > below) {
    return "top";
  }

  if (placement === "top" && box.height > above && below > above) {
    return "bottom";
  }

  return placement;
};

const besideAnchor = (
  anchor: DOMRect,
  box: Size,
  placement: FloatingPlacement,
  gap: number,
  margin: number,
): FloatingPlacement => {
  const roomFor = (space: number, size: number) => size <= space - gap - margin;

  if (placement === "bottom" || placement === "top") {
    const fits =
      placement === "bottom"
        ? roomFor(window.innerHeight - anchor.bottom, box.height)
        : roomFor(anchor.top, box.height);

    if (fits) return placement;
    if (roomFor(window.innerWidth - anchor.right, box.width)) return "right";
    if (roomFor(anchor.left, box.width)) return "left";
  }

  return placement;
};

/*
 * Where a floating box goes beside its anchor, in viewport coordinates for a
 * `position: fixed` box. Centred on the anchor along the other axis, then slid
 * back inside the viewport -- never shrunk, so a box wider than the window runs
 * off the side rather than wrapping.
 *
 * An unknown placement is treated as `top`, which is what `v-tooltip` has
 * always done with a modifier it does not recognise.
 */
export const placeFloating = (
  anchor: DOMRect,
  box: Size,
  requested: string,
  {
    gap = 8,
    margin = 4,
    flip = false,
    sideways = false,
    avoidOverlap = false,
    sides = ["bottom", "top", "right", "left"],
  }: FloatingOptions = {},
): FloatingPosition => {
  if (avoidOverlap) {
    const candidates = [requested, ...sides].map((side) =>
      placeFloating(anchor, box, side, { gap, margin }),
    );
    const overlap = ({ top, left }: FloatingPosition) =>
      Math.max(
        0,
        Math.min(left + box.width, anchor.right + gap) -
          Math.max(left, anchor.left - gap),
      ) *
      Math.max(
        0,
        Math.min(top + box.height, anchor.bottom + gap) -
          Math.max(top, anchor.top - gap),
      );

    return candidates.reduce((best, candidate) =>
      overlap(candidate) < overlap(best) ? candidate : best,
    );
  }

  let placement: FloatingPlacement = ["bottom", "left", "right"].includes(
    requested,
  )
    ? (requested as FloatingPlacement)
    : "top";

  if (flip) placement = flipped(anchor, box, placement, gap, margin);

  const preferred = placement;

  if (sideways) placement = besideAnchor(anchor, box, placement, gap, margin);

  let top = 0;
  let left = 0;

  switch (placement) {
    case "bottom":
      top = anchor.bottom + gap;
      left = anchor.left + anchor.width / 2 - box.width / 2;
      break;
    case "left":
      top = anchor.top + anchor.height / 2 - box.height / 2;
      left = anchor.left - box.width - gap;
      break;
    case "right":
      top = anchor.top + anchor.height / 2 - box.height / 2;
      left = anchor.right + gap;
      break;
    default:
      top = anchor.top - box.height - gap;
      left = anchor.left + anchor.width / 2 - box.width / 2;
      break;
  }

  // Moved aside from below or above, it still reads down from the anchor rather
  // than centring on it.
  if (placement !== preferred) top = anchor.top;

  return {
    placement,
    left: Math.max(
      margin,
      Math.min(left, window.innerWidth - box.width - margin),
    ),
    top: Math.max(
      margin,
      Math.min(top, window.innerHeight - box.height - margin),
    ),
  };
};
