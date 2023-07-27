/* generated using openapi-typescript-codegen -- do no edit */
/* istanbul ignore file */
/* tslint:disable */
/* eslint-disable */

import type { Manufacturer } from './Manufacturer';
import type { MediaImage } from './MediaImage';
import type { ShopCommodity } from './ShopCommodity';

export type ModelModuleMinimal = {
    id: string;
    name: string | null;
    availability: {
        boughtAt: Array<ShopCommodity>;
        soldAt: Array<ShopCommodity>;
    };
    description?: string | null;
    media: {
        storeImage?: MediaImage;
    };
    pledgePrice?: number | null;
    productionStatus?: string | null;
    manufacturer?: Manufacturer;
    createdAt: string;
    updatedAt: string;
};

