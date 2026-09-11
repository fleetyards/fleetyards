// Whether a curated dimension disagrees with what the loader read from the game
// files. The two are kept in separate columns and nothing keeps them in step,
// so the admin has to be able to see the difference and take the value over.
//
// A missing game-file value counts as a difference, matching the backend scope:
// a model the filter selected because its `scHeight` is null would otherwise
// show nothing at all on the page it sent the administrator to. There is just
// nothing to take over in that case, which is what `isAppliable` separates.

export const isPresent = (value: unknown): boolean =>
  value !== null && value !== undefined;

export const hasDrifted = (
  current: unknown,
  source?: number | null,
): boolean => {
  if (!isPresent(source)) {
    return isPresent(current);
  }

  return isPresent(current) && Number(current) !== Number(source);
};

export const isAppliable = (
  current: unknown,
  source?: number | null,
): boolean => isPresent(source) && hasDrifted(current, source);
