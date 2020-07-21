//  SDLGetVehicleDataResponse.m
//


#import "SDLGetVehicleDataResponse.h"

#import "NSMutableDictionary+Store.h"
#import "SDLAirbagStatus.h"
#import "SDLBeltStatus.h"
#import "SDLBodyInformation.h"
#import "SDLClusterModeStatus.h"
#import "SDLDeviceStatus.h"
#import "SDLECallInfo.h"
#import "SDLEmergencyEvent.h"
#import "SDLFuelRange.h"
#import "SDLGPSData.h"
#import "SDLHeadLampStatus.h"
#import "SDLMyKey.h"
#import "SDLRPCParameterNames.h"
#import "SDLRPCFunctionNames.h"
#import "SDLTireStatus.h"

NS_ASSUME_NONNULL_BEGIN

@implementation SDLGetVehicleDataResponse

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
- (instancetype)init {
    if (self = [super initWithName:SDLRPCFunctionNameGetVehicleData]) {
    }
    return self;
}
#pragma clang diagnostic pop

- (void)setGps:(nullable SDLGPSData *)gps {
    [self.parameters sdl_setObject:gps forName:SDLRPCParameterNameGPS];
}

- (nullable SDLGPSData *)gps {
    return [self.parameters sdl_objectForName:SDLRPCParameterNameGPS ofClass:SDLGPSData.class error:nil];
}

- (void)setSpeed:(nullable NSNumber<SDLFloat> *)speed {
    [self.parameters sdl_setObject:speed forName:SDLRPCParameterNameSpeed];
}

- (nullable NSNumber<SDLFloat> *)speed {
    return [self.parameters sdl_objectForName:SDLRPCParameterNameSpeed ofClass:NSNumber.class error:nil];
}

- (void)setRpm:(nullable NSNumber<SDLInt> *)rpm {
    [self.parameters sdl_setObject:rpm forName:SDLRPCParameterNameRPM];
}

- (nullable NSNumber<SDLInt> *)rpm {
    return [self.parameters sdl_objectForName:SDLRPCParameterNameRPM ofClass:NSNumber.class error:nil];
}

- (void)setFuelLevel:(nullable NSNumber<SDLFloat> *)fuelLevel {
    [self.parameters sdl_setObject:fuelLevel forName:SDLRPCParameterNameFuelLevel];
}

- (nullable NSNumber<SDLFloat> *)fuelLevel {
    return [self.parameters sdl_objectForName:SDLRPCParameterNameFuelLevel ofClass:NSNumber.class error:nil];
}

- (void)setFuelLevel_State:(nullable SDLComponentVolumeStatus)fuelLevel_State {
    [self.parameters sdl_setObject:fuelLevel_State forName:SDLRPCParameterNameFuelLevelState];
}

- (nullable SDLComponentVolumeStatus)fuelLevel_State {
    return [self.parameters sdl_enumForName:SDLRPCParameterNameFuelLevelState error:nil];
}

- (void)setInstantFuelConsumption:(nullable NSNumber<SDLFloat> *)instantFuelConsumption {
    [self.parameters sdl_setObject:instantFuelConsumption forName:SDLRPCParameterNameInstantFuelConsumption];
}

- (void)setFuelRange:(nullable NSArray<SDLFuelRange *> *)fuelRange {
    [self.parameters sdl_setObject:fuelRange forName:SDLRPCParameterNameFuelRange];
}

- (nullable NSArray<SDLFuelRange *> *)fuelRange {
    return [self.parameters sdl_objectsForName:SDLRPCParameterNameFuelRange ofClass:SDLFuelRange.class error:nil];
}

- (nullable NSNumber<SDLFloat> *)instantFuelConsumption {
    return [self.parameters sdl_objectForName:SDLRPCParameterNameInstantFuelConsumption ofClass:NSNumber.class error:nil];
}

- (void)setExternalTemperature:(nullable NSNumber<SDLFloat> *)externalTemperature {
    [self.parameters sdl_setObject:externalTemperature forName:SDLRPCParameterNameExternalTemperature];
}

- (nullable NSNumber<SDLFloat> *)externalTemperature {
    return [self.parameters sdl_objectForName:SDLRPCParameterNameExternalTemperature ofClass:NSNumber.class error:nil];
}

- (void)setVin:(nullable NSString *)vin {
    [self.parameters sdl_setObject:vin forName:SDLRPCParameterNameVIN];
}

- (nullable NSString *)vin {
    return [self.parameters sdl_objectForName:SDLRPCParameterNameVIN ofClass:NSString.class error:nil];
}

