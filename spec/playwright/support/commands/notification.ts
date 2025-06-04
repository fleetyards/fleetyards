import { expect, type Page } from "@playwright/test";

export default class Notification {
  page: Page;

  constructor(page: Page) {
    this.page = page;
  }

  async alert(message: string) {
    const alertModal = this.page
      .locator(".app-notifications__message--alert div")
      .getByText(message);

    await expect(alertModal).toBeVisible();

    await alertModal.click();
  }

  async success(message: string) {
    const successModal = this.page
      .locator(".app-notifications__message--success div")
      .getByText(message);

    await expect(successModal).toBeVisible();

    await successModal.click();
  }
}
