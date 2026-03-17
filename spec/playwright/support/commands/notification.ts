import { expect, type Page } from "@playwright/test";

export default class Notification {
  page: Page;

  constructor(page: Page) {
    this.page = page;
  }

  async alert(message: string) {
    const alertModal = this.page
      .getByTestId("notification-alert")
      .locator("div")
      .getByText(message);

    await expect(alertModal).toBeVisible();

    await alertModal.click();
  }

  async success(message: string) {
    const successModal = this.page
      .getByTestId("notification-success")
      .locator("div")
      .getByText(message);

    await expect(successModal).toBeVisible();

    await successModal.click();
  }
}
