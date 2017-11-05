/*
 * A smart AMap location Library for react-native apps
 * https://github.com/react-native-component/react-native-smart-amap-location/
 * Released under the MIT license
 * Copyright (c) 2016 react-native-component <moonsunfall@aliyun.com>
 */

'use strict';

var ReactNative = require('react-native');

var {
    NativeModules,
    DeviceEventEmitter
} = ReactNative;

const AMapLocation = NativeModules.AMapLocation;
const onLocationUpdatingEvent = 'amap.location.onLocationResult'
const onLocationUpdatingEventOnce = 'amap.location.onLocationResult.once'
let listener
module.exports = {
    startUpdatingLocation: (option, callback) => {
        const handler = (body) => {
            callback && callback(body)
        }
        listener = DeviceEventEmitter.addListener(
            onLocationUpdatingEvent,
            handler
        );
        AMapLocation.startUpdatingLocation(option)
    },
    stopUpdatingLocation: () => {
        listener && DeviceEventEmitter.removeListener(listener)
        AMapLocation.stopUpdatingLocatoin()
    },
    getReGeocode: (option, callback) => {
        let cb = callback
        let listener1;
        const handler = (body) => {
            cb && cb(body)
            cb = undefined
            listener1 && DeviceEventEmitter.removeListener(listener1)
        }
        listener1 = DeviceEventEmitter.addListener(
            onLocationUpdatingEventOnce,
            handler
        );
        AMapLocation.getReGeocode(option)
    }
};

