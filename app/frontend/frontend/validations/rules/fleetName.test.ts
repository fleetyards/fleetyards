import { createPinia, setActivePinia } from "pinia";
import { useRule } from "./fleetName";

describe("fleetName rule", () => {
  beforeEach(() => {
    setActivePinia(createPinia());
  });

  const validate = (value: string) =>
    useRule()(value, [undefined], { field: "Name" } as FieldValidationMetaInfo);

  it.each(["MARU Inc.", "Test Fleet", "fleet_name-1"])(
    "accepts %s",
    (value) => {
      expect(validate(value)).toBe(true);
    },
  );

  it.each(["Fleet!", "Flotte ä", "a/b"])("rejects %s", (value) => {
    expect(validate(value)).toBe(
      "The Name field may contain alpha-numeric characters, spaces, dots, dashes and underscores",
    );
  });
});
