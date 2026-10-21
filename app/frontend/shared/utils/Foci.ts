type FocusSource = {
  fociLabels?: string[] | null;
  stealth?: boolean | null;
};

// A ship's foci as one line to read, with stealth last since it describes the
// hull rather than a job.
export const fociText = (
  model: FocusSource,
  stealthLabel: string,
): string | undefined => {
  const parts = [...(model.fociLabels ?? [])];
  if (model.stealth) parts.push(stealthLabel);

  return parts.length ? parts.join(", ") : undefined;
};
