import type {
  PortOverrides,
  PowerColumn,
  PowerColumnMember,
} from "@/frontend/composables/useLoadoutSim";

export interface PipCell {
  // The allocation this cell stands for: its top edge.
  level: number;
  // How many segments the cell spans; the mandatory floor is one tall block.
  span: number;
}

// Move a member (a single component or the weapon pool) toward `desired`
// segments: it is off (0) or on at its mandatory floor or above, and an
// increase never exceeds what the pool has left, so asking for more with an
// empty pool changes nothing. Returns the new overrides, or undefined when the
// allocation stays as it is.
export function setMemberTarget(
  overrides: PortOverrides,
  member: PowerColumnMember,
  desired: number,
  remaining: number,
): PortOverrides | undefined {
  let target = Math.max(0, Math.min(member.fillable, desired));
  if (target > 0 && target < member.min) target = 0;

  if (target > member.allocated) {
    if (member.allocated === 0) {
      if (remaining < member.min) return undefined;
      target = Math.min(target, remaining);
    } else {
      target = Math.min(target, member.allocated + remaining);
    }
  }

  if (target === member.allocated) return undefined;
  return { ...overrides, [member.portPath]: target };
}

// A click on the pip at `level`. In a column shared by several parts the
// merged floor block sets that part to its minimum, or switches it off when it
// already sits there, so a part with headroom can still drop back to its floor
// without jumping to full. Every other pip asks for exactly `level`.
export function pipClickTarget(
  overrides: PortOverrides,
  column: PowerColumn,
  member: PowerColumnMember,
  level: number,
  remaining: number,
): PortOverrides | undefined {
  if (level > member.fillable) return undefined;

  if (column.members.length > 1 && level === member.min) {
    const desired = member.allocated === member.min ? 0 : member.min;
    return setMemberTarget(overrides, member, desired, remaining);
  }

  return setMemberTarget(overrides, member, level, remaining);
}

// Drain the whole column when any part in it has power, else fill every part.
export function toggleColumnOverrides(
  overrides: PortOverrides,
  column: PowerColumn,
): PortOverrides {
  const anyOn = column.members.some((member) => member.allocated > 0);
  const next: PortOverrides = { ...overrides };
  for (const member of column.members) {
    next[member.portPath] = anyOn ? 0 : member.fillable;
  }
  return next;
}

export function pipCells(member: PowerColumnMember): PipCell[] {
  const cells: PipCell[] = [];
  if (member.min > 0) cells.push({ level: member.min, span: member.min });
  for (let level = member.min + 1; level <= member.capacity; level += 1) {
    cells.push({ level, span: 1 });
  }
  return cells;
}
