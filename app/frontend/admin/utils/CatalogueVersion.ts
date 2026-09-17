// A game build names its environment in its version: `4.10.1-ptu.12578875` is
// patch 4.10.1 on ptu, carried by build 12578875. Nothing else records the
// channel a load read from -- the imports ledger has no environment column --
// so anything wanting to say which one a figure came from reads it back out of
// the string.
//
// Both parts after the patch are optional: a version a test writes stops after
// the environment (`4.10.1-ptu`), and one without an environment at all is
// still a patch.

export const patchOf = (version?: string | null): string | undefined =>
  version?.split("-")[0] || undefined;

export const environmentOf = (version?: string | null): string | undefined => {
  const separator = version?.indexOf("-") ?? -1;

  if (!version || separator < 0) {
    return undefined;
  }

  return version.slice(separator + 1).split(".")[0] || undefined;
};
