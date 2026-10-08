import { test, expect } from "../support/commands";
import { app, appScenario } from "../support/on-rails";
import { expectNoA11yViolations } from "../support/a11y";

test.describe("Accessibility", () => {
  test.describe("public pages", () => {
    test.beforeEach(async () => {
      await app("clean");
      await appScenario("ships");
    });

    test("home", async ({ page }) => {
      await page.goto("/");
      await expect(
        page.getByTestId("home-ships").locator(".panel"),
      ).toHaveCount(2);

      await expectNoA11yViolations(page);
    });

    test("ships", async ({ page }) => {
      await page.goto("/ships/");
      await expect(page.getByTestId("model-panel-aegs-ironclad")).toBeVisible();

      await expectNoA11yViolations(page);
    });

    test("ship", async ({ page }) => {
      await page.goto("/ships/aegs-ironclad/");
      await expect(page.getByTestId("model-headline")).toContainText(
        "Ironclad",
      );

      await expectNoA11yViolations(page);
    });

    test("login", async ({ page }) => {
      await page.goto("/login/");
      await expect(page.locator("input[name='login']")).toBeVisible();

      await expectNoA11yViolations(page);
    });

    test("sign up", async ({ page }) => {
      await page.goto("/sign-up/");
      await expect(page.getByTestId("submit-signup")).toBeVisible();

      await expectNoA11yViolations(page);
    });
  });

  test.describe("components", () => {
    for (const demo of ["buttons", "forms", "panels", "typography", "alerts"]) {
      test(demo, async ({ page }) => {
        await page.goto(`/visual-tests/${demo}/`);
        await expect(page.locator(".visual-tests")).toBeVisible();

        await expectNoA11yViolations(page);
      });
    }

    test("confirm dialog", async ({ page }) => {
      await page.goto("/visual-tests/overlays/");
      await page.getByTestId("confirm-destructive").click();
      await expect(page.getByTestId("confirm-ok")).toBeVisible();

      await expectNoA11yViolations(page, { include: ".app-confirm" });
    });
  });
});
