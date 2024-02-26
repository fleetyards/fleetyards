/* generated using openapi-typescript-codegen -- do no edit */
/* istanbul ignore file */
/* tslint:disable */
/* eslint-disable */

import type { BoughtViaEnum } from './BoughtViaEnum';

export type VehicleUpdateInput = {
    name?: string | null;
    serial?: string | null;
    wanted?: boolean;
    nameVisible?: boolean;
    public?: boolean;
    saleNotify?: boolean;
    flagship?: boolean;
    modelPaintId?: string | null;
    boughtVia?: BoughtViaEnum;
    hangarGroupIds?: Array<string>;
    modelModuleIds?: Array<string>;
    modelUpgradeIds?: Array<string>;
    alternativeNames?: Array<string>;
};

