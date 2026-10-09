import { mountWithDefaults } from "@/shared/utils/TestUtils";
import { afterEach, describe, expect, it, vi } from "vitest";
import { ref } from "vue";
import {
  type Fleet,
  type Mission,
  MissionCategoryEnum,
  MissionStatusEnum,
} from "@/services/fyApi";
import Component from "./index.vue";

const missions = ref<{ items: Mission[] } | undefined>();
const isError = ref(false);

vi.mock("@/services/fyApi", async () => {
  const actual =
    await vi.importActual<Record<string, unknown>>("@/services/fyApi");

  return {
    ...actual,
    useFleetMissions: () => ({
      data: missions,
      isLoading: ref(false),
      isError,
    }),
  };
});

const fleet = { slug: "test" } as Fleet;

const mission = (attributes: Partial<Mission>): Mission =>
  ({
    id: attributes.slug,
    title: attributes.slug,
    category: MissionCategoryEnum.OTHER,
    status: MissionStatusEnum.PUBLISHED,
    teamCount: 1,
    shipCount: 2,
    ...attributes,
  }) as Mission;

const mounted: { unmount: () => void }[] = [];

const mountPicker = async (onPick = vi.fn()) => {
  const wrapper = await mountWithDefaults(Component, {
    props: { fleet, onPick },
  });
  mounted.push(wrapper);

  return wrapper;
};

afterEach(() => {
  mounted.splice(0).forEach((wrapper) => wrapper.unmount());
  missions.value = undefined;
  isError.value = false;
});

describe("MissionTemplatePicker", () => {
  it("offers published missions and leaves drafts out", async () => {
    missions.value = {
      items: [
        mission({ slug: "bluebird" }),
        mission({ slug: "unfinished", status: MissionStatusEnum.DRAFT }),
      ],
    };
    const wrapper = await mountPicker();

    expect(
      wrapper.find('[data-test="mission-template-bluebird"]').exists(),
    ).toBe(true);
    expect(
      wrapper.find('[data-test="mission-template-unfinished"]').exists(),
    ).toBe(false);
  });

  it("hands the picked mission to the caller", async () => {
    missions.value = { items: [mission({ slug: "bluebird" })] };
    const onPick = vi.fn();
    const wrapper = await mountPicker(onPick);

    await wrapper
      .find('[data-test="mission-template-bluebird"]')
      .trigger("click");

    expect(onPick).toHaveBeenCalledWith(
      expect.objectContaining({ slug: "bluebird" }),
    );
  });

  it("still offers no template when the fleet has no missions", async () => {
    missions.value = { items: [] };
    const onPick = vi.fn();
    const wrapper = await mountPicker(onPick);

    await wrapper.find('[data-test="mission-template-none"]').trigger("click");

    expect(onPick).toHaveBeenCalledWith(null);
  });

  it("says the missions failed to load rather than that there are none", async () => {
    isError.value = true;
    const wrapper = await mountPicker();

    expect(wrapper.find('[data-test="mission-template-error"]').exists()).toBe(
      true,
    );
    expect(wrapper.text()).not.toContain("No missions yet.");
  });
});
