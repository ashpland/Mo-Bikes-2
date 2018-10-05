//
//  RxExtensions.swift
//  Mo-Bikes
//
//  Created by Andrew on 2018-10-05.
//  Copyright © 2018 hearthedge. All rights reserved.
//

import RxSwift
import RxCocoa
import MapKit

extension Reactive where Base: MKMarkerAnnotationView {
    var markerTintColor: Binder<UIColor?> {
        return Binder(self.base) { marker, color in
            marker.markerTintColor = color
        }
    }

    var glyphText: Binder<String?> {
        return Binder(self.base) { marker, text in
            marker.glyphText = text
        }
    }

    var glyphImage: Binder<UIImage?> {
        return Binder(self.base) { marker, image in
            marker.glyphImage = image
        }
    }
}

extension Reactive where Base: MKMapView {
    var addAnnotations: Binder<[MKAnnotation]> {
        return Binder(self.base) { mapView, annotations in
            mapView.addAnnotations(annotations)
        }
    }

    var removeAnnotation: Binder<MKAnnotation> {
        return Binder(self.base) { mapView, annotation in
            mapView.removeAnnotation(annotation)
        }
    }
}
