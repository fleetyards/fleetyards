import { test, expect, type Page, type BrowserContext } from "@playwright/test";
import { execSync } from "child_process";
import * as fs from "fs";
import * as path from "path";

/*
 * Visual comparison between current (subdomain-based) and bootstrap-removal (path-based) environments.
 *
 * Before (subdomains):
 *   fleetyards.test          → frontend
 *   docs.fleetyards.test     → docs
 *   admin.fleetyards.test    → admin
 *
 * After (localhost path-based):
 *   localhost:8540            → frontend
 *   localhost:8540/docs       → docs
 *   localhost:8540/admin      → admin
 *
 * Run: pnpm exec playwright test spec/playwright/visual-compare.spec.ts --reporter=html
 * Screenshots saved to: tmp/visual-compare/{before,after}/{frontend,docs,admin}/
 */

const SCREENSHOT_DIR = path.join(__dirname, "../../tmp/visual-compare");

// ── Credentials (from 1Password) ─────────────────────────────────────
function opRead(ref: string): string {
  return execSync(`op read "${ref}"`, { encoding: "utf-8" }).trim();
}

const FRONTEND_USER = {
  login: opRead("op://Private/FleetYards Test Admin/username"),
  password: opRead("op://Private/FleetYards Test Admin/password"),
};

const ADMIN_USER = {
  login: opRead("op://Private/FleetYards Test Frontend/username"),
  password: opRead("op://Private/FleetYards Test Frontend/password"),
};

// ── Public frontend pages (no auth required) ──────────────────────────
const FRONTEND_PUBLIC_PAGES = [
  "/",
  "/ships/",
  "/stats/",
  "/images/",
  "/fleets/",
  "/compare/",
  "/tools/",
  "/tools/travel-times/",
  "/tools/cargo-grids/",
  "/impressum/",
  "/privacy-policy/",
  "/login/",
  "/sign-up/",
  "/password/request/",
  "/404/",
];

// ── Authenticated frontend pages ─────────────────────────────────────
const FRONTEND_AUTH_PAGES = [
  "/hangar/",
  "/hangar/wishlist/",
  "/hangar/stats/",
  "/hangar/fleetchart/",
  "/settings/profile/",
  "/settings/account/",
  "/settings/notifications/",
  "/settings/hangar/",
  "/settings/features/",
  "/settings/security/",
  "/settings/oauth-applications/",
];

// ── Docs pages ────────────────────────────────────────────────────────
const DOCS_PAGES = [
  "/api/v1/",
  "/api/v1/pagination/",
  "/api/auth/v1/",
  "/api/auth/v1/openid/",
  "/embed/",
];

// ── Admin pages ───────────────────────────────────────────────────────
const ADMIN_PUBLIC_PAGES = ["/login/"];

const ADMIN_AUTH_PAGES = [
  "/",
  "/models/",
  "/components/",
  "/manufacturers/",
  "/vehicles/",
  "/fleets/",
  "/users/",
  "/admins/",
  "/oauth-applications/",
  "/maintenance/features/",
  "/maintenance/workers/",
  "/maintenance/tasks/",
];

// ── Helpers ───────────────────────────────────────────────────────────

