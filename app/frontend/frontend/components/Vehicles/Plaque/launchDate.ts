// The game is set 930 years ahead, so a ship launched in October 2026 reads
// as launched in October 2956, the way the plaques in the game date theirs.
export const IN_UNIVERSE_YEAR_OFFSET = 930;

export const inUniverseLaunchDate = (
  launchedOn: string,
  locale: string,
): { month: string; year: number } => {
  const [year, month] = launchedOn.split("-").map(Number);

  return {
    month: new Intl.DateTimeFormat(locale, { month: "long" }).format(
      new Date(year, month - 1, 1),
    ),
    year: year + IN_UNIVERSE_YEAR_OFFSET,
  };
};
