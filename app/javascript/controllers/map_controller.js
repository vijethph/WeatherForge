import { Controller } from "@hotwired/stimulus";

console.log("Map controller file loaded");

// Connects to data-controller="map"
export default class extends Controller {
  static values = {
    sensors: Array,
    center: Array,
    zoom: Number,
    hideViewDetails: { type: Boolean, default: false }, // Add option to hide View Details button
  };

  static targets = ["container"];

  connect() {
    console.log("Map controller connected!");
    console.log("Sensors value:", this.sensorsValue);
    console.log("Center value:", this.centerValue);
    console.log("Container target:", this.containerTarget);
    // Wait for Leaflet to be available from CDN
    this.waitForLeaflet();
  }

  waitForLeaflet() {
    if (typeof L !== "undefined") {
      this.initializeLeaflet();
    } else {
      // Retry after 100ms if Leaflet isn't loaded yet
      setTimeout(() => this.waitForLeaflet(), 100);
    }
  }

  initializeLeaflet() {
    // Fix Leaflet's default icon paths
    delete L.Icon.Default.prototype._getIconUrl;
    L.Icon.Default.mergeOptions({
      iconRetinaUrl:
        "https://cdnjs.cloudflare.com/ajax/libs/leaflet/1.9.4/images/marker-icon-2x.png",
      iconUrl:
        "https://cdnjs.cloudflare.com/ajax/libs/leaflet/1.9.4/images/marker-icon.png",
      shadowUrl:
        "https://cdnjs.cloudflare.com/ajax/libs/leaflet/1.9.4/images/marker-shadow.png",
    });

    this.initializeMap();
    this.addSensorMarkers();
  }

  disconnect() {
    if (this.map) {
      this.map.remove();
      this.map = null;
    }
  }

  initializeMap() {
    try {
      // Default center (San Francisco if not provided)
      const center = this.hasCenterValue
        ? this.centerValue
        : [37.7749, -122.4194];
      const zoom = this.hasZoomValue ? this.zoomValue : 10;

      console.log("Initializing map with center:", center, "zoom:", zoom);
      console.log("Container target:", this.containerTarget);

      // Initialize Leaflet map
      this.map = L.map(this.containerTarget).setView(center, zoom);

      // Add OpenStreetMap tile layer
      L.tileLayer("https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png", {
        attribution:
          '&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors',
        maxZoom: 19,
      }).addTo(this.map);

      // Store marker layer group
      this.markerLayer = L.layerGroup().addTo(this.map);

      // Force map to invalidate size after a short delay
      setTimeout(() => {
        if (this.map) {
          this.map.invalidateSize();
        }
      }, 100);

      console.log("Map initialized successfully");
    } catch (error) {
      console.error("Error initializing map:", error);
    }
  }

  addSensorMarkers() {
    if (!this.hasSensorsValue || this.sensorsValue.length === 0) {
      return;
    }

    const bounds = [];

    this.sensorsValue.forEach((sensor) => {
      if (!sensor.latitude || !sensor.longitude) return;

      const marker = this.createMarker(sensor);
      marker.addTo(this.markerLayer);

      bounds.push([sensor.latitude, sensor.longitude]);
    });

    // Fit map to show all markers
    if (bounds.length > 0) {
      this.map.fitBounds(bounds, { padding: [50, 50] });
    }
  }

  createMarker(sensor) {
    const icon = this.getMarkerIcon(sensor);
    const marker = L.marker([sensor.latitude, sensor.longitude], { icon });

    // Create popup content
    const popupContent = this.createPopupContent(sensor);
    marker.bindPopup(popupContent);

    // Add click event
    marker.on("click", () => {
      this.onMarkerClick(sensor);
    });

    return marker;
  }

  getMarkerIcon(sensor) {
    // Color based on sensor type and status
    let color = "#0066CC"; // default blue

    if (sensor.status === "inactive") {
      color = "#999999"; // gray
    } else {
      switch (sensor.sensor_type) {
        case "air_quality":
          color = "#FF6600"; // orange
          break;
        case "temperature":
          color = "#CC0000"; // red
          break;
        case "humidity":
          color = "#0099CC"; // light blue
          break;
        case "water_quality":
          color = "#00CC66"; // green
          break;
      }
    }

    // Create custom icon
    const iconHtml = `
      <div style="
        background-color: ${color};
        width: 24px;
        height: 24px;
        border-radius: 50%;
        border: 2px solid white;
        box-shadow: 0 2px 4px rgba(0,0,0,0.3);
      "></div>
    `;

    return L.divIcon({
      html: iconHtml,
      className: "sensor-marker",
      iconSize: [24, 24],
      iconAnchor: [12, 12],
      popupAnchor: [0, -12],
    });
  }

  createPopupContent(sensor) {
    const latestReading = sensor.latest_reading || {};
    const value = latestReading.value || "N/A";
    const unit = latestReading.unit || "";

    // Check if we should hide the View Details button (e.g., when already on detail page)
    const showButton = !this.hideViewDetailsValue;

    return `
      <div class="sensor-popup" style="min-width: 200px;">
        <h6 class="mb-2">${this.escapeHtml(sensor.name)}</h6>
        <p class="mb-1" style="font-size: 0.95rem;">
          <strong>Type:</strong> ${this.formatSensorType(sensor.sensor_type)}
        </p>
        <p class="mb-1" style="font-size: 0.95rem;">
          <strong>Status:</strong>
          <span class="badge bg-${
            sensor.status === "active" ? "success" : "secondary"
          }">
            ${sensor.status}
          </span>
        </p>
        ${
          value !== "N/A"
            ? `
          <p class="mb-1" style="font-size: 0.95rem;">
            <strong>Latest Reading:</strong> ${value} ${unit}
          </p>
        `
            : ""
        }
        ${
          showButton
            ? `
        <a href="/environmental_sensors/${sensor.id}" class="btn btn-sm btn-light border mt-2" style="color: #0d6efd; font-weight: 500;">
          <i class="bi bi-eye"></i> View Details
        </a>
        `
            : ""
        }
      </div>
    `;
  }

  formatSensorType(type) {
    return type
      .split("_")
      .map((word) => word.charAt(0).toUpperCase() + word.slice(1))
      .join(" ");
  }

  escapeHtml(text) {
    const div = document.createElement("div");
    div.textContent = text;
    return div.innerHTML;
  }

  onMarkerClick(sensor) {
    // Emit custom event for other controllers
    const event = new CustomEvent("sensor-marker-clicked", {
      detail: { sensor },
      bubbles: true,
    });
    this.element.dispatchEvent(event);
  }

  // Method to update markers dynamically (for Turbo Stream updates)
  updateMarkers(sensors) {
    this.sensorsValue = sensors;
    this.markerLayer.clearLayers();
    this.addSensorMarkers();
  }

  // Method to add a single sensor marker
  addSensor(sensor) {
    const marker = this.createMarker(sensor);
    marker.addTo(this.markerLayer);
  }

  // Method to center map on specific coordinates
  centerOn(lat, lon, zoom = 13) {
    this.map.setView([lat, lon], zoom);
  }
}
