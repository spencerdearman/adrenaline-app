//
//  MapView.swift
//  Adrenaline
//
//  Created by Spencer Dearman on 12/30/23.
//

import SwiftUI
import MapKit

class MapViewModel: ObservableObject {
    @Published var region: MKCoordinateRegion

    init() {
        // Initialize with a default location
        region = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 0, longitude: 0), span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05))
    }

    func findLocation(location: String) {
        let geocoder = CLGeocoder()
        geocoder.geocodeAddressString(location) { [weak self] (placemarks, error) in
            guard let self = self, let placemark = placemarks?.first, let location = placemark.location else { return }
            self.region = MKCoordinateRegion(center: location.coordinate, span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005))
        }
    }
}

struct MapView: View {
    @StateObject private var viewModel = MapViewModel()
    let locationString: String

    init(locationString: String) {
        self.locationString = locationString
        _viewModel = StateObject(wrappedValue: MapViewModel())
    }

    var body: some View {
        Map(coordinateRegion: $viewModel.region)
            .onAppear {
                viewModel.findLocation(location: locationString)
            }
    }
}
