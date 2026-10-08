import { test, expect } from "../support/commands";
import { app, appFactories } from "../support/on-rails";

type Page = import("@playwright/test").Page;

const card = (page: Page) => page.getByTestId("tour-card");

test.describe("Hangar tour", () => {
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

  test("starts once on an empty hangar and replays from the menu", async ({
    page,
  }) => {
    await page.goto("/hangar/");

    await expect(card(page)).toBeVisible();
    await expect(card(page)).toHaveAttribute("data-step", "welcome");

    await page.getByTestId("tour-next").click();
    await expect(card(page)).toHaveAttribute("data-step", "add");

    await page.keyboard.press("ArrowRight");
    await expect(card(page)).toHaveAttribute("data-step", "sync");

    await page.keyboard.press("Escape");
    await expect(card(page)).toHaveCount(0);

    // Seen once shown: a reload must not start it again. The groups row is
    // what the auto-start waits for, so the wait after it outlasts its delay.
    await page.reload();
    await expect(page.locator("[data-tour='hangar-groups']")).toBeVisible();
    await page.waitForTimeout(1500);
    await expect(card(page)).toHaveCount(0);

    await page.locator("[data-tour='hangar-menu'] button").first().click();
    await page
      .getByTestId("dropdown-list")
      .getByTestId("hangar-show-guide")
      .click();

    await expect(card(page)).toBeVisible();
    await expect(card(page)).toHaveAttribute("data-step", "welcome");
  });

  test("walks every step through to the end", async ({ page }) => {
    await page.goto("/hangar/");
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

    // No vehicles yet, so the step about a ship's own menu has nothing to
    // point at.
    expect(seen).not.toContain("vehicle");
    expect(seen).toEqual(
      expect.arrayContaining(["welcome", "add", "sync", "display", "menu"]),
    );
  });
});
