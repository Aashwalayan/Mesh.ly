# Mesh.ly

> **Decentralized nearby communication through peer-to-peer mesh networking.**

Mesh.ly is a Flutter-based peer-to-peer communication application designed to discover nearby devices, establish direct connections, and exchange messages without relying on a traditional centralized messaging architecture.

The project focuses on building a local communication layer where devices can discover and communicate with one another through nearby wireless connectivity.

---

## Overview

Traditional messaging applications generally follow this architecture:

```text
User A
   ↓
Internet
   ↓
Central Server
   ↓
Internet
   ↓
User B
```

Mesh.ly explores a different approach:

```text
User A
   ↕
Nearby Peer
   ↕
User B
```

Instead of making the server the center of communication, Mesh.ly places the **peer devices** at the center of the communication layer.

The application is designed around four major stages:

```text
Discovery → Connection → Contact → Messaging
```

---

# Features

* Nearby Mesh.ly device discovery
* Peer-to-peer communication architecture
* Automatic connection to discovered peers
* Persistent device identity
* Contact management
* Real-time connection state tracking
* Peer-to-peer messaging
* Separation between physical peers and saved contacts
* Centralized networking management through `MeshRouter`
* Android Nearby/Bluetooth/Wi-Fi based device communication
* Permission-aware networking startup
* Connection failure and rejection handling
* Architecture designed for future multi-hop mesh networking

---

# Architecture

Mesh.ly follows a layered architecture:

```text
┌──────────────────────────────────────┐
│              UI Layer                │
│                                      │
│  Nearby  │  Contacts  │  Chats      │
└──────────────────┬───────────────────┘
                   │
┌──────────────────▼───────────────────┐
│          Application Layer            │
│                                      │
│             MeshRouter               │
│       Contact / Chat Management       │
└──────────────────┬───────────────────┘
                   │
┌──────────────────▼───────────────────┐
│          Networking Layer             │
│                                      │
│ Discovery │ Connections │ Messaging  │
└──────────────────┬───────────────────┘
                   │
┌──────────────────▼───────────────────┐
│          Android / OS Layer           │
│                                      │
│ Bluetooth / Wi-Fi / Nearby APIs      │
└──────────────────────────────────────┘
```

The most important component is the **MeshRouter**.

It acts as the central coordinator for the active mesh networking state.

---

# How It Works

## 1. Application Startup

When Mesh.ly starts, `AppStartupGate` makes sure that a device identity is available.

```text
App Launch
    ↓
AppStartupGate
    ↓
Check / Create Identity
    ↓
Identity Ready
    ↓
Start MeshRouter
```

The networking system is not started until the application has a valid identity.

---

## 2. MeshRouter Initialization

Once the identity is ready, `MeshRouter` becomes responsible for the application's networking lifecycle.

```text
AppStartupGate
       ↓
MeshRouter
       ↓
Networking initialization
       ↓
Discovery
```

The UI does not independently start discovery or create competing networking sessions.

This provides a single source of truth for the mesh network.

---

## 3. Device Discovery

When Nearby functionality is active, Mesh.ly searches for other Mesh.ly devices in the local environment.

At the same time, a Mesh.ly device can advertise its presence.

```text
Device A
   │
   │ Discovery
   ▼
Local Wireless Environment
   ▲
   │ Advertisement
   │
Device B
```

When Device A detects Device B, the discovery service reports the peer to `MeshRouter`.

---

# Discovery vs Contacts

One of the core architectural decisions in Mesh.ly is keeping **physical discovery** separate from **user contacts**.

A device being nearby does not automatically mean that it is a contact.

```text
Nearby Device
     ↓
Physical Peer
     ↓
Connection
     ↓
User chooses to add
     ↓
Contact
```

This allows Mesh.ly to distinguish between:

* Devices that happen to be nearby
* Devices that are currently connected
* People the user has intentionally added

---

# 4. Automatic Peer Connection

After a physical peer is discovered, Mesh.ly can automatically attempt to establish a connection.

```text
Peer Discovered
      ↓
Connection Manager
      ↓
Connection Attempt
      ↓
┌─────┴─────┐
│           │
Success    Failure
│           │
▼           ▼
Connected   Failed
```

The connection state is maintained by the networking layer.

The UI simply observes the resulting state.

---

# 5. Connection States

A peer can move through several networking states:

```text
DISCOVERED
     ↓
CONNECTING
     ↓
CONNECTED
     │
     ├──────→ DISCONNECTED
     │
     └──────→ FAILED / REJECTED
```

Rejected or failed connections are explicitly represented as failures rather than being incorrectly displayed as successful connections.

This is important for accurately representing the real state of the mesh network.

---

# 6. Nearby Screen

