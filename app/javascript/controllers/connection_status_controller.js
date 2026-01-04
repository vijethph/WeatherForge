import { Controller } from "@hotwired/stimulus";

// Connection status indicator for Turbo Streams (ActionCable WebSocket)
export default class extends Controller {
  static targets = ["status", "icon"];

  connect() {
    this.setupConnectionListeners();
    this.updateConnectionStatus();
  }

  setupConnectionListeners() {
    // Listen for Turbo Stream connection events
    document.addEventListener(
      "turbo:before-stream-render",
      this.handleStreamRender.bind(this)
    );

    // Listen for cable connection events
    if (window.cable) {
      window.cable.subscriptions.consumer.connection.monitor.addEventListener(
        "connected",
        this.handleConnected.bind(this)
      );
      window.cable.subscriptions.consumer.connection.monitor.addEventListener(
        "disconnected",
        this.handleDisconnected.bind(this)
      );
    }

    // Periodically check connection status
    this.checkInterval = setInterval(() => {
      this.updateConnectionStatus();
    }, 5000);
  }

  disconnect() {
    if (this.checkInterval) {
      clearInterval(this.checkInterval);
    }
  }

  handleStreamRender(event) {
    // Update status when streams are received
    this.showConnected();
  }

  handleConnected() {
    console.log("WebSocket connected");
    this.showConnected();
  }

  handleDisconnected() {
    console.log("WebSocket disconnected");
    this.showDisconnected();
  }

  updateConnectionStatus() {
    // Check if ActionCable is connected
    if (this.isConnected()) {
      this.showConnected();
    } else {
      this.showDisconnected();
    }
  }

  isConnected() {
    // Check if ActionCable consumer is connected
    if (window.cable?.subscriptions?.consumer) {
      return window.cable.subscriptions.consumer.connection.isActive();
    }

    // Fallback: check if Turbo is connected (less reliable)
    return (
      document.documentElement.hasAttribute("data-turbo-preview") === false
    );
  }

  showConnected() {
    if (this.hasStatusTarget) {
      this.statusTarget.textContent = "Live";
      this.statusTarget.classList.remove("bg-danger", "bg-warning");
      this.statusTarget.classList.add("bg-success");
    }

    if (this.hasIconTarget) {
      this.iconTarget.classList.remove("bi-wifi-off", "bi-wifi-1");
      this.iconTarget.classList.add("bi-wifi");
    }

    // Update title attribute
    if (this.element) {
      this.element.title = "Real-time updates active";
    }
  }

  showDisconnected() {
    if (this.hasStatusTarget) {
      this.statusTarget.textContent = "Offline";
      this.statusTarget.classList.remove("bg-success", "bg-warning");
      this.statusTarget.classList.add("bg-danger");
    }

    if (this.hasIconTarget) {
      this.iconTarget.classList.remove("bi-wifi", "bi-wifi-1");
      this.iconTarget.classList.add("bi-wifi-off");
    }

    // Update title attribute
    if (this.element) {
      this.element.title = "Real-time updates disconnected";
    }
  }

  showConnecting() {
    if (this.hasStatusTarget) {
      this.statusTarget.textContent = "Connecting...";
      this.statusTarget.classList.remove("bg-success", "bg-danger");
      this.statusTarget.classList.add("bg-warning");
    }

    if (this.hasIconTarget) {
      this.iconTarget.classList.remove("bi-wifi", "bi-wifi-off");
      this.iconTarget.classList.add("bi-wifi-1");
    }

    // Update title attribute
    if (this.element) {
      this.element.title = "Connecting to real-time updates...";
    }
  }
}
