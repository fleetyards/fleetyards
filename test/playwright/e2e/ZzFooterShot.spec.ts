import { test } from "../support/commands";
import fs from "node:fs";

const OUT = process.env.SHOT_OUT as string;

test("shot", async ({ page }) => {
  await page.setViewportSize({ width: 1440, height: 900 });
  await page.goto("/");
  const footer = page.getByTestId("app-footer");
  await footer.scrollIntoViewIfNeeded();
  await page.waitForTimeout(1500);

  fs.writeFileSync(
    `${OUT}.html`,
    await footer.evaluate((el) => el.outerHTML),
  );

  const data = await footer.evaluate((el) => {
    const keys = [
      "display",
      "gridTemplateColumns",
      "gridTemplateAreas",
      "gap",
      "padding",
      "backgroundColor",
      "color",
      "borderTop",
      "fontSize",
      "textAlign",
      "position",
      "transition",
    ] as const;
    const pick = (n: Element) => {
      const cs = getComputedStyle(n);
      return Object.fromEntries(keys.map((k) => [k, cs[k]]));
    };
    const before = getComputedStyle(el, "::before");
    return {
      footer: pick(el),
      footerBefore: {
        content: before.content,
        height: before.height,
        left: before.left,
        right: before.right,
        top: before.top,
        backgroundColor: before.backgroundColor,
        borderRadius: before.borderRadius,
      },
      children: [...el.querySelectorAll(":scope > *, :scope > * > *")].map(
        (n) => ({ tag: n.tagName, cls: n.className, ...pick(n) }),
      ),
      links: [...el.querySelectorAll("a")].map((a) => ({
        text: a.textContent?.trim(),
        href: a.getAttribute("href"),
        icon: a.querySelector("i")?.className || null,
        aria: a.getAttribute("aria-label"),
      })),
      text: (el as HTMLElement).innerText,
      box: el.getBoundingClientRect().toJSON(),
    };
  });
  fs.writeFileSync(`${OUT}.json`, JSON.stringify(data, null, 2));

  await footer.screenshot({ path: `${OUT}-desktop.png` });

  await page.setViewportSize({ width: 390, height: 844 });
  await page.waitForTimeout(1000);
  await footer.scrollIntoViewIfNeeded();
  await page.waitForTimeout(500);
  await footer.screenshot({ path: `${OUT}-mobile.png` });
});
