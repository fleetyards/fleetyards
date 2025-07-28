import { test as base } from "@playwright/test";

import AcceptCookie from "./commands/acceptCookie";
import Nav from "./commands/nav";
import Notification from "./commands/notification";
import Dropdown from "./commands/dropdown";

export const test = base.extend<{
  acceptCookie: AcceptCookie;
  nav: Nav;
  notification: Notification;
  dropdown: Dropdown;
}>({
  acceptCookie: async ({ page }, use) => {
    const acceptCookie = new AcceptCookie(page);
    await use(acceptCookie);
  },
  nav: async ({ page }, use) => {
    const nav = new Nav(page);
    await use(nav);
  },
  notification: async ({ page }, use) => {
    const notification = new Notification(page);
    await use(notification);
  },
  dropdown: async ({ page }, use) => {
    const dropdown = new Dropdown(page);
    await use(dropdown);
  },
});

export { expect } from "@playwright/test";
