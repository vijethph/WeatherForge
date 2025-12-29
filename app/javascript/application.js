// Entry point for the build script in your package.json
import "@hotwired/turbo-rails";
import "./controllers";
import "chartkick/chart.js";
import "chartjs-adapter-date-fns";

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

// Clean up Bootstrap dropdown instances before caching
function cleanupDropdowns() {
  const dropdownElements = document.querySelectorAll(
    '[data-bs-toggle="dropdown"]'
  );
  dropdownElements.forEach((element) => {
    const instance = bootstrap.Dropdown.getInstance(element);
    if (instance) {
      instance.dispose();
    }
  });
}

// Run on Turbo load (after navigation)
document.addEventListener("turbo:load", () => {
  initializeCharts();
});

// Run on initial page load
document.addEventListener("DOMContentLoaded", () => {
  initializeCharts();
});

// Clean up before Turbo caches the page
document.addEventListener("turbo:before-cache", () => {
  cleanupDropdowns();
});