The Nearby screen is primarily a view of the networking state.

It does not independently control the discovery engine.

```text
                MeshRouter
                    │
                    ▼
             Networking State
                    │
                    ▼
                Nearby UI
```

This architecture prevents individual screens from creating duplicate discovery services or conflicting connection states.

---

# 7. Adding Contacts

When a user decides to add a nearby peer:

```text
Nearby Peer
     ↓
Add Contact
     ↓
Contact Created
     ↓
Contact List
```

The contact system operates independently from the physical discovery system.

A contact can therefore be treated as a persistent user-level relationship rather than simply a temporary nearby device.

---

# 8. Messaging

Once a peer connection exists, users can communicate through the chat interface.

The messaging flow is:

```text
User
 ↓
Chat Screen
 ↓
Message
 ↓
MeshRouter
 ↓
Active Peer Connection
 ↓
Remote Device
 ↓
Message Handler
 ↓
Remote Chat Screen
```

The chat UI does not directly interact with low-level networking APIs.

Instead, it communicates with the networking layer through the application's routing architecture.

---

# End-to-End Flow

The complete flow can be represented as:

```text
                 Mesh.ly Launch
                       │
                       ▼
                AppStartupGate
                       │
                       ▼
                 Device Identity
                       │
                       ▼
                  MeshRouter
                       │
                       ▼
                  Discovery
                       │
                       ▼
                Nearby Peer
                       │
                       ▼
              Automatic Connection
                       │
              ┌────────┴────────┐
              ▼                 ▼
          Connected           Failed
              │
              ▼
          Nearby UI
              │
              ▼
        Add as Contact
              │
              ▼
         Contact List
              │
              ▼
           Open Chat
              │
              ▼
        Send Message
              │
              ▼
          MeshRouter
              │
              ▼
       Peer Connection
              │
              ▼
        Remote Device
              │
              ▼
       Receive Message
```

---

# Core Components

## AppStartupGate

Responsible for controlling application startup and ensuring that the required identity exists before networking begins.

---

## MeshRouter

The central networking coordinator.

Responsibilities include:

* Starting networking
* Managing discovery
* Tracking peers
* Managing connections
* Exposing networking state
* Routing messages
* Coordinating communication between the UI and networking layer

---

## Discovery Service

Responsible for finding nearby Mesh.ly devices and detecting when peers enter or leave the local environment.

---

## Connection Manager

Responsible for establishing and maintaining communication channels with discovered peers.

It also tracks connection states such as:

* Connecting
* Connected
* Disconnected
* Failed
* Rejected

---

## Contacts

Represents users/devices that the user has intentionally added.

Contacts are separate from temporary physical peer discovery.

---

## Chat

Provides the user interface for exchanging messages with connected peers.

The chat layer delegates actual communication to `MeshRouter`.

---

# Permission Architecture

Because Mesh.ly communicates with nearby devices, Android requires appropriate runtime permissions.

The application handles permissions before attempting to start the nearby networking functionality.

Depending on Android version and the underlying communication mechanism, this can involve permissions related to:

* Nearby devices
* Bluetooth
* Wi-Fi / nearby Wi-Fi devices
* Location where required by the Android version/API

The permission layer is separated from the networking layer so that permission handling does not become mixed with peer discovery logic.

---

# Android Networking

Mesh.ly uses Android's nearby wireless capabilities to facilitate peer discovery and communication.

The networking architecture is designed around the Android device environment while keeping the application-level networking logic independent from the UI.

The application therefore separates:

```text
Flutter
  ↓
Mesh.ly Networking Abstraction
  ↓
Android Networking APIs
  ↓
Physical Wireless Layer
```

This makes it possible to evolve the underlying transport without rewriting the application's UI architecture.

---

# Why MeshRouter?

Without a centralized networking coordinator, individual screens could independently attempt to start networking:

```text
Nearby Screen → Discovery

Contacts Screen → Discovery

Chat Screen → Discovery
```

This could result in:

* Duplicate discovery sessions
* Conflicting connection state
* Duplicate connections
* Difficult lifecycle management
* Increased resource consumption

Mesh.ly instead follows:

```text
                 MeshRouter
              /      |       \
             /       |        \
      Discovery  Connections  Messaging
             \       |        /
              \      |       /
                 Networking
                     │
                     ▼
                    UI
```

This gives the application a single networking authority.

---

# Design Principles

### Single Source of Truth

`MeshRouter` owns the active networking state.

### Separation of Concerns

Discovery, connections, contacts, and messaging have separate responsibilities.

### UI as Observer

The UI observes networking state instead of directly controlling the networking engine.

### Discovery ≠ Contact

A nearby device is not automatically a saved contact.

