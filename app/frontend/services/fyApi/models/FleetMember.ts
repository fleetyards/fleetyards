/* generated using openapi-typescript-codegen -- do no edit */
/* istanbul ignore file */
/* tslint:disable */
/* eslint-disable */

import type { FleetMembershipRoleEnum } from './FleetMembershipRoleEnum';
import type { FleetMembershipShipsFilterEnum } from './FleetMembershipShipsFilterEnum';
import type { FleetMembershipStatusEnum } from './FleetMembershipStatusEnum';
import type { FleetMinimal } from './FleetMinimal';

export type FleetMember = {
    id: string;
    username: string;
    role: FleetMembershipRoleEnum;
    roleLabel: string;
    status?: FleetMembershipStatusEnum;
    avatar?: string | null;
    rsiHandle?: string | null;
    homepage?: string | null;
    discord?: string | null;
    youtube?: string | null;
    twitch?: string | null;
    guilded?: string | null;
    shipsFilter: FleetMembershipShipsFilterEnum;
    hangarGroupId?: string | null;
    fleetSlug: string;
    fleetName: string;
    fleet?: FleetMinimal;
    primary?: boolean;
    hangarUpdatedAt?: string | null;
    invitedAt?: string;
    invitedAtLabel?: string;
    requestedAt?: string;
    requestedAtLabel?: string;
    acceptedAt?: string;
    acceptedAtLabel?: string;
    declinedAt?: string;
    declinedAtLabel?: string;
    createdAt: string;
    updatedAt: string;
};

