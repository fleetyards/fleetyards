import { describe, it, expect, beforeEach } from "vitest";
import { setActivePinia, createPinia } from "pinia";
import type { User } from "@/services/fyApi";
import { useSessionStore } from "@/frontend/stores/session";
import { useNotificationsStore } from "@/shared/stores/notifications";
import { useSupportPrompt } from "./useSupportPrompt";

const signInAs = (attrs: Partial<User>) => {
  const sessionStore = useSessionStore();
  sessionStore.authenticated = true;
  sessionStore.currentUser = { supporter: false, ...attrs } as User;
};

describe("useSupportPrompt", () => {
  beforeEach(() => {
    setActivePinia(createPinia());
    localStorage.clear();
  });

  it("prompts a signed-in user who does not support yet", () => {
    signInAs({ supporter: false });

    expect(useSupportPrompt().notify("vehicleAdded")).toBe(true);
    expect(useNotificationsStore().messages).toHaveLength(1);
  });

  it("never prompts a supporter", () => {
    signInAs({ supporter: true });
    const supportPrompt = useSupportPrompt();

    expect(supportPrompt.canShow()).toBe(false);
    expect(supportPrompt.notify("vehicleAdded")).toBe(false);
    expect(useNotificationsStore().messages).toHaveLength(0);
  });

  it("prompts a signed-out visitor", () => {
    expect(useSupportPrompt().canShow()).toBe(true);
  });
});
