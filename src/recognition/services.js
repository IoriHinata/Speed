import {VEHICLE_CATALOG, CAR_COLORS, COLOR_HEX} from '../data/vehicle-catalog.js';
/** Production adapters can replace these ports without touching UI or gameplay. */
export class LicensePlateDetectionService { async detect(){return [];} }
export class ImagePrivacyService { constructor(detector){this.detector=detector;} async sanitize(photo){const plates=await this.detector.detect(photo);return {photo,redactedRegions:plates.map(({x,y,width,height})=>({x,y,width,height})),plateNumberStored:false};} }
export class VehicleRecognitionService { async recognize(){throw new Error('Recognition service is not configured');} }
export class FallbackVehicleRecognitionService extends VehicleRecognitionService { async recognize(){const entry=VEHICLE_CATALOG[Math.floor(Date.now()/1000)%VEHICLE_CATALOG.length];const name=CAR_COLORS[Math.floor(Date.now()/1000)%CAR_COLORS.length];return {...entry,color:name,colorHex:COLOR_HEX[name],confidence:.9};} }
