// `money` used to hide the pledge and the in-game total together. A visitor
// who hid them before `credits` existed keeps the in-game total hidden too.
export const creditsFromLegacyMoney = (
  storageKey: string,
  credits: boolean,
): boolean => {
  try {
    const stored = JSON.parse(localStorage.getItem(storageKey) ?? "null");
    if (stored && !("credits" in stored) && stored.money === false) {
      return false;
    }
  } catch {
    return credits;
  }
  return credits;
};
