import { expect, type Page } from "@playwright/test";

export default class AcceptCookie {
  page: Page;

  constructor(page: Page) {
    this.page = page;
  }

  async accept() {
    const cookieModal = this.page.getByTestId("accept-cookies");
    await expect(cookieModal).toBeVisible();
    await cookieModal.click({ force: true });
    await expect(cookieModal).not.toBeVisible();
  }
}
