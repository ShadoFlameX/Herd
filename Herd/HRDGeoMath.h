//
//  HRDGeoMath.h
//  Herd
//
//  Created by Bryan Hansen on 1/3/13.
//  Copyright (c) 2013 Bryan Hansen. All rights reserved.
//

#ifndef Herd_HRDGeoMath_h
#define Herd_HRDGeoMath_h

static double const MilesPerMeter = 0.00062137119f;
static double const MetersPerMile = 1609.344f;

static inline double convertMetersToMiles(double meters) {
    return meters * MilesPerMeter;
}

static inline double convertMilesToMeters(double meters) {
    return meters * MetersPerMile;
}

#endif
