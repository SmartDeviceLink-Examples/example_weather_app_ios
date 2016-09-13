//  SDLGetVehicleData.m
//


#import "SDLGetVehicleData.h"

#import "SDLNames.h"

@implementation SDLGetVehicleData

- (instancetype)init {
    if (self = [super initWithName:NAMES_GetVehicleData]) {
    }
    return self;
}

- (instancetype)initWithDictionary:(NSMutableDictionary *)dict {
    if (self = [super initWithDictionary:dict]) {
    }
    return self;
}

- (void)setGps:(NSNumber *)gps {
    if (gps != nil) {
        [parameters setObject:gps forKey:NAMES_gps];
    } else {
        [parameters removeObjectForKey:NAMES_gps];
    }
}

- (NSNumber *)gps {
    return [parameters objectForKey:NAMES_gps];
}

- (void)setSpeed:(NSNumber *)speed {
    if (speed != nil) {
        [parameters setObject:speed forKey:NAMES_speed];
    } else {
        [parameters removeObjectForKey:NAMES_speed];
    }
}

- (NSNumber *)speed {
    return [parameters objectForKey:NAMES_speed];
}

- (void)setRpm:(NSNumber *)rpm {
    if (rpm != nil) {
        [parameters setObject:rpm forKey:NAMES_rpm];
    } else {
        [parameters removeObjectForKey:NAMES_rpm];
    }
}

- (NSNumber *)rpm {
    return [parameters objectForKey:NAMES_rpm];
}

- (void)setFuelLevel:(NSNumber *)fuelLevel {
    if (fuelLevel != nil) {
        [parameters setObject:fuelLevel forKey:NAMES_fuelLevel];
    } else {
        [parameters removeObjectForKey:NAMES_fuelLevel];
    }
}

- (NSNumber *)fuelLevel {
    return [parameters objectForKey:NAMES_fuelLevel];
}

- (void)setFuelLevel_State:(NSNumber *)fuelLevel_State {
    if (fuelLevel_State != nil) {
        [parameters setObject:fuelLevel_State forKey:NAMES_fuelLevel_State];
    } else {
        [parameters removeObjectForKey:NAMES_fuelLevel_State];
    }
}

- (NSNumber *)fuelLevel_State {
    return [parameters objectForKey:NAMES_fuelLevel_State];
}

- (void)setInstantFuelConsumption:(NSNumber *)instantFuelConsumption {
    if (instantFuelConsumption != nil) {
        [parameters setObject:instantFuelConsumption forKey:NAMES_instantFuelConsumption];
    } else {
        [parameters removeObjectForKey:NAMES_instantFuelConsumption];
    }
}

- (NSNumber *)instantFuelConsumption {
    return [parameters objectForKey:NAMES_instantFuelConsumption];
}

- (void)setExternalTemperature:(NSNumber *)externalTemperature {
    if (externalTemperature != nil) {
        [parameters setObject:externalTemperature forKey:NAMES_externalTemperature];
    } else {
        [parameters removeObjectForKey:NAMES_externalTemperature];
    }
}

- (NSNumber *)externalTemperature {
    return [parameters objectForKey:NAMES_externalTemperature];
}

- (void)setVin:(NSNumber *)vin {
    if (vin != nil) {
        [parameters setObject:vin forKey:NAMES_vin];
    } else {
        [parameters removeObjectForKey:NAMES_vin];
    }
}

- (NSNumber *)vin {
    return [parameters objectForKey:NAMES_vin];
}

- (void)setPrndl:(NSNumber *)prndl {
    if (prndl != nil) {
        [parameters setObject:prndl forKey:NAMES_prndl];
    } else {
        [parameters removeObjectForKey:NAMES_prndl];
    }
}

- (NSNumber *)prndl {
    return [parameters objectForKey:NAMES_prndl];
}

- (void)setTirePressure:(NSNumber *)tirePressure {
    if (tirePressure != nil) {
        [parameters setObject:tirePressure forKey:NAMES_tirePressure];
    } else {
        [parameters removeObjectForKey:NAMES_tirePressure];
    }
}

- (NSNumber *)tirePressure {
    return [parameters objectForKey:NAMES_tirePressure];
}

- (void)setOdometer:(NSNumber *)odometer {
    if (odometer != nil) {
        [parameters setObject:odometer forKey:NAMES_odometer];
    } else {
        [parameters removeObjectForKey:NAMES_odometer];
    }
}

- (NSNumber *)odometer {
    return [parameters objectForKey:NAMES_odometer];
}

- (void)setBeltStatus:(NSNumber *)beltStatus {
    if (beltStatus != nil) {
        [parameters setObject:beltStatus forKey:NAMES_beltStatus];
    } else {
        [parameters removeObjectForKey:NAMES_beltStatus];
    }
}

- (NSNumber *)beltStatus {
    return [parameters objectForKey:NAMES_beltStatus];
}

- (void)setBodyInformation:(NSNumber *)bodyInformation {
    if (bodyInformation != nil) {
        [parameters setObject:bodyInformation forKey:NAMES_bodyInformation];
    } else {
        [parameters removeObjectForKey:NAMES_bodyInformation];
    }
}

