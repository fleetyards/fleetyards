// The server's limits on each line of a plaque.
export const PLAQUE_LIMITS = {
  dedication: 150,
  dedicationVerse: 500,
  line: 100,
  captain: 50,
};

export const PLAQUE_FIELD_RULES = {
  // Without one there is no plaque, and the other lines would save to nothing.
  dedication: `required|max:${PLAQUE_LIMITS.dedication}`,
  dedicationVerse: `max:${PLAQUE_LIMITS.dedicationVerse}`,
  launchPort: `max:${PLAQUE_LIMITS.line}`,
  affiliation: `max:${PLAQUE_LIMITS.line}`,
  plaqueCaptain: `max:${PLAQUE_LIMITS.captain}`,
};
