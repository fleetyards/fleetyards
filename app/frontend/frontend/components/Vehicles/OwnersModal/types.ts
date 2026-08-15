import type { MemberContact } from "@/frontend/components/base/MemberContactMenu/types";

export interface Owner {
  key: string;
  // Absent for vehicles whose owner is not public: those carry no identity at
  // all, so there is nobody to contact.
  member?: MemberContact;
  avatar?: string;
  count: number;
  ships: string[];
}
