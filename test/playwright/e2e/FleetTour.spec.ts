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

  const createFleet = async (page: Page) => {
    await page.goto("/fleets/add/");

    await page.getByTestId("input-fid").fill("TourFleet");
    await page.getByTestId("input-name").fill("Tour Fleet");
    await page.getByTestId("fleet-save").click();

    await expect(page).toHaveURL(/\/fleets\/tourfleet\/$/);
  };

  test("starts once after creating a fleet and replays from the header", async ({
    page,
  }) => {
    await createFleet(page);

    await expect(card(page)).toBeVisible();
    await expect(card(page)).toHaveAttribute("data-step", "welcome");

    await page.getByTestId("tour-next").click();
    await expect(page).toHaveURL(/\/fleets\/tourfleet\/members\/$/);
    await expect(card(page)).toHaveAttribute("data-step", "members");

    await page.getByTestId("tour-skip").click();
    await expect(card(page)).toHaveCount(0);

    // Done once shown: the overview must not start it again. The guide button
    // is rendered with the page, so the wait after it outlasts the delay.
    await page.goto("/fleets/tourfleet/");
    await expect(page.getByTestId("fleet-show-guide")).toBeVisible();
    await page.waitForTimeout(1500);
    await expect(card(page)).toHaveCount(0);

    await page.getByTestId("fleet-show-guide").click();

    await expect(card(page)).toBeVisible();
    await expect(card(page)).toHaveAttribute("data-step", "welcome");
  });

  test("walks the fleet's pages through to the end", async ({ page }) => {
    await createFleet(page);
    await expect(card(page)).toBeVisible();

    const seen: { step: string | null; path: string }[] = [];

    for (let i = 0; i < 14; i += 1) {
      await expect(card(page)).not.toHaveCSS("visibility", "hidden");

      seen.push({
        step: await card(page).getAttribute("data-step"),
        path: new URL(page.url()).pathname,
      });

      const next = page.getByTestId("tour-next");
      const done = (await next.textContent())?.trim() === "Done";
      await next.click();

      if (done) break;
    }

    await expect(card(page)).toHaveCount(0);

    // Events and contracts are flag-gated and off here.
    expect(seen).toEqual([
      { step: "welcome", path: "/fleets/tourfleet/" },
      { step: "members", path: "/fleets/tourfleet/members/" },
      { step: "ships", path: "/fleets/tourfleet/ships/" },
      { step: "membership", path: "/fleets/tourfleet/settings/membership/" },
      { step: "rsi", path: "/fleets/tourfleet/settings/rsi/" },
      { step: "roles", path: "/fleets/tourfleet/settings/roles/" },
      { step: "squadrons", path: "/fleets/tourfleet/settings/squadrons/" },
      { step: "discord", path: "/fleets/tourfleet/settings/discord/" },
      { step: "settings", path: "/fleets/tourfleet/settings/fleet/" },
    ]);
  });

  test("goes back to the previous step's page", async ({ page }) => {
    await createFleet(page);
    await expect(card(page)).toBeVisible();

    await page.getByTestId("tour-next").click();
    await expect(card(page)).toHaveAttribute("data-step", "members");
    await page.getByTestId("tour-next").click();
    await expect(page).toHaveURL(/\/ships\/$/);
    await expect(card(page)).toHaveAttribute("data-step", "ships");

    await page.getByTestId("tour-back").click();

    await expect(page).toHaveURL(/\/members\/$/);
    await expect(card(page)).toHaveAttribute("data-step", "members");
  });
});
