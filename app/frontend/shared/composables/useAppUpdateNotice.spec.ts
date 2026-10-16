import { describe, it, expect, beforeEach } from "vitest";
import { nextTick, reactive } from "vue";
import { setActivePinia, createPinia } from "pinia";
import { useNotificationsStore } from "@/shared/stores/notifications";
import {
  releaseUrl,
  useAppUpdateNotice,
  whatsNewUrl,
} from "./useAppUpdateNotice";

const announcement = {
  title: "Fleet events",
  link: "/fleets/",
  publishedAt: "2026-10-16T12:00:00Z",
};

const visibleNotices = () =>
  useNotificationsStore().messages.filter((message) => message.visible);

describe("releaseUrl", () => {
  it("links the release tag, with or without the v prefix", () => {
    const expected =
      "https://github.com/fleetyards/fleetyards/releases/tag/v9.9.0";

    expect(releaseUrl("v9.9.0")).toBe(expected);
    expect(releaseUrl("9.9.0")).toBe(expected);
  });
});

describe("whatsNewUrl", () => {
  const before = Date.parse("2026-10-16T11:00:00Z");
  const after = Date.parse("2026-10-16T13:00:00Z");

  it("points at an announcement published after the tab loaded", () => {
    expect(whatsNewUrl("v9.9.0", announcement, before)).toBe(
      `${window.FRONTEND_ENDPOINT}/fleets/`,
    );
  });

  it("falls back to the release for an announcement the tab already had", () => {
    expect(whatsNewUrl("v9.9.0", announcement, after)).toBe(
      releaseUrl("v9.9.0"),
    );
  });

  it("keeps an absolute announcement link as it is", () => {
    expect(
      whatsNewUrl(
        "v9.9.0",
        { ...announcement, link: "https://example.com/news" },
        before,
      ),
    ).toBe("https://example.com/news");
  });
});

describe("useAppUpdateNotice", () => {
  beforeEach(() => {
    setActivePinia(createPinia());
  });

  it("shows nothing while the tab runs the live version", () => {
    useAppUpdateNotice(
      reactive({ version: "v9.8.0", codename: "X", isUpdateAvailable: false }),
    );

    expect(useNotificationsStore().messages).toHaveLength(0);
  });

  it("shows one persistent notice per new version", async () => {
    const source = reactive({
      version: "v9.8.0",
      codename: "X",
      isUpdateAvailable: false,
    });
    useAppUpdateNotice(source);

    source.version = "v9.9.0";
    source.isUpdateAvailable = true;
    await nextTick();

    expect(visibleNotices()).toHaveLength(1);
    expect(visibleNotices()[0]).toMatchObject({
      persist: true,
      timeout: false,
      componentProps: { version: "v9.9.0", codename: "X" },
    });

    source.version = "v9.10.0";
    await nextTick();

    expect(visibleNotices()).toHaveLength(1);
    expect(visibleNotices()[0].componentProps.version).toBe("v9.10.0");
  });
});
