import { Application } from "@hotwired/stimulus"

const application = Application.start()

// Configure Stimulus development experience
application.debug = false
window.Stimulus   = application

console.log("Stimulus application started")
console.log("Available controllers:", application.controllers)

export { application }