- (void)setPrndl:(nullable SDLPRNDL)prndl {
    [self.parameters sdl_setObject:prndl forName:SDLRPCParameterNamePRNDL];
}

- (nullable SDLPRNDL)prndl {
    return [self.parameters sdl_enumForName:SDLRPCParameterNamePRNDL error:nil];
}

- (void)setTirePressure:(nullable SDLTireStatus *)tirePressure {
    [self.parameters sdl_setObject:tirePressure forName:SDLRPCParameterNameTirePressure];
}

- (nullable SDLTireStatus *)tirePressure {
    return [self.parameters sdl_objectForName:SDLRPCParameterNameTirePressure ofClass:SDLTireStatus.class error:nil];
}

- (void)setOdometer:(nullable NSNumber<SDLInt> *)odometer {
    [self.parameters sdl_setObject:odometer forName:SDLRPCParameterNameOdometer];
}

- (nullable NSNumber<SDLInt> *)odometer {
    return [self.parameters sdl_objectForName:SDLRPCParameterNameOdometer ofClass:NSNumber.class error:nil];
}

- (void)setBeltStatus:(nullable SDLBeltStatus *)beltStatus {
    [self.parameters sdl_setObject:beltStatus forName:SDLRPCParameterNameBeltStatus];
}

- (nullable SDLBeltStatus *)beltStatus {
    return [self.parameters sdl_objectForName:SDLRPCParameterNameBeltStatus ofClass:SDLBeltStatus.class error:nil];
}

- (void)setBodyInformation:(nullable SDLBodyInformation *)bodyInformation {
    [self.parameters sdl_setObject:bodyInformation forName:SDLRPCParameterNameBodyInformation];
}

- (nullable SDLBodyInformation *)bodyInformation {
    return [self.parameters sdl_objectForName:SDLRPCParameterNameBodyInformation ofClass:SDLBodyInformation.class error:nil];
}

- (void)setDeviceStatus:(nullable SDLDeviceStatus *)deviceStatus {
    [self.parameters sdl_setObject:deviceStatus forName:SDLRPCParameterNameDeviceStatus];
}

- (nullable SDLDeviceStatus *)deviceStatus {
    return [self.parameters sdl_objectForName:SDLRPCParameterNameDeviceStatus ofClass:SDLDeviceStatus.class error:nil];
}

- (void)setDriverBraking:(nullable SDLVehicleDataEventStatus)driverBraking {
    [self.parameters sdl_setObject:driverBraking forName:SDLRPCParameterNameDriverBraking];
}

- (nullable SDLVehicleDataEventStatus)driverBraking {
    return [self.parameters sdl_enumForName:SDLRPCParameterNameDriverBraking error:nil];
}

- (void)setWiperStatus:(nullable SDLWiperStatus)wiperStatus {
    [self.parameters sdl_setObject:wiperStatus forName:SDLRPCParameterNameWiperStatus];
}

- (nullable SDLWiperStatus)wiperStatus {
    return [self.parameters sdl_enumForName:SDLRPCParameterNameWiperStatus error:nil];
}

- (void)setHeadLampStatus:(nullable SDLHeadLampStatus *)headLampStatus {
    [self.parameters sdl_setObject:headLampStatus forName:SDLRPCParameterNameHeadLampStatus];
}

- (nullable SDLHeadLampStatus *)headLampStatus {
    return [self.parameters sdl_objectForName:SDLRPCParameterNameHeadLampStatus ofClass:SDLHeadLampStatus.class error:nil];
}

- (void)setEngineOilLife:(nullable NSNumber<SDLFloat> *)engineOilLife {
    [self.parameters sdl_setObject:engineOilLife forName:SDLRPCParameterNameEngineOilLife];
}

- (nullable NSNumber<SDLFloat> *)engineOilLife {
    return [self.parameters sdl_objectForName:SDLRPCParameterNameEngineOilLife ofClass:NSNumber.class error:nil];
}

- (void)setEngineTorque:(nullable NSNumber<SDLFloat> *)engineTorque {
    [self.parameters sdl_setObject:engineTorque forName:SDLRPCParameterNameEngineTorque];
}

- (nullable NSNumber<SDLFloat> *)engineTorque {
    return [self.parameters sdl_objectForName:SDLRPCParameterNameEngineTorque ofClass:NSNumber.class error:nil];
}

- (void)setAccPedalPosition:(nullable NSNumber<SDLFloat> *)accPedalPosition {
    [self.parameters sdl_setObject:accPedalPosition forName:SDLRPCParameterNameAccelerationPedalPosition];
}

