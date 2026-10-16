const parts = (version: string) =>
  version
    .replace(/^v/, "")
    .split(".")
    .map((part) => parseInt(part, 10) || 0);

// Several web hosts are rolled one after another, and a rollback goes back down,
// so a version that is merely different is not one to reload into.
export const isNewerVersion = (candidate: string, current: string) => {
  const next = parts(candidate);
  const now = parts(current);

  for (let index = 0; index < Math.max(next.length, now.length); index += 1) {
    const difference = (next[index] ?? 0) - (now[index] ?? 0);

    if (difference !== 0) {
      return difference > 0;
    }
  }

  return false;
};
