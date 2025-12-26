// Entry point for the build script in your package.json
import "@hotwired/turbo-rails";
import "./controllers";
import "chartkick/chart.js";
import "chartjs-adapter-date-fns";

// Re-initialize Bootstrap dropdowns after Turbo navigation
document.addEventListener("turbo:load", () => {
  // Initialize all dropdowns
  const dropdownElementList = document.querySelectorAll(
    '[data-bs-toggle="dropdown"]'
  );
  const dropdownList = [...dropdownElementList].map((dropdownToggleEl) => {
    return new bootstrap.Dropdown(dropdownToggleEl);
  });

  console.log("Bootstrap dropdowns initialized:", dropdownList.length);
});

// Ensure Chartkick redraws charts after Turbo navigation
document.addEventListener("turbo:load", () => {
  if (window.Chartkick) {
    window.Chartkick.eachChart((chart) => {
      chart.redraw();
    });
  }
});
