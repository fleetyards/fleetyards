/* generated using openapi-typescript-codegen -- do no edit */
/* istanbul ignore file */
/* tslint:disable */
/* eslint-disable */

import type { BoughtViaEnum } from './BoughtViaEnum';
import type { HangarGroup } from './HangarGroup';
import type { Model } from './Model';
import type { ModelModulePackage } from './ModelModulePackage';
import type { ModelPaint } from './ModelPaint';
import type { ModelUpgrade } from './ModelUpgrade';

export type Vehicle = {
    id: string;
    name?: string;
    slug?: string;
    serial?: string;
    alternativeNames: Array<string>;
    boughtVia: BoughtViaEnum;
    boughtViaLabel?: string;
    flagship: boolean;
    hangarGroupIds: Array<string>;
    hangarGroups: Array<HangarGroup>;
    loaner: boolean;
    model: Model;
    modelModuleIds: Array<string>;
    modelUpgradeIds: Array<string>;
    modulePackage?: ModelModulePackage;
    nameVisible: boolean;
    paint?: ModelPaint;
    public: boolean;
    saleNotify: boolean;
    upgrade?: ModelUpgrade;
    wanted: boolean;
    createdAt: string;
    updatedAt: string;
};

