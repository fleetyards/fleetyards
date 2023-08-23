/* generated using openapi-typescript-codegen -- do no edit */
/* istanbul ignore file */
/* tslint:disable */
/* eslint-disable */

import type { DockShipSizeEnum } from './DockShipSizeEnum';
import type { DockTypeEnum } from './DockTypeEnum';

export type Dock = {
    name: string;
    group?: string;
    size: DockShipSizeEnum;
    sizeLabel: string;
    type: DockTypeEnum;
    typeLabel: string;
};

