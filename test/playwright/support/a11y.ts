import AxeBuilder from "@axe-core/playwright";
import { expect, test, type Page } from "@playwright/test";

type Impact = "minor" | "moderate" | "serious" | "critical";

type A11yOptions = {
  include?: string;
  exclude?: string[];
  disableRules?: string[];
  impacts?: Impact[];
};

const WCAG_TAGS = ["wcag2a", "wcag2aa", "wcag21a", "wcag21aa", "wcag22aa"];

/*
 * Only serious and critical findings fail by default: moderate ones are mostly
 * best-practice rules (region, heading order) that would drown the real
 * blockers while the existing pages are brought up to standard.
 */
export const expectNoA11yViolations = async (
  page: Page,
  {
    include,
    exclude = [],
    disableRules = [],
    impacts = ["serious", "critical"],
  }: A11yOptions = {},
) => {
  // The route enter transition fades the page in, and axe measures contrast
  // against whatever opacity is current.
  // Looping animations (spinners) never finish, and a cancelled one rejects.
  await page.evaluate(() =>
    Promise.allSettled(
      document
        .getAnimations()
        .filter(
          (animation) =>
            animation.effect?.getComputedTiming().iterations !== Infinity,
        )
        .map((animation) => animation.finished),
    ),
  );

  let builder = new AxeBuilder({ page }).withTags(WCAG_TAGS);

  if (include) builder = builder.include(include);
  for (const selector of exclude) builder = builder.exclude(selector);
  if (disableRules.length) builder = builder.disableRules(disableRules);

  const results = await builder.analyze();

  await test.info().attach("axe-results", {
    body: JSON.stringify(results.violations, null, 2),
    contentType: "application/json",
  });

  const violations = results.violations.filter((violation) =>
    impacts.includes(violation.impact as Impact),
  );

  const summary = violations.map((violation) => ({
    rule: violation.id,
    impact: violation.impact,
    help: violation.help,
    targets: violation.nodes.map((node) => node.target.join(" ")),
  }));

  expect(summary).toEqual([]);
};
