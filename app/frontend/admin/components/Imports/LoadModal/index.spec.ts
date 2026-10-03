import { describe, expect, it, vi } from "vitest";
import { flushPromises } from "@vue/test-utils";
import { mountWithDefaults } from "@/shared/utils/TestUtils";
import {
  type Import,
  ImportStatusEnum,
  ImportTypeEnum,
} from "@/services/fyAdminApi";
import Component from "./index.vue";

const mutateAsync = vi.fn(async () => ({ message: "Jobs enqueued" }));

vi.mock("@/services/fyAdminApi", async (importOriginal) => ({
  ...(await importOriginal<typeof import("@/services/fyAdminApi")>()),
  useStartImportLoad: () => ({ mutateAsync }),
}));

vi.mock("@/shared/composables/useAppNotifications", () => ({
  useAppNotifications: () => ({
    displaySuccess: vi.fn(),
    displayAlert: vi.fn(),
  }),
}));

vi.mock("@/shared/components/AppModal/Inner/index.vue", () => ({
  default: { name: "Modal", template: "<div><slot /></div>" },
}));

const ptuLoad = {
  id: "import-1",
  type: ImportTypeEnum.IMPORTS_SC_DATA_ALL_IMPORT,
  status: ImportStatusEnum.STARTED,
  version: "4.10.1-ptu.12578875",
  createdAt: "2026-10-03T00:00:00Z",
  updatedAt: "2026-10-03T00:00:00Z",
} as Import;

const mount = (imports: Record<string, Import> = {}) =>
  mountWithDefaults(Component, {
    props: { group: "scData" },
    initialState: { adminImports: { imports } },
  });

describe("ImportsLoadModal", () => {
  it("offers every game data load, one per environment", async () => {
    const wrapper = await mount();

    const rows = wrapper
      .findAll("[data-test^='import-loader-']")
      .filter((row) => row.element.tagName === "LI")
      .map((row) => row.attributes("data-test"));

    expect(rows).toEqual([
      "import-loader-sc_data_live",
      "import-loader-sc_data_ptu",
      "import-loader-sc_data_models",
      "import-loader-uex_commodity_prices",
      "import-loader-uex_component_prices",
      "import-loader-uex_equipment_prices",
      "import-loader-uex_trade_routes",
    ]);
  });

  it("shows a running ptu load as loading, and leaves live to be started", async () => {
    const wrapper = await mount({ [ptuLoad.id]: ptuLoad });

    const ptu = wrapper.get("[data-test='import-loader-start-sc_data_ptu']");
    const live = wrapper.get("[data-test='import-loader-start-sc_data_live']");

    expect(ptu.attributes("disabled")).toBeDefined();
    expect(live.attributes("disabled")).toBeUndefined();

    await live.trigger("click");
    await flushPromises();

    expect(mutateAsync).toHaveBeenCalledWith({
      data: { loader: "sc_data", environment: "live" },
    });
  });
});
