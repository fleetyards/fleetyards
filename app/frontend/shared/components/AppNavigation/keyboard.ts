/*
 * What one press of an arrow key walks along. A panel is a list of its own, so
 * the rail skips the rows of a panel open beside it and a panel never runs out
 * into the rail. A section unfolded in place shares its parent's list, the way
 * it reads on screen.
 */
const LIST_LEVEL = ".nav-flyout, .nav-menu__panel, .app-navigation__inner";

export const hasModifier = (event: KeyboardEvent) =>
  event.altKey || event.ctrlKey || event.metaKey || event.shiftKey;

/*
 * A folding list stays displayed until its animation ends, and a row focused in
 * that window loses the focus to the top of the document when it does. The
 * section's own trigger already says it is shut.
 */
const inFoldedSection = (row: HTMLElement) => {
  let section = row.closest("ul")?.closest(".nav-item__sub-menu");

  while (section) {
    if (section.querySelector(':scope > button[aria-expanded="false"]')) {
      return true;
    }

    section = section.closest("ul")?.closest(".nav-item__sub-menu");
  }

  return false;
};

export const focusableRows = (container: Element | null | undefined) =>
  Array.from(
    container?.querySelectorAll<HTMLElement>(
      "a[href], button:not([disabled])",
    ) ?? [],
  ).filter((row) => row.getClientRects().length && !inFoldedSection(row));

export const navRows = (container: Element | null | undefined) => {
  const level = container?.closest(LIST_LEVEL);

  return focusableRows(container).filter(
    (row) => level && row.closest(LIST_LEVEL) === level,
  );
};

export const focusEdgeRow = (
  container: Element | null | undefined,
  edge: "first" | "last",
) => {
  const rows = navRows(container);

  rows[edge === "first" ? 0 : rows.length - 1]?.focus();
};

export const moveRowFocus = (event: KeyboardEvent) => {
  if (event.defaultPrevented || hasModifier(event)) {
    return;
  }

  const current = event.target as HTMLElement;
  const rows = navRows(current.closest(LIST_LEVEL));
  const index = rows.indexOf(current);

  if (index < 0) {
    return;
  }

  const targets: Record<string, number> = {
    ArrowDown: (index + 1) % rows.length,
    ArrowUp: (index - 1 + rows.length) % rows.length,
    Home: 0,
    End: rows.length - 1,
  };

  const target = targets[event.key];

  if (target === undefined) {
    return;
  }

  event.preventDefault();
  rows[target].focus();
};

// The drawer covers the page, so Tab stays in it until Escape closes it.
export const containTab = (event: KeyboardEvent, container: Element | null) => {
  if (event.key !== "Tab" || !container?.contains(event.target as Node)) {
    return;
  }

  const rows = focusableRows(container);
  const edge = event.shiftKey ? rows[0] : rows[rows.length - 1];

  if (event.target === edge) {
    event.preventDefault();
    (event.shiftKey ? rows[rows.length - 1] : rows[0])?.focus();
  }
};
