import { test as base } from "@playwright/test";

import Nav from "./commands/nav";
import Notification from "./commands/notification";
import Dropdown from "./commands/dropdown";

export const test = base.extend<{
  nav: Nav;
  notification: Notification;
  dropdown: Dropdown;
}>({
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
