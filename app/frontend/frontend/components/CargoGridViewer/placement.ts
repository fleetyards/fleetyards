import type { CargoHold } from "@/services/fyApi";

export type HoldPlacement = {
  // The hold's lowest corner in metres: x along the tool's floor, y across
  // it, z up.
  offset: { x: number; y: number; z: number };
  // Turned a quarter about the vertical, so its length runs across the floor.
  turned: boolean;
};

const QUARTER = Math.PI / 2;

// The tool's unturned hold lies a quarter turn from the hull holo's frame --
// the Caterpillar's modules are turned -90 degrees in the export and run
// along the tool's floor -- so the whole ship is turned by that first.
const SHIP_TURN = -QUARTER;

/**
 * Where the cargo grid tool draws a hold the hull export placed: its centre
 * and quaternion in the hull holo's frame (glTF, y up) read into the tool's
 * floor. The API only places a parent whose grids all stand upright and turn
 * by quarters.
 */
export const holdPlacement = (hold: CargoHold): HoldPlacement | undefined => {
  const { position, rotation } = hold;
  if (!position || position.length !== 3 || !rotation || rotation.length !== 4)
    return undefined;

  const [, qy, , qw] = rotation;
  const turn = 2 * Math.atan2(qy, qw) + SHIP_TURN;
  const turned = Math.abs(Math.round(turn / QUARTER)) % 2 === 1;

  const { x: length, y: width, z: height } = hold.dimensions;
  const [extentX, extentY] = turned ? [width, length] : [length, width];

  // The ship turned by SHIP_TURN about the vertical, then glTF's (x, up, z)
  // read as the tool's (x, y, up).
  const [x, up, z] = position;
  const centre = {
    x: x * Math.cos(SHIP_TURN) + z * Math.sin(SHIP_TURN),
    y: -x * Math.sin(SHIP_TURN) + z * Math.cos(SHIP_TURN),
    z: up,
  };

  return {
    offset: {
      x: centre.x - extentX / 2,
      y: centre.y - extentY / 2,
      z: centre.z - height / 2,
    },
    turned,
  };
};
