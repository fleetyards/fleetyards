import { test, expect } from "../support/commands";
import { app, appFactories } from "../support/on-rails";

type Page = import("@playwright/test").Page;

const card = (page: Page) => page.getByTestId("tour-card");

test.describe("Fleet tour", () => {
  test.beforeEach(async ({ page }) => {
    await app("clean");
    await appFactories([
      ["create", "user", { username: "tour", password: "password" }],
    ]);

    await page.goto("/login/");
    await page.locator("input[name='login']").fill("tour");
    await page.locator("input[name='password']").fill("password");

    const sessionCreated = page.waitForResponse(
      (response) =>
        response.url().includes("/api/v1/sessions") &&
        response.request().method() === "POST",
    );
    await page.getByTestId("submit-login").click();
    await sessionCreated;
    await expect(page).not.toHaveURL(/\/login/);
  });

  test("starts once after creating a fleet and replays from the header", async ({
    page,
  }) => {
    await page.goto("/fleets/add/");

    await page.getByTestId("input-fid").fill("TourFleet");
    await page.getByTestId("input-name").fill("Tour Fleet");
    await page.getByTestId("fleet-save").click();

    await expect(page).toHaveURL(/\/fleets\/tourfleet\//);

    await expect(card(page)).toBeVisible();
    await expect(card(page)).toHaveAttribute("data-step", "welcome");

    await page.getByTestId("tour-next").click();
    await expect(card(page)).toHaveAttribute("data-step", "members");

    await page.getByTestId("tour-skip").click();
    await expect(card(page)).toHaveCount(0);

    // Done once shown: a reload must not start it again. The guide button is
    // rendered with the page, so the wait after it outlasts the start delay.
    await page.reload();
    await expect(page.getByTestId("fleet-show-guide")).toBeVisible();
    await page.waitForTimeout(1500);
    await expect(card(page)).toHaveCount(0);

    await page.getByTestId("fleet-show-guide").click();

    await expect(card(page)).toBeVisible();
    await expect(card(page)).toHaveAttribute("data-step", "welcome");
  });

  test("walks every step through to the end", async ({ page }) => {
    await page.goto("/fleets/add/");

    await page.getByTestId("input-fid").fill("TourFleet");
    await page.getByTestId("input-name").fill("Tour Fleet");
    await page.getByTestId("fleet-save").click();

    await expect(card(page)).toBeVisible();

    const seen: (string | null)[] = [];

    for (let i = 0; i < 12; i += 1) {
      seen.push(await card(page).getAttribute("data-step"));

      const next = page.getByTestId("tour-next");
      const done = (await next.textContent())?.trim() === "Done";
      await next.click();

      if (done) break;
    }

    await expect(card(page)).toHaveCount(0);

    expect(seen).toEqual(
      expect.arrayContaining([
        "welcome",
        "members",
        "roles",
        "ships",
        "rsi",
        "discord",
        "settings",
      ]),
    );
  });

  // The slide-out menu stays laid out off-screen while closed, so a tab step
  // that found it there would spotlight nothing the reader can see.
  test("spotlights the bottom bar on a phone", async ({ page }) => {
    await page.setViewportSize({ width: 390, height: 844 });
    await page.goto("/fleets/add/");

    await page.getByTestId("input-fid").fill("TourFleet");
    await page.getByTestId("input-name").fill("Tour Fleet");
    await page.getByTestId("fleet-save").click();

    await expect(card(page)).toBeVisible();
    await page.getByTestId("tour-next").click();
    await expect(card(page)).toHaveAttribute("data-step", "members");

    // The spotlight slides from the previous step, so wait for it to land.
    await expect
      .poll(async () => {
        const hole = await page.locator(".tour__hole").boundingBox();

        return (
          !!hole &&
          hole.x >= 0 &&
          hole.x + hole.width <= 390 &&
          hole.y > 844 / 2
        );
      })
      .toBe(true);
  });
});
