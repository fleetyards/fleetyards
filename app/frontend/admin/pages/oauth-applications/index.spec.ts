import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import { flushPromises } from "@vue/test-utils";
import { createRouter, createMemoryHistory } from "vue-router";
import { mountWithDefaults } from "@/shared/utils/TestUtils";
import type { OauthApplication } from "@/services/fyAdminApi";

const device = vi.hoisted(() => ({ mobile: false }));

const queries = vi.hoisted(() => [] as unknown[]);

vi.mock("@/shared/composables/useMobile", () => ({
  useMobile: () => ref(device.mobile),
}));

const application = (
  id: string,
  overrides: Partial<OauthApplication> = {},
): OauthApplication => ({
  id,
  name: `App ${id}`,
  uid: `uid-${id}`,
  secret: "secret",
  confidential: true,
  redirectUri: "https://one.example.com/callback\nhttps://two.example.com/cb",
  scopes: "public hangar",
  ownerName: "pilot",
  ownerId: "11111111-1111-1111-1111-111111111111",
  state: "approved",
  rejectionReason: null,
  approvedAt: "2026-08-02T00:00:00Z",
  rejectedAt: null,
  reviewedByName: "admin",
  authorizedUsersCount: 3,
  createdAt: "2026-08-01T00:00:00Z",
  updatedAt: "2026-08-03T00:00:00Z",
  ...overrides,
});

const settled = (data: unknown) => ({
  data: ref(data),
  error: ref(null),
  isPending: ref(false),
  isFetching: ref(false),
  isError: ref(false),
  isSuccess: ref(true),
  fetchStatus: ref("idle"),
  isLoading: ref(false),
  isRefetching: ref(false),
  refetch: vi.fn(),
});

vi.mock("@/services/fyAdminApi", async (importOriginal) => ({
  ...(await importOriginal<Record<string, unknown>>()),
  useOauthApplications: (params: unknown) => {
    queries.push(params);

    return settled({
      items: [
        application("1"),
        application("2", {
          state: "rejected",
          scopes: "",
          rejectionReason: "Looks like spam",
          approvedAt: null,
          rejectedAt: "2026-08-04T00:00:00Z",
        }),
      ],
      meta: { pagination: { totalCount: 2, currentPage: 1, totalPages: 1 } },
    });
  },
}));

import AdminOauthApplicationsPage from "./index.vue";

let mounted: { unmount: () => void } | undefined;

let router: ReturnType<typeof createRouter>;

const mount = async (path = "/oauth-applications/") => {
  router = createRouter({
    history: createMemoryHistory(),
    routes: [
      {
        path: "/oauth-applications/",
        name: "admin-oauth-applications",
        component: {},
      },
      {
        path: "/oauth-applications/create/",
        name: "admin-oauth-application-create",
        component: {},
      },
      {
        path: "/oauth-applications/:id/edit",
        name: "admin-oauth-application-edit",
        component: {},
      },
    ],
  });

  await router.push(path);

  const wrapper = await mountWithDefaults(AdminOauthApplicationsPage, {
    plugins: [router],
    attachTo: document.getElementById("app")!,
  });

  await flushPromises();

  mounted = wrapper;

  return wrapper;
};

const lastQuery = () =>
  toValue(queries[queries.length - 1] as Ref<{ q: Record<string, unknown> }>);

beforeEach(() => {
  document.body.innerHTML =
    '<div id="header-left"></div><div id="header-right"></div><div id="off-canvas-content"></div><div id="app"></div>';
  queries.length = 0;
  device.mobile = false;
});

afterEach(() => {
  mounted?.unmount();
  mounted = undefined;
});

describe("AdminOauthApplicationsPage", () => {
  it("asks the API for what the URL filters on, the way the review notification links it", async () => {
    await mount("/oauth-applications/?aasmStateEq=pending&s=name%20asc");

    expect(lastQuery().q).toEqual({
      aasmStateEq: "pending",
      sorts: ["name asc"],
    });
  });

  it("shows the review, scopes, usage and redirect host on desktop", async () => {
    const wrapper = await mount();

    const approved = wrapper.find("[id='1']");
    const rejected = wrapper.find("[id='2']");

    expect(approved.find("[data-test='redirect-host']").text()).toContain(
      "one.example.com",
    );
    expect(approved.find("[data-test='review-summary']").text()).toContain(
      "admin",
    );
    expect(approved.text()).toContain("hangar");
    expect(approved.text()).toContain("3");
    expect(rejected.find("[data-test='rejection-reason']").text()).toBe(
      "Looks like spam",
    );
    expect(approved.find("[data-test='mobile-owner']").exists()).toBe(false);
  });

  it("filters by an owner when the owner is clicked", async () => {
    const wrapper = await mount();

    await wrapper.find("[data-test='owner-filter']").trigger("click");
    await flushPromises();

    expect(router.currentRoute.value.query.ownerIdEq).toBe(
      "11111111-1111-1111-1111-111111111111",
    );
    expect(lastQuery().q).toMatchObject({
      ownerIdEq: "11111111-1111-1111-1111-111111111111",
    });
  });

  it("keeps owner, usage and scopes on a phone, where those columns are gone", async () => {
    device.mobile = true;

    const wrapper = await mount();

    expect(wrapper.find("[data-test='owner-filter']").exists()).toBe(false);

    const approved = wrapper.find("[id='1']");
    const rejected = wrapper.find("[id='2']");

    expect(approved.find("[data-test='mobile-owner']").text()).toContain(
      "pilot",
    );
    expect(approved.find("[data-test='mobile-owner']").text()).toContain("3");
    expect(approved.find("[data-test='mobile-scopes']").text()).toContain(
      "public, hangar",
    );
    expect(rejected.find("[data-test='mobile-scopes']").text()).not.toBe("");
    expect(rejected.find("[data-test='rejection-reason']").exists()).toBe(true);
    expect(rejected.find("[data-test='mobile-state']").exists()).toBe(true);
  });
});
