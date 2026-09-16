import { describe, expect, it } from "vitest";

import { sameApartFromModalQuery } from "./ModalQuery";

const route = (
  path: string,
  query: Record<string, unknown> = {},
  hash = "",
) => ({ path, query, hash });

describe("sameApartFromModalQuery", () => {
  it("is true when only the modal is opened", () => {
    expect(
      sameApartFromModalQuery(
        route("/", { modal: "support" }),
        route("/", {}),
      ),
    ).toBe(true);
  });

  it("is true when only the modal is closed", () => {
    expect(
      sameApartFromModalQuery(route("/", {}), route("/", { modal: "support" })),
    ).toBe(true);
  });

  it("keeps the rest of the query out of it", () => {
    expect(
      sameApartFromModalQuery(
        route("/ships/", { modal: "support", page: "2" }),
        route("/ships/", { page: "2" }),
      ),
    ).toBe(true);
  });

  it("is false when another parameter changes with it", () => {
    expect(
      sameApartFromModalQuery(
        route("/ships/", { modal: "support", page: "3" }),
        route("/ships/", { page: "2" }),
      ),
    ).toBe(false);
  });

  it("is false when a parameter is dropped", () => {
    expect(
      sameApartFromModalQuery(
        route("/ships/", { modal: "support" }),
        route("/ships/", { page: "2" }),
      ),
    ).toBe(false);
  });

  it("is false for another page or another anchor", () => {
    expect(
      sameApartFromModalQuery(
        route("/support/", { modal: "support" }),
        route("/", {}),
      ),
    ).toBe(false);

    expect(
      sameApartFromModalQuery(
        route("/", { modal: "support" }, "#top"),
        route("/", {}, "#ships"),
      ),
    ).toBe(false);
  });

  it("compares a repeated parameter by its values", () => {
    expect(
      sameApartFromModalQuery(
        route("/ships/", { modal: "support", tag: ["a", "b"] }),
        route("/ships/", { tag: ["a", "b"] }),
      ),
    ).toBe(true);

    expect(
      sameApartFromModalQuery(
        route("/ships/", { modal: "support", tag: ["a", "b"] }),
        route("/ships/", { tag: ["a"] }),
      ),
    ).toBe(false);
  });
});
