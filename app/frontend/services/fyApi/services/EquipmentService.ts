/* generated using openapi-typescript-codegen -- do no edit */
/* istanbul ignore file */
/* tslint:disable */
/* eslint-disable */
import type { EquipmentMinimal } from '../models/EquipmentMinimal';

import type { CancelablePromise } from '../core/CancelablePromise';
import type { BaseHttpRequest } from '../core/BaseHttpRequest';

export class EquipmentService {

    constructor(public readonly httpRequest: BaseHttpRequest) {}

    /**
     * list equipment
     * Get a List of Equipment
     * @returns EquipmentMinimal successful
     * @throws ApiError
     */
    public getEquipment(): CancelablePromise<Array<EquipmentMinimal>> {
        return this.httpRequest.request({
            method: 'GET',
            url: '/equipment',
        });
    }

}
