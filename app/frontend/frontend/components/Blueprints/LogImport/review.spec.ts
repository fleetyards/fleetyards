import { describe, expect, it } from "vitest";
import { reviewMatches } from "./review";

const option = (
  slug: string,
  attrs: { owned?: boolean; wanted?: boolean } = {},
) => ({
  slug,
  name: slug,
  owned: false,
  wanted: false,
  ...attrs,
});

describe("reviewMatches", () => {
  it("sorts each name into new, ambiguous, owned or unmatched", () => {
    const review = reviewMatches([
      { name: "Aspis", blueprints: [option("aspis")] },
      { name: "Wanted", blueprints: [option("wanted", { wanted: true })] },
      { name: "Helmet", blueprints: [option("helmet-a"), option("helmet-b")] },
      { name: "Held", blueprints: [option("held", { owned: true })] },
      {
        name: "Held colourway",
        blueprints: [option("core-a"), option("core-b", { owned: true })],
      },
      { name: "Nothing", blueprints: [] },
    ]);

    expect(review.fresh.map(({ slug }) => slug)).toEqual(["aspis", "wanted"]);
    expect(review.ambiguous.map(({ name }) => name)).toEqual(["Helmet"]);
    expect(review.owned.map(({ slug }) => slug)).toEqual(["held", "core-b"]);
    expect(review.unmatched).toEqual(["Nothing"]);
  });
});
