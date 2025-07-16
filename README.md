# Kavach – Real-Time Crime Reporting & Citizen Safety Platform

**HackVortex 2025 | Team AutoBots | GovTech**


https://github.com/user-attachments/assets/841a52a2-7e09-4dc8-9fd0-e1edecc14c6c


## Overview

Kavach is a GovTech mobile application designed to revolutionize crime reporting and enhance public safety by empowering citizens to contribute to crime prevention and community security. It complements existing law enforcement systems by providing tools for real-time crime reporting, evidence collection, and situational awareness, all within the legal framework.

## Problem Statement

The current law enforcement infrastructure faces several challenges that delay justice and hinder rapid response:

- **Inefficient FIR Initiation**: Manual processes delay crime reporting.
- **Lack of Real-Time Evidence Capture**: Limited mechanisms for immediate evidence submission.
- **Limited Citizen Engagement Tools**: Insufficient platforms for active citizen participation.
- **Absence of Situational Awareness Mechanisms**: Lack of real-time crime hotspot information.
- **Inadequate Emergency Response Connectivity**: Slow communication with authorities.
- **Underutilization of AI in Citizen Safety**: Missed opportunities for AI-driven safety solutions.

Kavach addresses these issues by digitizing initial reporting stages, enabling faster law enforcement response, and fostering proactive public safety.

## Solution

Kavach empowers citizens with the following features:

- **Instant Crime Reporting**: Report crimes directly through the mobile app, complementing the formal FIR process.
- **Live Evidence Upload**: Capture and upload real-time photo/video evidence during incidents.
- **Real-Time Crime Heatmaps**: View interactive maps showing crime hotspots and nearby threats.
- **Geofencing Alerts**: Receive notifications when entering high-risk areas.
- **SafetyBuddy AI Assistant**: 24/7 chatbot providing safety tips, emergency advice, travel guidance, and crisis navigation.
- **Quick Access to Authorities**: Locate and contact nearby police stations or emergency responders with live location sharing.
- **Emergency SOS**: Send distress signals with precise geolocation to authorities and trusted contacts.
- **Trusted Contacts**: Store and alert personal contacts during emergencies with live location sharing.

By facilitating real-time communication and awareness, Kavach enhances law enforcement efficiency and promotes community safety.

## Core Features

| Feature                     | Description                                                                 |
|-----------------------------|-----------------------------------------------------------------------------|
| **Digital Crime Reporting**  | Submit crime reports instantly via the app without visiting a police station. |
| **Live Crime Broadcasting**  | Record and send real-time photos/videos for immediate evidence collection.   |
| **Real-Time Crime Maps**    | Interactive maps displaying ongoing crime locations, hotspots, and alerts.   |
| **SafetyBuddy AI Assistant** | 24/7 chatbot offering safety tips, emergency advice, and travel guidance.    |
| **Smart Alerts**            | Notifications for users entering or nearing crime-prone areas.               |
| **Quick Access**            | Locate and contact authorities or trusted contacts with live location and SOS alerts. |

## Tech Stack

| Layer         | Technology                           |
|---------------|--------------------------------------|
| **Frontend**  | Flutter (Dart)                       |
| **Backend**   | Node.js, Express.js                  |
| **Database**  | Firebase Realtime Database           |
| **Maps**      | Google Maps API                      |
| **Chatbot**   | OpenRouter API, DialogFlow           |
| **Design**    | Figma (UI)                           |
| **Alerts**    | Firebase Cloud Messaging             |

## Development Methodology

- **Agile Development**: Iterative development with task division for efficient collaboration.
- **MVC Pattern**: Ensures modularity and scalability.
- **Observer & Singleton Patterns**: Facilitates real-time updates and efficient database interactions.

## Prerequisites

To run Kavach locally, ensure you have the following installed:

- Flutter SDK
- Node.js
- npm
- Git
- Firebase CLI (for Firebase setup)
- Google Maps API key
- OpenRouter API key (for chatbot integration)
- DialogFlow setup

## How to Run Locally

1. **Clone the Repository**:
   ```bash
   git clone https://github.com/Angat-Shah/Kavach-HackVortex.git
   cd Kavach-HackVortex
   ```

2. **Set Up Flutter App**:
   ```bash
   flutter pub get
   npm install
   flutter run
   ```

3. **Configure Firebase**:
   - Set up a Firebase project and add the `google-services.json` file to the `android/app` directory for Android or `GoogleService-Info.plist` for iOS.
   - Enable Firebase Realtime Database and Firebase Cloud Messaging in your Firebase console.

4. **Set Up APIs**:
   - Add your Google Maps API key to the app configuration.
   - Configure OpenRouter API and DialogFlow for the chatbot functionality.

## Screenshots

Below are screenshots showcasing key features of the Kavach app:

<div style="display: flex; overflow-x: auto; white-space: nowrap; padding: 10px 0;">
  <img src="/screenshots/splash-screen.PNG" width="150" style="margin-right: 8px;" />
  <img src="/screenshots/onboarding-screen.PNG" width="150" style="margin-right: 8px;" />
  <img src="/screenshots/home-screen.PNG" width="150" style="margin-right: 8px;" />
  <img src="/screenshots/create-account.PNG" width="150" style="margin-right: 8px;" />
  <img src="/screenshots/crime-map.PNG" width="150" style="margin-right: 8px;" />
  <img src="/screenshots/live-stream.PNG" width="150" style="margin-right: 8px;" />
  <img src="/screenshots/safety-buddy-intro.PNG" width="150" style="margin-right: 8px;" />
  <img src="/screenshots/safety-buddy-chat.PNG" width="150" style="margin-right: 8px;" />
  <img src="/screenshots/settings-screen.PNG" width="150" />
</div>

- **Splash Screen**: The initial splash screen displaying the Kavach logo.

- **Onboarding Screen**: Explanation for live crime broadcasting to share real-time incidents with authorities.  

- **Home Screen**: Displays the main dashboard with options for reporting incidents, quick access to emergency contacts, and recent reports.  

- **Create Account Screen**: Interface for signing up or signing in using Apple, Google, email, or phone.  

- **Real-Time Crime Map**: Interactive map showing crime hotspots and incidents across a region.  

- **Live Stream**: Screen for starting a live stream to report incidents with video evidence.  

- **SafetyBuddy Introduction**: Introduction screen for the SafetyBuddy AI chatbot, detailing its features.  

- **SafetyBuddy Chat**: Chat interface for interacting with the SafetyBuddy AI for safety tips and emergency guidance. 

- **Settings Screen**: Interface for managing user settings, including emergency contacts, location sharing, and preferences.  

## Future Enhancements

- Multilingual support for broader accessibility.
- Advanced AI analytics for predictive crime mapping.
- Offline mode for limited connectivity areas.

## Team

**Team AutoBots** – Built for HackVortex 2025

- **Angat Shah**
- **Yash Patel**
- **Gati Shah**

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.

## Contact

For inquiries or contributions, please contact us via [GitHub Issues](https://github.com/Angat-Shah/Kavach-HackVortex/issues).