- (NSNumber *)bodyInformation {
    return [parameters objectForKey:NAMES_bodyInformation];
}

- (void)setDeviceStatus:(NSNumber *)deviceStatus {
    if (deviceStatus != nil) {
        [parameters setObject:deviceStatus forKey:NAMES_deviceStatus];
    } else {
        [parameters removeObjectForKey:NAMES_deviceStatus];
    }
}

- (NSNumber *)deviceStatus {
    return [parameters objectForKey:NAMES_deviceStatus];
}

- (void)setDriverBraking:(NSNumber *)driverBraking {
    if (driverBraking != nil) {
        [parameters setObject:driverBraking forKey:NAMES_driverBraking];
    } else {
        [parameters removeObjectForKey:NAMES_driverBraking];
    }
}

- (NSNumber *)driverBraking {
    return [parameters objectForKey:NAMES_driverBraking];
}

- (void)setWiperStatus:(NSNumber *)wiperStatus {
    if (wiperStatus != nil) {
        [parameters setObject:wiperStatus forKey:NAMES_wiperStatus];
    } else {
        [parameters removeObjectForKey:NAMES_wiperStatus];
    }
}

- (NSNumber *)wiperStatus {
    return [parameters objectForKey:NAMES_wiperStatus];
}

- (void)setHeadLampStatus:(NSNumber *)headLampStatus {
    if (headLampStatus != nil) {
        [parameters setObject:headLampStatus forKey:NAMES_headLampStatus];
    } else {
        [parameters removeObjectForKey:NAMES_headLampStatus];
    }
}

- (NSNumber *)headLampStatus {
    return [parameters objectForKey:NAMES_headLampStatus];
}

- (void)setEngineTorque:(NSNumber *)engineTorque {
    if (engineTorque != nil) {
        [parameters setObject:engineTorque forKey:NAMES_engineTorque];
    } else {
        [parameters removeObjectForKey:NAMES_engineTorque];
    }
}

- (NSNumber *)engineTorque {
    return [parameters objectForKey:NAMES_engineTorque];
}

- (void)setAccPedalPosition:(NSNumber *)accPedalPosition {
    if (accPedalPosition != nil) {
        [parameters setObject:accPedalPosition forKey:NAMES_accPedalPosition];
    } else {
        [parameters removeObjectForKey:NAMES_accPedalPosition];
    }
}

- (NSNumber *)accPedalPosition {
    return [parameters objectForKey:NAMES_accPedalPosition];
}

- (void)setSteeringWheelAngle:(NSNumber *)steeringWheelAngle {
    if (steeringWheelAngle != nil) {
        [parameters setObject:steeringWheelAngle forKey:NAMES_steeringWheelAngle];
    } else {
        [parameters removeObjectForKey:NAMES_steeringWheelAngle];
    }
}

- (NSNumber *)steeringWheelAngle {
    return [parameters objectForKey:NAMES_steeringWheelAngle];
}

- (void)setECallInfo:(NSNumber *)eCallInfo {
    if (eCallInfo != nil) {
        [parameters setObject:eCallInfo forKey:NAMES_eCallInfo];
    } else {
        [parameters removeObjectForKey:NAMES_eCallInfo];
    }
}

- (NSNumber *)eCallInfo {
    return [parameters objectForKey:NAMES_eCallInfo];
}

- (void)setAirbagStatus:(NSNumber *)airbagStatus {
    if (airbagStatus != nil) {
        [parameters setObject:airbagStatus forKey:NAMES_airbagStatus];
    } else {
        [parameters removeObjectForKey:NAMES_airbagStatus];
    }
}

- (NSNumber *)airbagStatus {
    return [parameters objectForKey:NAMES_airbagStatus];
}

- (void)setEmergencyEvent:(NSNumber *)emergencyEvent {
    if (emergencyEvent != nil) {
        [parameters setObject:emergencyEvent forKey:NAMES_emergencyEvent];
    } else {
        [parameters removeObjectForKey:NAMES_emergencyEvent];
    }
}

- (NSNumber *)emergencyEvent {
    return [parameters objectForKey:NAMES_emergencyEvent];
}

- (void)setClusterModeStatus:(NSNumber *)clusterModeStatus {
    if (clusterModeStatus != nil) {
        [parameters setObject:clusterModeStatus forKey:NAMES_clusterModeStatus];
    } else {
        [parameters removeObjectForKey:NAMES_clusterModeStatus];
    }
}

- (NSNumber *)clusterModeStatus {
    return [parameters objectForKey:NAMES_clusterModeStatus];
}

- (void)setMyKey:(NSNumber *)myKey {
    if (myKey != nil) {
        [parameters setObject:myKey forKey:NAMES_myKey];
    } else {
        [parameters removeObjectForKey:NAMES_myKey];
    }
}

- (NSNumber *)myKey {
    return [parameters objectForKey:NAMES_myKey];
}

@end
