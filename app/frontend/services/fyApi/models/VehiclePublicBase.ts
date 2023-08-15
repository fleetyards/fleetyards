/* generated using openapi-typescript-codegen -- do no edit */
/* istanbul ignore file */
/* tslint:disable */
/* eslint-disable */

import type { HangarGroup } from './HangarGroup';
import type { ModelMinimal } from './ModelMinimal';
import type { ModelModulePackage } from './ModelModulePackage';
import type { ModelPaint } from './ModelPaint';

export type VehiclePublicBase = {
    id: string;
    name?: string | null;
    slug?: string | null;
    serial?: string | null;
    hangarGroupIds: Array<string>;
    hangarGroups: Array<HangarGroup>;
    loaner: boolean;
    model: ModelMinimal;
    username?: string | null;
    userAvatar?: string | null;
    modelModuleIds: Array<string>;
    modelUpgradeIds: Array<string>;
    modulePackage?: ModelModulePackage | null;
    paint?: ModelPaint | null;
};