- (nullable NSNumber<SDLFloat> *)accPedalPosition {
    return [self.parameters sdl_objectForName:SDLRPCParameterNameAccelerationPedalPosition ofClass:NSNumber.class error:nil];
}

- (void)setSteeringWheelAngle:(nullable NSNumber<SDLFloat> *)steeringWheelAngle {
    [self.parameters sdl_setObject:steeringWheelAngle forName:SDLRPCParameterNameSteeringWheelAngle];
}

- (nullable NSNumber<SDLFloat> *)steeringWheelAngle {
    return [self.parameters sdl_objectForName:SDLRPCParameterNameSteeringWheelAngle ofClass:NSNumber.class error:nil];
}

- (void)setECallInfo:(nullable SDLECallInfo *)eCallInfo {
    [self.parameters sdl_setObject:eCallInfo forName:SDLRPCParameterNameECallInfo];
}

- (nullable SDLECallInfo *)eCallInfo {
    return [self.parameters sdl_objectForName:SDLRPCParameterNameECallInfo ofClass:SDLECallInfo.class error:nil];
}

- (void)setAirbagStatus:(nullable SDLAirbagStatus *)airbagStatus {
    [self.parameters sdl_setObject:airbagStatus forName:SDLRPCParameterNameAirbagStatus];
}

- (nullable SDLAirbagStatus *)airbagStatus {
    return [self.parameters sdl_objectForName:SDLRPCParameterNameAirbagStatus ofClass:SDLAirbagStatus.class error:nil];
}

- (void)setEmergencyEvent:(nullable SDLEmergencyEvent *)emergencyEvent {
    [self.parameters sdl_setObject:emergencyEvent forName:SDLRPCParameterNameEmergencyEvent];
}

- (nullable SDLEmergencyEvent *)emergencyEvent {
    return [self.parameters sdl_objectForName:SDLRPCParameterNameEmergencyEvent ofClass:SDLEmergencyEvent.class error:nil];
}

- (void)setClusterModeStatus:(nullable SDLClusterModeStatus *)clusterModeStatus {
    [self.parameters sdl_setObject:clusterModeStatus forName:SDLRPCParameterNameClusterModeStatus];
}

- (nullable SDLClusterModeStatus *)clusterModeStatus {
    return [self.parameters sdl_objectForName:SDLRPCParameterNameClusterModeStatus ofClass:SDLClusterModeStatus.class error:nil];
}

- (void)setMyKey:(nullable SDLMyKey *)myKey {
    [self.parameters sdl_setObject:myKey forName:SDLRPCParameterNameMyKey];
}

- (nullable SDLMyKey *)myKey {
    return [self.parameters sdl_objectForName:SDLRPCParameterNameMyKey ofClass:SDLMyKey.class error:nil];
}

- (void)setElectronicParkBrakeStatus:(nullable SDLElectronicParkBrakeStatus)electronicParkBrakeStatus {
    [self.parameters sdl_setObject:electronicParkBrakeStatus forName:SDLRPCParameterNameElectronicParkBrakeStatus];
}

- (nullable SDLElectronicParkBrakeStatus)electronicParkBrakeStatus {
    return [self.parameters sdl_enumForName:SDLRPCParameterNameElectronicParkBrakeStatus error:nil];
}

- (void)setTurnSignal:(nullable SDLTurnSignal)turnSignal {
    [self.parameters sdl_setObject:turnSignal forName:SDLRPCParameterNameTurnSignal];
}

- (nullable SDLTurnSignal)turnSignal {
    return [self.parameters sdl_enumForName:SDLRPCParameterNameTurnSignal error:nil];
}

- (void)setCloudAppVehicleID:(nullable NSString *)cloudAppVehicleID {
    [self.parameters sdl_setObject:cloudAppVehicleID forName:SDLRPCParameterNameCloudAppVehicleID];
}

- (nullable NSString *)cloudAppVehicleID {
    return [self.parameters sdl_objectForName:SDLRPCParameterNameCloudAppVehicleID ofClass:NSString.class error:nil];
}

- (void)setOEMCustomVehicleData:(NSString *)vehicleDataName withVehicleDataState:(NSObject *)vehicleDataState {
    [self.parameters sdl_setObject:vehicleDataState forName:vehicleDataName];
}

- (nullable NSObject *)getOEMCustomVehicleData:(NSString *)vehicleDataName {
    return [self.parameters sdl_objectForName:vehicleDataName ofClass:NSObject.class error:nil];
}

@end

NS_ASSUME_NONNULL_END
