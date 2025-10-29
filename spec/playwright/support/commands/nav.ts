import { expect, type Page } from "@playwright/test";

export default class Nav {
  page: Page;

  constructor(page: Page) {
    this.page = page;
  }

  async click(name: string, subName?: string) {
    const navItem = this.page.getByTestId(`nav-${name}`);
    if (navItem) {
      navItem.click();
    }

    if (subName) {
      const subNavItem = this.page.getByTestId(`nav-${subName}`);
      if (subNavItem) {
        await subNavItem.click();
      }
    }
  }
}
