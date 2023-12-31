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
    @Published var locationCoordinate: CLLocationCoordinate2D?

    init() {
        // Initialize with a default location
        region = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 0, longitude: 0), span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05))
    }

    func findLocation(location: String) {
        let geocoder = CLGeocoder()
        geocoder.geocodeAddressString(location) { [weak self] (placemarks, error) in
            guard let self = self, let placemark = placemarks?.first, let locationCoordinate = placemark.location?.coordinate else { return }
            
            // Now set the locationCoordinate and region
            self.locationCoordinate = locationCoordinate
            self.region = MKCoordinateRegion(center: locationCoordinate, span: MKCoordinateSpan(latitudeDelta: 0.002, longitudeDelta: 0.002))
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
    
    private func openInMaps() {
            guard let coordinate = viewModel.locationCoordinate else { return }

            let placemark = MKPlacemark(coordinate: coordinate)
            let mapItem = MKMapItem(placemark: placemark)
            mapItem.name = locationString // Optional: Set the name of the location

            MKMapItem.openMaps(with: [mapItem], launchOptions: nil)
        }

    var body: some View {
        Map(coordinateRegion: $viewModel.region)
            .onAppear {
                viewModel.findLocation(location: locationString)
            }
            .onTapGesture {
                openInMaps()
            }
    }
}
