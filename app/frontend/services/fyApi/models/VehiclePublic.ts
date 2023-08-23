/* generated using openapi-typescript-codegen -- do no edit */
/* istanbul ignore file */
/* tslint:disable */
/* eslint-disable */

import type { HangarGroupPublic } from './HangarGroupPublic';
import type { Model } from './Model';
import type { ModelModulePackage } from './ModelModulePackage';
import type { ModelPaint } from './ModelPaint';

export type VehiclePublic = {
    id: string;
    name?: string;
    slug?: string;
    serial?: string;
    hangarGroupIds: Array<string>;
    hangarGroups: Array<HangarGroupPublic>;
    loaner: boolean;
    model: Model;
    username?: string;
    userAvatar?: string;
    modelModuleIds: Array<string>;
    modelUpgradeIds: Array<string>;
    modulePackage?: ModelModulePackage;
    paint?: ModelPaint;
    createdAt: string;
    updatedAt: string;
};

