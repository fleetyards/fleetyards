import { describe, expect, it, beforeEach } from "vitest";
import { setActivePinia, createPinia } from "pinia";
import { useRecurrence } from "./useRecurrence";
import { useI18nStore } from "@/shared/stores/i18n";

describe("useRecurrence", () => {
  beforeEach(() => {
    setActivePinia(createPinia());
    useI18nStore().locale = "en";
  });

  it("names a plain interval", () => {
    const { intervalLabel } = useRecurrence();

    expect(intervalLabel({ recurrenceInterval: "weekly" } as never)).toBe(
      "weekly",
    );
  });

  it("names an every-N interval", () => {
    const { intervalLabel } = useRecurrence();

    expect(
      intervalLabel({
        recurrenceInterval: "monthly",
        recurrenceEvery: 3,
      } as never),
    ).toBe("every 3 months");
  });

  // Monday first, whatever order the server sent Ruby's wday values in.
  it("lists the weekdays Monday first", () => {
    const { intervalLabel } = useRecurrence();

    expect(
      intervalLabel({
        recurrenceInterval: "weekly",
        recurrenceEvery: 2,
        recurrenceWeekdays: [0, 4, 2],
      } as never),
    ).toBe("every 2 weeks on Tue, Thu, & Sun");
  });

  it("says nothing for an event that does not repeat", () => {
    const { intervalLabel } = useRecurrence();

    expect(intervalLabel({} as never)).toBe("");
  });
});
