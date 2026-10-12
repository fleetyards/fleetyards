import { createPinia, setActivePinia } from "pinia";
import { useRule } from "./vehicleSerial";

describe("vehicleSerial rule", () => {
  beforeEach(() => {
    setActivePinia(createPinia());
  });

  const validate = (value: string) =>
    useRule()(value, [undefined], {
      field: "Serial",
    } as FieldValidationMetaInfo);

  it.each(["", "L8-4261-HA", "l84261ha", " L8 4261 HA "])(
    "accepts %s",
    (value) => {
      expect(validate(value)).toBe(true);
    },
  );

  it.each(["F-9", "SUB FLAGSHIP", "L8-4261-HAX"])("rejects %s", (value) => {
    expect(validate(value)).toBe(
      "The Serial field must look like the registration the game shows, such as L8-4261-HA",
    );
  });
});
