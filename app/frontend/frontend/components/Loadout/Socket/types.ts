// What a socket holds, as the socket shows it: no slot type's own record, so
// modules, weapons and the rest all reach it through their caller.
export interface LoadoutSocketItem {
  id: string;
  name: string;
  image?: string;
  // One figure that says what the item brings, already formatted.
  figure?: string;
}

export interface LoadoutSocketSlot {
  id: string;
  label: string;
  size?: string;
  item?: LoadoutSocketItem;
}

export interface LoadoutSocketGroup {
  key: string;
  // Left out where every slot is its own mount, so a lone heading does not
  // repeat the socket's label.
  label?: string;
  slots: LoadoutSocketSlot[];
}
