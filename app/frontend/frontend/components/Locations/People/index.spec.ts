import { describe, expect, it } from "vitest";
import { createRouter, createWebHashHistory } from "vue-router";
import { mountWithDefaults } from "@/shared/utils/TestUtils";
import {
  LocationKindEnum,
  type LocationLink,
  type LocationPerson,
} from "@/services/fyApi";
import Component from "./index.vue";

const router = async () => {
  const instance = createRouter({
    history: createWebHashHistory(),
    routes: [
      { path: "/", name: "home", component: { template: "<div />" } },
      {
        path: "/locations/:slug",
        name: "location",
        component: { template: "<div />" },
      },
      {
        path: "/fleets/:slug",
        name: "fleet",
        component: { template: "<div />" },
      },
    ],
  });

  await instance.push({ name: "home" });
  await instance.isReady();

  return instance;
};

const lorville: LocationLink = {
  id: "lorville",
  slug: "lorville",
  name: "Lorville",
  kind: LocationKindEnum.CITY,
  parentName: "Hurston",
};
const clinic: LocationLink = {
  id: "clinic",
  slug: "lorville-clinic",
  name: "Lorville Clinic",
  kind: LocationKindEnum.CLINIC,
  parentName: "Lorville",
};

const person = (overrides: Partial<LocationPerson>): LocationPerson => ({
  id: "user",
  username: "alpha",
  currentLocation: lorville,
  friend: false,
  fleets: [],
  ...overrides,
});

describe("LocationPeople", () => {
  it("names a place only where it is one inside the page's", async () => {
    const wrapper = await mountWithDefaults(Component, {
      props: {
        people: [
          person({ id: "a", username: "alpha", currentLocation: clinic }),
          person({ id: "b", username: "bravo" }),
        ],
        totalCount: 2,
        locationId: lorville.id,
      },
      plugins: [await router()],
    });

    const rows = wrapper.findAll("[data-test='location-person']");

    expect(rows).toHaveLength(2);
    expect(rows[0].text()).toContain("Lorville Clinic");
    expect(rows[1].find("[data-test='location-name']").exists()).toBe(false);
    expect(wrapper.find(".location-people__summary").text()).toBe("2");
  });

  it("says how the reader knows each of them", async () => {
    const wrapper = await mountWithDefaults(Component, {
      props: {
        people: [
          person({
            friend: true,
            fleets: [{ id: "f", slug: "ninetails", name: "Ninetails" }],
          }),
        ],
        totalCount: 1,
        locationId: lorville.id,
      },
      plugins: [await router()],
    });

    expect(wrapper.find("[data-test='location-person-friend']").exists()).toBe(
      true,
    );
    expect(wrapper.find("a[href='#/fleets/ninetails']").text()).toBe(
      "Ninetails",
    );
  });

  it("shows five, then the rest it was sent, and counts what it was not", async () => {
    const people = Array.from({ length: 7 }, (_, index) =>
      person({ id: `user-${index}`, username: `user-${index}` }),
    );

    const wrapper = await mountWithDefaults(Component, {
      props: { people, totalCount: 60, locationId: lorville.id },
      plugins: [await router()],
    });

    const rows = () => wrapper.findAll("[data-test='location-person']");

    expect(rows()).toHaveLength(5);
    expect(wrapper.find(".location-people__summary").text()).toBe("60");
    expect(
      wrapper.find("[data-test='location-people-unlisted']").exists(),
    ).toBe(false);

    await wrapper.find("[data-test='location-people-more']").trigger("click");

    expect(rows()).toHaveLength(7);
    expect(
      wrapper.find("[data-test='location-people-unlisted']").text(),
    ).toContain("53");
  });
});
