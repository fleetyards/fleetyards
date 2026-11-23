import { mountWithDefaults } from "@/shared/utils/TestUtils";
import { beforeEach, describe, expect, it, vi } from "vitest";
import Component from "./index.vue";
import type { ModelPaint } from "@/services/fyApi";

// The cards carry a store image, and jsdom has no IntersectionObserver for
// useLazyBackground to hand it to.
beforeEach(() => {
  vi.stubGlobal(
    "IntersectionObserver",
    class {
      observe() {}
      unobserve() {}
      disconnect() {}
    },
  );
});

const paint = (id: string) =>
  ({ id, name: id, slug: id, media: {} }) as unknown as ModelPaint;

const paints = ref<ModelPaint[]>([]);
const ownedIds = ref<string[] | undefined>(undefined);
const hangarPaintsEnabled = vi.fn();

vi.mock("@/services/fyApi", async (importOriginal) => ({
  ...(await importOriginal<typeof import("@/services/fyApi")>()),
  useModelPaints: () => ({
    data: paints,
    isSuccess: ref(true),
    isError: ref(false),
    isLoading: ref(false),
    isFetching: ref(false),
    error: ref(null),
    refetch: vi.fn(),
  }),
  useHangarPaints: (options: { query: { enabled: Ref<boolean> } }) => {
    hangarPaintsEnabled(unref(options.query.enabled));
    return { data: ownedIds };
  },
}));

const mount = (authenticated: boolean) =>
  mountWithDefaults(Component, {
    props: { modelSlug: "carrack" },
    initialState: { session: { authenticated } },
  });

const ownedNames = (wrapper: Awaited<ReturnType<typeof mount>>) =>
  wrapper
    .findAll('[data-test="model-paint"]')
    .filter((card) => card.find('[data-test="model-paint-owned"]').exists())
    .map((card) => card.find("h3").text());

describe("ModelPaintList", () => {
  it("marks the paints you own", async () => {
    paints.value = [paint("Polar"), paint("Kepler"), paint("Copernicus")];
    ownedIds.value = ["Kepler", "Copernicus"];

    const wrapper = await mount(true);

    expect(hangarPaintsEnabled).toHaveBeenLastCalledWith(true);
    expect(ownedNames(wrapper)).toEqual(["Kepler", "Copernicus"]);
  });

  it("asks for no hangar and marks nothing when signed out", async () => {
    paints.value = [paint("Polar")];
    ownedIds.value = undefined;

    const wrapper = await mount(false);

    expect(hangarPaintsEnabled).toHaveBeenLastCalledWith(false);
    expect(wrapper.findAll('[data-test="model-paint"]')).toHaveLength(1);
    expect(ownedNames(wrapper)).toEqual([]);
  });
});
