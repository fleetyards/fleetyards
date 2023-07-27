/* generated using openapi-typescript-codegen -- do no edit */
/* istanbul ignore file */
/* tslint:disable */
/* eslint-disable */

import type { MediaImage } from './MediaImage';
import type { ShopCommodity } from './ShopCommodity';
import type { ViewImage } from './ViewImage';

export type ModelPaintMinimal = {
    id: string;
    name: string | null;
    slug: string | null;
    availability: {
        boughtAt: Array<ShopCommodity>;
        soldAt: Array<ShopCommodity>;
    };
    description?: string | null;
    lastUpdatedAt?: string | null;
    lastUpdatedAtLabel?: string | null;
    media: {
        angledView?: ViewImage;
        fleetchartImage?: string | null;
        sideView?: ViewImage;
        storeImage?: MediaImage;
        topView?: ViewImage;
    };
    nameWithModel?: string | null;
    rsiId?: number | null;
    rsiName?: string | null;
    rsiSlug?: string | null;
    createdAt: string;
    updatedAt: string;
};

