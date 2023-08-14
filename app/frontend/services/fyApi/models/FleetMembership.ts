/* generated using openapi-typescript-codegen -- do no edit */
/* istanbul ignore file */
/* tslint:disable */
/* eslint-disable */

import type { FleetMembershipRoleEnum } from './FleetMembershipRoleEnum';
import type { FleetMembershipShipsFilterEnum } from './FleetMembershipShipsFilterEnum';
import type { FleetMembershipStatusEnum } from './FleetMembershipStatusEnum';
import type { FleetMinimal } from './FleetMinimal';

export type FleetMembership = {
    id: string;
    username: string;
    role: FleetMembershipRoleEnum;
    roleLabel: string;
    status?: FleetMembershipStatusEnum;
    invitedAt?: string | null;
    requestedAt?: string | null;
    acceptedAt?: string | null;
    acceptedAtLabel?: string | null;
    declinedAt?: string | null;
    declinedAtLabel?: string | null;
    avatar?: string | null;
    rsiHandle?: string | null;
    homepage?: string | null;
    discord?: string | null;
    youtube?: string | null;
    twitch?: string | null;
    shipsFilter: FleetMembershipShipsFilterEnum;
    hangarGroupId?: string | null;
    fleetSlug: string;
    fleetName: string;
    fleet: FleetMinimal;
    createdAt: string;
    updatedAt: string;
};

