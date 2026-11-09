import { createPinia, setActivePinia } from "pinia";
import { beforeEach, describe, expect, it, vi } from "vitest";
import { useRedirectBackStore } from "@/shared/stores/redirectBack";

const push = vi.fn();

vi.mock("vue-router", async (importOriginal) => ({
  ...(await importOriginal<Record<string, unknown>>()),
  useRoute: () => ({ fullPath: "/tools/dressing-room/?torso=adp-core" }),
  useRouter: () => ({ push }),
}));

const { useSignInAndReturn } = await import("./useSignInAndReturn");

beforeEach(() => {
  setActivePinia(createPinia());
  push.mockClear();
});

describe("useSignInAndReturn", () => {
  it("opens the login and comes back to the page as it is", async () => {
    await useSignInAndReturn()();

    expect(useRedirectBackStore().backRoute).toBe(
      "/tools/dressing-room/?torso=adp-core",
    );
    expect(push).toHaveBeenCalledWith({ name: "login" });
  });
});
