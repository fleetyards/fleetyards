import { mountWithDefaults } from "@/shared/utils/TestUtils";
import { describe, expect, it } from "vitest";
import Component from "./index.vue";
import type { SyncNumberTextValue } from "./types";

const plainText = async (text: SyncNumberTextValue) =>
  (await mountWithDefaults<typeof Component>(Component, { props: { text } }))
    .get("[data-text]")
    .attributes("data-text");

describe("HangarSyncNumberText", () => {
  it("chooses the plural form the count asks for", async () => {
    const key = "labels.syncExtension.stepDetails.sent";

    expect(await plainText({ key, values: { count: 1 } })).toBe("Sent 1 item");
    expect(await plainText({ key, values: { count: 3 } })).toBe("Sent 3 items");
    expect(await plainText({ key, values: { count: 0 } })).toBe("Sent 0 items");
  });

  it("fills every placeholder of a line without plural forms", async () => {
    expect(
      await plainText({
        key: "labels.syncExtension.stepDetails.pageOf",
        values: { page: 3, total: 58 },
      }),
    ).toBe("Page 3 of 58");
  });

  it("renders a line with no translation of its own", async () => {
    expect(
      await plainText({ template: "+%{count}", values: { count: 2 } }),
    ).toBe("+2");
  });
});
