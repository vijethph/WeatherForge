import { Application } from "@hotwired/stimulus";

const application = Application.start();

// Configure Stimulus development experience
application.debug = true;
window.Stimulus = application;

console.log("Stimulus application started", application);

export { application };
