// Only one popover is ever on screen. Opening one closes whichever was up,
// wherever on the page it lives.
let closeActive: (() => void) | null = null;

export const claimActive = (close: () => void) => {
  if (closeActive && closeActive !== close) closeActive();

  closeActive = close;
};

export const releaseActive = (close: () => void) => {
  if (closeActive === close) closeActive = null;
};
