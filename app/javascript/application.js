// Entry point for the build script in your package.json
import "@hotwired/turbo-rails";
import "./controllers";
import "chartkick/chart.js";
import "chartjs-adapter-date-fns";

// Store dropdown instances globally to manage lifecycle
const dropdownInstances = new Map();

// Initialize Bootstrap dropdowns with proper cleanup
function initializeDropdowns() {
  const dropdownElements = document.querySelectorAll(
    '[data-bs-toggle="dropdown"]'
  );

  dropdownElements.forEach((element) => {
    // Check if we already have an instance for this element
    if (dropdownInstances.has(element)) {
      return;
    }

    // Create new dropdown instance
    const dropdown = new bootstrap.Dropdown(element, {
      autoClose: true,
      boundary: "viewport",
    });

    // Store the instance
    dropdownInstances.set(element, dropdown);
  });

  console.log(`Initialized ${dropdownElements.length} dropdowns`);
}

// Clean up all dropdown instances
function cleanupDropdowns() {
  dropdownInstances.forEach((instance, element) => {
    if (instance) {
      instance.dispose();
    }
  });
  dropdownInstances.clear();
}

// Initialize Chartkick charts
function initializeCharts() {
  if (window.Chartkick) {
    setTimeout(() => {
      window.Chartkick.eachChart((chart) => {
        chart.redraw();
      });
    }, 100);
  }
}

// Run on Turbo load (after navigation)
document.addEventListener("turbo:load", () => {
  initializeDropdowns();
  initializeCharts();
});

// Run on initial page load
document.addEventListener("DOMContentLoaded", () => {
  initializeDropdowns();
  initializeCharts();
});

// Clean up before Turbo caches the page
document.addEventListener("turbo:before-cache", () => {
  cleanupDropdowns();
});

// Clean up before page unload
window.addEventListener("beforeunload", () => {
  cleanupDropdowns();
});

// Clean up before caching
document.addEventListener("turbo:before-cache", () => {
  const dropdownElements = document.querySelectorAll(
    '[data-bs-toggle="dropdown"]'
  );
  dropdownElements.forEach((element) => {
    const instance = bootstrap.Dropdown.getInstance(element);
    if (instance) {
      instance.dispose();
    }
  });
});
