import { mountWithDefaults } from "@/shared/utils/TestUtils";
import { describe, expect, it, vi } from "vitest";
import Component from "./log.vue";
import type { Vehicle, VehicleLogEntry } from "@/services/fyApi";

const entry = (
  id: string,
  loggedAt: string,
  isPublic: boolean,
): VehicleLogEntry => ({
  id,
  title: id,
  body: null,
  loggedAt,
  public: isPublic,
  createdAt: loggedAt,
  updatedAt: loggedAt,
});

vi.mock("@/services/fyApi", async (importOriginal) => ({
  ...(await importOriginal<typeof import("@/services/fyApi")>()),
  useVehicleLogEntries: () => ({
    data: ref([
      entry("Four years", "2026-10-11T20:00:00Z", true),
      entry("Checkmate", "2025-11-02T00:10:00Z", false),
      entry("Pyro", "2025-03-09T18:20:00Z", true),
    ]),
    isLoading: ref(false),
  }),
}));

const vehicle = {
  id: "vehicle-1",
  public: true,
  wanted: false,
  logEntriesPublicByDefault: false,
} as Vehicle;

const mount = () => mountWithDefaults(Component, { props: { vehicle } });

const titles = (wrapper: Awaited<ReturnType<typeof mount>>) =>
  wrapper
    .findAll('[data-test="vehicle-log-entry"] h3')
    .map((title) => title.text());

describe("HangarVehicleLogPage", () => {
  it("tells the log in years, newest first", async () => {
    const wrapper = await mount();

    expect(
      wrapper.findAll(".vehicle-log__year-title").map((year) => year.text()),
    ).toEqual(["2026", "2025"]);
    expect(titles(wrapper)).toEqual(["Four years", "Checkmate", "Pyro"]);
  });

  it("narrows the log to the public entries", async () => {
    const wrapper = await mount();

    await wrapper
      .find('[data-test="vehicle-log-filter-public"]')
      .trigger("click");

    expect(titles(wrapper)).toEqual(["Four years", "Pyro"]);
  });

  it("narrows the log to the private entries", async () => {
    const wrapper = await mount();

    await wrapper
      .find('[data-test="vehicle-log-filter-private"]')
      .trigger("click");

    expect(titles(wrapper)).toEqual(["Checkmate"]);
  });
});
