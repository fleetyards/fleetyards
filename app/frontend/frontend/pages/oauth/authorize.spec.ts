import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import { flushPromises } from "@vue/test-utils";
import { mountWithDefaults } from "@/shared/utils/TestUtils";

const oauthPreAuthorize = vi.fn();

vi.mock("@/services/fyOAuthApi/services/oauth/oauth", () => ({
  oauthPreAuthorize: (...args: unknown[]) => oauthPreAuthorize(...args),
  oauthAuthorize: vi.fn(),
  oauthDeny: vi.fn(),
}));

import AuthorizePage from "./authorize.vue";

const originalLocation = window.location;

describe("OauthAuthorize", () => {
  beforeEach(() => {
    Object.defineProperty(window, "location", {
      configurable: true,
      value: { ...originalLocation, href: "http://localhost/oauth/authorize" },
    });
  });

  afterEach(() => {
    Object.defineProperty(window, "location", {
      configurable: true,
      value: originalLocation,
    });
    oauthPreAuthorize.mockReset();
  });

  it("lists the scopes the client asks for", async () => {
    oauthPreAuthorize.mockResolvedValue({
      clientId: "client",
      clientName: "Some App",
      redirectUri: "https://app.example/callback",
      responseType: "code",
      scope: "public",
      scopes: [{ name: "public", description: "Read public data" }],
    });

    const wrapper = await mountWithDefaults(AuthorizePage);
    await flushPromises();

    expect(wrapper.find(".authorize-scopes").text()).toContain(
      "Read public data",
    );
  });

  it("sends a returning user straight back to the client", async () => {
    oauthPreAuthorize.mockResolvedValue({
      status: "redirect",
      redirect_uri: "https://app.example/callback?code=abc",
    });

    const wrapper = await mountWithDefaults(AuthorizePage);
    await flushPromises();

    expect(window.location.href).toBe("https://app.example/callback?code=abc");
    expect(wrapper.find(".authorize-scopes").exists()).toBe(false);
    expect(wrapper.find(".text-danger").exists()).toBe(false);
  });
});
