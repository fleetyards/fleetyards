import { mountWithDefaults } from "@/shared/utils/TestUtils";
import { afterEach, describe, expect, it, vi } from "vitest";
import { type MaybeRefOrGetter, ref, toValue } from "vue";
import {
  type Fleet,
  type FleetMissionsParams,
  type Mission,
  MissionCategoryEnum,
  MissionStatusEnum,
} from "@/services/fyApi";
import Component from "./index.vue";

type MissionsPage = {
  items: Mission[];
  meta?: { pagination: { totalPages: number } };
};

const missions = ref<MissionsPage | undefined>();
const anyMission = ref<MissionsPage | undefined>();
const isLoading = ref(false);
const isPlaceholderData = ref(false);
const isError = ref(false);
const refetch = vi.fn();
const requested: MaybeRefOrGetter<FleetMissionsParams>[] = [];

vi.mock("@/services/fyApi", async () => {
  const actual =
    await vi.importActual<Record<string, unknown>>("@/services/fyApi");

  return {
    ...actual,
    // The picker asks twice: its published list, and a one-row probe of any
    // status that only runs when that list is empty.
    useFleetMissions: (
      _slug: unknown,
      params: MaybeRefOrGetter<FleetMissionsParams>,
    ) => {
      if (toValue(params).perPage === "1") {
        return { data: anyMission };
      }

      requested.push(params);

      return {
        data: missions,
        isLoading,
        isPlaceholderData,
        isError,
        refetch,
      };
    },
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
  anyMission.value = undefined;
  requested.splice(0);
  isError.value = false;
  isLoading.value = false;
  isPlaceholderData.value = false;
  refetch.mockClear();
});

describe("MissionTemplatePicker", () => {
  it("asks the server for published missions only", async () => {
    missions.value = { items: [mission({ slug: "bluebird" })] };
    const wrapper = await mountPicker();

    expect(toValue(requested[0]).q?.statusEq).toBe(MissionStatusEnum.PUBLISHED);
    expect(
      wrapper.find('[data-test="mission-template-bluebird"]').exists(),
    ).toBe(true);
  });

  it("loads the next page onto the list", async () => {
    missions.value = {
      items: [mission({ slug: "bluebird" })],
      meta: { pagination: { totalPages: 2 } },
    };
    const wrapper = await mountPicker();

    await wrapper.find('[data-test="mission-template-more"]').trigger("click");

    expect(toValue(requested[0]).page).toBe("2");

    // The query client shows the previous page while the next one loads; the
    // button stays to say so.
    isPlaceholderData.value = true;
    await wrapper.vm.$nextTick();

    expect(wrapper.find('[data-test="mission-template-more"]').exists()).toBe(
      true,
    );

    isPlaceholderData.value = false;
    missions.value = {
      items: [mission({ slug: "redbird" })],
      meta: { pagination: { totalPages: 2 } },
    };
    await wrapper.vm.$nextTick();

    expect(
      wrapper.find('[data-test="mission-template-bluebird"]').exists(),
    ).toBe(true);
    expect(
      wrapper.find('[data-test="mission-template-redbird"]').exists(),
    ).toBe(true);
    expect(wrapper.find('[data-test="mission-template-more"]').exists()).toBe(
      false,
    );
  });

  it("says it is loading, not that nothing matches, while a new search runs", async () => {
    vi.useFakeTimers();
    missions.value = { items: [mission({ slug: "bluebird" })] };
    const wrapper = await mountPicker();

    await wrapper
      .find('[data-test="mission-template-search"] input')
      .setValue("red");
    // The previous search stands in as placeholder data until "red" answers.
    isPlaceholderData.value = true;
    vi.advanceTimersByTime(300);
    await wrapper.vm.$nextTick();

    expect(
      wrapper.find('[data-test="mission-template-loading"]').exists(),
    ).toBe(true);
    expect(wrapper.find('[data-test="mission-template-empty"]').exists()).toBe(
      false,
    );
    expect(
      wrapper.find('[data-test="mission-template-bluebird"]').exists(),
    ).toBe(false);
    expect(toValue(requested[0]).q?.titleCont).toBe("red");

    vi.useRealTimers();
  });

  it("offers a retry when a later page fails to load", async () => {
    missions.value = {
      items: [mission({ slug: "bluebird" })],
      meta: { pagination: { totalPages: 2 } },
    };
    const wrapper = await mountPicker();

    await wrapper.find('[data-test="mission-template-more"]').trigger("click");
    isError.value = true;
    await wrapper.vm.$nextTick();

    expect(
      wrapper.find('[data-test="mission-template-bluebird"]').exists(),
    ).toBe(true);
    expect(wrapper.find('[data-test="mission-template-error"]').exists()).toBe(
      false,
    );

    await wrapper
      .find('[data-test="mission-template-page-retry"]')
      .trigger("click");

    expect(refetch).toHaveBeenCalled();
    expect(toValue(requested[0]).page).toBe("2");
  });

  it("says none is published when the fleet only has drafts", async () => {
    missions.value = { items: [] };
    anyMission.value = {
      items: [mission({ slug: "unfinished", status: MissionStatusEnum.DRAFT })],
    };
    const wrapper = await mountPicker();

    expect(
      wrapper.find('[data-test="mission-template-empty"]').text(),
    ).toContain("None of the fleet's active missions is published yet.");
  });

  it("says the fleet has no active missions when it has none", async () => {
    missions.value = { items: [] };
    anyMission.value = { items: [] };
    const wrapper = await mountPicker();

    expect(
      wrapper.find('[data-test="mission-template-empty"]').text(),
    ).toContain("The fleet has no active missions.");
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
    expect(wrapper.text()).not.toContain("The fleet has no active missions.");
  });

  it("keeps a list it already has when a refetch fails", async () => {
    missions.value = { items: [mission({ slug: "bluebird" })] };
    isError.value = true;
    const wrapper = await mountPicker();

    expect(wrapper.find('[data-test="mission-template-error"]').exists()).toBe(
      false,
    );
    expect(
      wrapper.find('[data-test="mission-template-bluebird"]').exists(),
    ).toBe(true);
  });

  it("loads the missions again from the error", async () => {
    isError.value = true;
    const wrapper = await mountPicker();

    await wrapper.find('[data-test="mission-template-retry"]').trigger("click");

    expect(refetch).toHaveBeenCalled();
  });
});
