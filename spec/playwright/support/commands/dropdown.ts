import { expect, type Page } from "@playwright/test";

export default class Dropdown {
  page: Page;

  constructor(page: Page) {
    this.page = page;
  }

  async click(dropdownName: string, navItem: string) {
    const dropdown = this.page.getByTestId(`${dropdownName}-dropdown`);

    await expect(dropdown).toBeVisible();

    await dropdown.click();

    const item = this.page.locator(
      `[data-test='${dropdownName}-dropdown'] [data-test='${navItem}']`,
    );

    await expect(item).toBeVisible();

    await item.click();
  }
}
