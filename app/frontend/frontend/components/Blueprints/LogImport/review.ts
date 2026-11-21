import type {
  BlueprintLogMatch,
  BlueprintLogMatchOption,
} from "@/services/fyApi";

export interface BlueprintLogReview {
  // One blueprint, not yet owned: imported unless the user unticks it.
  fresh: BlueprintLogMatchOption[];
  // A name two recipes share: nothing is imported until the user picks.
  ambiguous: BlueprintLogMatch[];
  // Nothing to do; listed so the count adds up to what the logs held.
  owned: BlueprintLogMatchOption[];
  // Names the catalogue does not know.
  unmatched: string[];
}

export const reviewMatches = (
  matches: BlueprintLogMatch[],
): BlueprintLogReview => {
  const review: BlueprintLogReview = {
    fresh: [],
    ambiguous: [],
    owned: [],
    unmatched: [],
  };

  matches.forEach((match) => {
    const owned = match.blueprints.filter((option) => option.owned);

    if (!match.blueprints.length) {
      review.unmatched.push(match.name);
    } else if (owned.length) {
      // Already holding one of the recipes the name can mean is the answer:
      // the log line is that one being received.
      review.owned.push(...owned);
    } else if (match.blueprints.length > 1) {
      review.ambiguous.push(match);
    } else {
      review.fresh.push(match.blueprints[0]);
    }
  });

  return review;
};
