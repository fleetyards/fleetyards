/*
 * What one press of an arrow key walks along. A panel is a list of its own, so
 * the rail skips the rows of a panel open beside it and a panel never runs out
 * into the rail. A section unfolded in place shares its parent's list, the way
 * it reads on screen.
 */
const LIST_LEVEL = ".nav-flyout, .nav-menu__panel, .app-navigation__inner";

export const hasModifier = (event: KeyboardEvent) =>
  event.altKey || event.ctrlKey || event.metaKey || event.shiftKey;

export const navRows = (container: Element | null | undefined) => {
  const level = container?.closest(LIST_LEVEL);

  if (!container || !level) {
    return [];
  }

  return Array.from(
    container.querySelectorAll<HTMLElement>("a[href], button:not([disabled])"),
  ).filter(
    (row) => row.closest(LIST_LEVEL) === level && row.getClientRects().length,
  );
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
