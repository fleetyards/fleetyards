import { afterEach, describe, expect, it, vi } from "vitest";
import { ref } from "vue";
import { useComlink } from "@/shared/composables/useComlink";

const route = ref<{
  path: string;
  query: Record<string, unknown>;
  hash: string;
}>({ path: "/hangar/", query: {}, hash: "" });

const replace = vi.fn();

vi.mock("vue-router", () => ({
  useRoute: () => route.value,
  useRouter: () => ({ replace }),
}));

const { useSupportModal, SUPPORT_QUERY_FLAG } =
  await import("./useSupportModal");

const comlink = useComlink();

describe("useSupportModal", () => {
  const unsubscribes: (() => void)[] = [];

  const onModalOpen = () => {
    const spy = vi.fn();
    unsubscribes.push(comlink.on("open-modal", spy));
    return spy;
  };

  afterEach(() => {
    unsubscribes.splice(0).forEach((unsubscribe) => unsubscribe());
    replace.mockClear();
    route.value = { path: "/hangar/", query: {}, hash: "" };
  });

  it("opens the modal for a flagged address", async () => {
    route.value.query = { [SUPPORT_QUERY_FLAG]: "true" };
    const opened = onModalOpen();

    await useSupportModal().openFromQuery();

    expect(opened).toHaveBeenCalled();
  });

  // Left in the address the flag would put the modal back up on every reload
  // and on the way back through history.
  it("takes the flag out of the address, keeping the rest", async () => {
    route.value.query = { [SUPPORT_QUERY_FLAG]: "true", tab: "ships" };

    await useSupportModal().openFromQuery();

    expect(replace).toHaveBeenCalledWith({
      path: "/hangar/",
      query: { tab: "ships" },
      hash: "",
    });
  });

  it("does nothing for an address without the flag", async () => {
    const opened = onModalOpen();

    await useSupportModal().openFromQuery();

    expect(opened).not.toHaveBeenCalled();
    expect(replace).not.toHaveBeenCalled();
  });

  it("comes back to the page the modal was over", () => {
    route.value.query = { tab: "ships" };

    expect(useSupportModal().supportReturnRoute()).toEqual({
      path: "/hangar/",
      query: { tab: "ships", [SUPPORT_QUERY_FLAG]: "true" },
      hash: "",
    });
  });

  // The page needs no flag: it shows the content without a modal.
  it("comes back to the support page on its own", () => {
    expect(useSupportModal().supportReturnRoute(true)).toEqual({
      name: "support",
    });
  });
});