### Automatic Peer Connectivity

Physical peers can be connected without requiring the user to manually initiate a connection.

### Explicit Connection States

Connection failures and rejections are represented accurately.

### Extensible Architecture

The architecture is designed so that additional mesh capabilities can be added without restructuring the entire application.

---

# Future: Multi-Hop Mesh Networking

The current architecture can be extended toward a true multi-hop mesh network.

For example:

```text
A ───── B ───── C
```

If A cannot directly reach C, B could potentially act as an intermediate relay:

```text
A → B → C
```

With multiple devices:

```text
        B
       / \
      A   C
       \ /
        D
```

The network could eventually support:

* Multi-hop message routing
* Peer relaying
* Route discovery
* Network topology management
* Store-and-forward messaging
* Offline message delivery
* Automatic route recovery

This is the long-term direction of Mesh.ly.

---

# Technology Stack

### Frontend

* Flutter
* Dart
* Material UI

### Platform

* Android
* Android Nearby / Bluetooth / Wi-Fi capabilities

### Architecture

* Layered architecture
* Service-based networking
* Centralized `MeshRouter`
* Reactive UI state

### Communication Model

* Peer-to-peer
* Nearby device discovery
* Direct device communication
* Future multi-hop mesh support

---

# Project Structure

A simplified representation of the project architecture:

```text
lib/
│
├── app/
│   ├── startup/
│   └── theme/
│
├── data/
│
├── models/
│
├── services/
│   ├── discovery/
│   ├── connection/
│   ├── messaging/
│   └── permissions/
│
├── networking/
│   └── mesh_router.dart
│
├── screens/
│   ├── nearby/
│   ├── contacts/
│   └── chat/
│
└── widgets/
```

The exact structure may evolve as the networking layer continues to develop.

---

# Getting Started

## Prerequisites

Install:

* Flutter SDK
* Android Studio
* Android SDK
* Android device running a supported Android version

A physical Android device is recommended because nearby device communication cannot always be accurately tested using an emulator.

---

## Clone the Repository

```bash
git clone https://github.com/Aashwalayan/Mesh.ly.git
cd Mesh.ly
```

---

## Install Dependencies

```bash
flutter pub get
```

---

## Run the Application

Connect an Android device and run:

```bash
flutter run
```

For networking testing, install the application on **at least two physical Android devices**.

---

# Testing Peer Discovery

To test Mesh.ly:

### Device A

1. Install Mesh.ly.
2. Launch the application.
3. Complete identity initialization.
4. Grant the required nearby-device permissions.
5. Open the Nearby section.

### Device B

1. Install Mesh.ly.
2. Launch the application.
3. Complete identity initialization.
4. Grant the required permissions.
5. Open the Nearby section.

The devices should be able to discover one another when the underlying wireless conditions and Android permissions allow it.

Once discovered, Mesh.ly attempts to establish the peer connection.

---

# Debugging

Mesh.ly includes diagnostic logging for the networking layer.

Useful events include:

```text
Discovery started
Peer discovered
Connection requested
Connection established
Connection rejected
Connection failed
Peer disconnected
Message sent
Message received
```

Android logs can be inspected using:

```bash
adb logcat
```

or through Android Studio's **Logcat** window.

---

# Project Status

Mesh.ly is currently under active development.

The current focus is:

* Reliable nearby discovery
* Stable peer connections
* Accurate connection state management
* Contact integration
* Peer-to-peer messaging
* Improving Android permission handling
* Preparing the architecture for multi-hop mesh networking

---

# Roadmap

* [x] Flutter application foundation
* [x] Persistent device identity
* [x] Nearby device discovery architecture
* [x] Centralized MeshRouter
* [x] Automatic peer connection architecture
* [x] Connection state handling
* [x] Contact architecture
* [x] Chat architecture
* [ ] Fully reliable peer-to-peer messaging
* [ ] Message persistence
* [ ] Multi-hop routing
* [ ] Peer relay system
* [ ] Store-and-forward messaging
* [ ] Network topology visualization
* [ ] Improved offline communication
* [ ] Production hardening

---

# Vision

Mesh.ly aims to explore what messaging could look like when **nearby devices themselves become part of the communication infrastructure**.

Instead of thinking of communication as:

```text
Device → Server → Device
```

Mesh.ly works toward:

```text
Device ↔ Device
```

and eventually:

```text
Device ↔ Device ↔ Device ↔ Device
```

creating a communication network built from the devices themselves.

---

## License

This project is currently under development. Licensing information will be added as the project approaches public release.

---

## Author

**Aashwalayan**

GitHub: `Aashwalayan`

---

> **Mesh.ly — Connect nearby. Communicate directly. Build the mesh.**
