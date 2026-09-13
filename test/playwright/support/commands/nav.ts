import { expect, type Page } from "@playwright/test";

export default class Nav {
  page: Page;

  constructor(page: Page) {
    this.page = page;
  }

  async click(name: string, subName?: string) {
    const navItem = this.page.getByTestId(`nav-${name}`);
    await navItem.click();

    if (subName) {
      const subNavItem = this.page.getByTestId(`nav-${subName}`);
      if (subNavItem) {
        await subNavItem.click();
      }
    }
  }

  /*
   * The navigation defaults to slim, where a row renders its icon and nothing
   * else -- a label only reaches the DOM once the nav is expanded. Anything
   * asserting on nav text has to expand it first.
   */
  async expand() {
    const navigation = this.page.getByTestId("app-navigation");

    if (
      await navigation.evaluate((el) =>
        el.classList.contains("app-navigation--slim"),
      )
    ) {
      await this.click("toggle-slim");
    }

    await expect(navigation).not.toHaveClass(/app-navigation--slim/);
  }
}