function slugify(pagePath: string): string {
  return (
    pagePath
      .replace(/^\//, "")
      .replace(/\/$/, "")
      .replace(/\//g, "-") || "home"
  );
}

function ensureDir(dir: string) {
  if (!fs.existsSync(dir)) {
    fs.mkdirSync(dir, { recursive: true });
  }
}

async function screenshot(
  page: Page,
  url: string,
  filePath: string,
): Promise<boolean> {
  try {
    await page.goto(url, { waitUntil: "networkidle", timeout: 30000 });
    await page.waitForTimeout(2000);
    await page.screenshot({ path: filePath, fullPage: true });
    return true;
  } catch (e: any) {
    console.warn(`  ⚠ Failed: ${url} — ${e.message}`);
    return false;
  }
}

async function dismissCookieBanner(page: Page) {
  try {
    const acceptBtn = page.locator("[data-test='cookie-accept'], .cookie-accept, button:has-text('Accept')");
    if (await acceptBtn.isVisible({ timeout: 3000 })) {
      await acceptBtn.click();
      await page.waitForTimeout(500);
    }
  } catch {
    // no cookie banner, that's fine
  }
}

async function loginFrontend(page: Page, baseUrl: string) {
  await page.goto(`${baseUrl}/login/`, { waitUntil: "networkidle", timeout: 30000 });
  await dismissCookieBanner(page);
  await page.locator("input[name='login']").fill(FRONTEND_USER.login);
  await page.locator("input[name='password']").fill(FRONTEND_USER.password);
  await page.getByTestId("submit-login").click();
  await page.waitForLoadState("networkidle");
  await page.waitForTimeout(2000);
}

async function loginAdmin(page: Page, baseUrl: string) {
  await page.goto(`${baseUrl}/login/`, { waitUntil: "networkidle", timeout: 30000 });
  await page.locator("input[name='login']").fill(ADMIN_USER.login);
  await page.locator("input[name='password']").fill(ADMIN_USER.password);
  await page.getByTestId("submit-login").click();
  await page.waitForLoadState("networkidle");
  await page.waitForTimeout(2000);
}

// ── Frontend Public ───────────────────────────────────────────────────

test.describe("Frontend Public", () => {
  for (const pagePath of FRONTEND_PUBLIC_PAGES) {
    const name = slugify(pagePath);

    test(`before — ${name}`, async ({ browser }) => {
      const dir = path.join(SCREENSHOT_DIR, "before", "frontend");
      ensureDir(dir);
      const ctx = await browser.newContext({ viewport: { width: 1440, height: 900 } });
      const page = await ctx.newPage();
      await screenshot(page, `http://fleetyards.test${pagePath}`, path.join(dir, `${name}.png`));
      await ctx.close();
    });

    test(`after — ${name}`, async ({ browser }) => {
      const dir = path.join(SCREENSHOT_DIR, "after", "frontend");
      ensureDir(dir);
      const ctx = await browser.newContext({ viewport: { width: 1440, height: 900 } });
      const page = await ctx.newPage();
      await screenshot(page, `http://localhost:8540${pagePath}`, path.join(dir, `${name}.png`));
      await ctx.close();
    });
  }
});

// ── Frontend Authenticated ────────────────────────────────────────────

test.describe("Frontend Auth", () => {
  test.describe("before", () => {
    let ctx: BrowserContext;
    let page: Page;

    test.beforeAll(async ({ browser }) => {
      ctx = await browser.newContext({ viewport: { width: 1440, height: 900 } });
      page = await ctx.newPage();
      await loginFrontend(page, "http://fleetyards.test");
    });

    test.afterAll(async () => {
      await ctx.close();
    });

    for (const pagePath of FRONTEND_AUTH_PAGES) {
      const name = slugify(pagePath);
      test(name, async () => {
        const dir = path.join(SCREENSHOT_DIR, "before", "frontend-auth");
        ensureDir(dir);
        await screenshot(page, `http://fleetyards.test${pagePath}`, path.join(dir, `${name}.png`));
      });
    }
  });

  test.describe("after", () => {
    let ctx: BrowserContext;
    let page: Page;

    test.beforeAll(async ({ browser }) => {
      ctx = await browser.newContext({ viewport: { width: 1440, height: 900 } });
      page = await ctx.newPage();
      await loginFrontend(page, "http://localhost:8540");
    });

    test.afterAll(async () => {
      await ctx.close();
    });

    for (const pagePath of FRONTEND_AUTH_PAGES) {
      const name = slugify(pagePath);
      test(name, async () => {
        const dir = path.join(SCREENSHOT_DIR, "after", "frontend-auth");
        ensureDir(dir);
        await screenshot(page, `http://localhost:8540${pagePath}`, path.join(dir, `${name}.png`));
      });
    }
  });
});

// ── Docs ──────────────────────────────────────────────────────────────

test.describe("Docs", () => {
  for (const pagePath of DOCS_PAGES) {
    const name = slugify(pagePath);

    test(`before — ${name}`, async ({ browser }) => {
      const dir = path.join(SCREENSHOT_DIR, "before", "docs");
      ensureDir(dir);
      const ctx = await browser.newContext({ viewport: { width: 1440, height: 900 } });
      const page = await ctx.newPage();
      await screenshot(page, `http://docs.fleetyards.test${pagePath}`, path.join(dir, `${name}.png`));
      await ctx.close();
    });

    test(`after — ${name}`, async ({ browser }) => {
      const dir = path.join(SCREENSHOT_DIR, "after", "docs");
      ensureDir(dir);
      const ctx = await browser.newContext({ viewport: { width: 1440, height: 900 } });
      const page = await ctx.newPage();
      await screenshot(page, `http://localhost:8540/docs${pagePath}`, path.join(dir, `${name}.png`));
      await ctx.close();
    });
  }
});

// ── Admin Public ──────────────────────────────────────────────────────

test.describe("Admin Public", () => {
  for (const pagePath of ADMIN_PUBLIC_PAGES) {
    const name = slugify(pagePath);

    test(`before — ${name}`, async ({ browser }) => {
      const dir = path.join(SCREENSHOT_DIR, "before", "admin");
      ensureDir(dir);
      const ctx = await browser.newContext({ viewport: { width: 1440, height: 900 } });
      const page = await ctx.newPage();
      await screenshot(page, `http://admin.fleetyards.test${pagePath}`, path.join(dir, `${name}.png`));
      await ctx.close();
    });

    test(`after — ${name}`, async ({ browser }) => {
      const dir = path.join(SCREENSHOT_DIR, "after", "admin");
      ensureDir(dir);
      const ctx = await browser.newContext({ viewport: { width: 1440, height: 900 } });
      const page = await ctx.newPage();
      await screenshot(page, `http://localhost:8540/admin${pagePath}`, path.join(dir, `${name}.png`));
      await ctx.close();
    });
  }
});

// ── Admin Authenticated ───────────────────────────────────────────────

test.describe("Admin Auth", () => {
  test.describe("before", () => {
    let ctx: BrowserContext;
    let page: Page;

    test.beforeAll(async ({ browser }) => {
      ctx = await browser.newContext({ viewport: { width: 1440, height: 900 } });
      page = await ctx.newPage();
      await loginAdmin(page, "http://admin.fleetyards.test");
    });

    test.afterAll(async () => {
      await ctx.close();
    });

    for (const pagePath of ADMIN_AUTH_PAGES) {
      const name = slugify(pagePath);
      test(name, async () => {
        const dir = path.join(SCREENSHOT_DIR, "before", "admin-auth");
        ensureDir(dir);
        await screenshot(page, `http://admin.fleetyards.test${pagePath}`, path.join(dir, `${name}.png`));
      });
    }
  });

  test.describe("after", () => {
    let ctx: BrowserContext;
    let page: Page;

    test.beforeAll(async ({ browser }) => {
      ctx = await browser.newContext({ viewport: { width: 1440, height: 900 } });
      page = await ctx.newPage();
      await loginAdmin(page, "http://localhost:8540/admin");
    });

    test.afterAll(async () => {
      await ctx.close();
    });

    for (const pagePath of ADMIN_AUTH_PAGES) {
      const name = slugify(pagePath);
      test(name, async () => {
        const dir = path.join(SCREENSHOT_DIR, "after", "admin-auth");
        ensureDir(dir);
        await screenshot(page, `http://localhost:8540/admin${pagePath}`, path.join(dir, `${name}.png`));
      });
    }
  });
});
