# 🚨 MAARG — Golden Hour Emergency Response System

> **"Every second counts. MAARG counts every second."**

MAARG (meaning *"path"* in Hindi) is an AI-powered road accident emergency response app built for India. It transforms every smartphone owner into a capable first responder — guiding first aid, notifying family, coordinating bystanders, and alerting hospitals before the ambulance arrives.

---

## 🌐 Live Demo

**Web App:** [https://maarg-app.vercel.app](https://maarg-app.vercel.app)

> 📱 For full features including Volume SOS and camera — download the Android APK below.

---

## 📱 Download APK

[[⬇️ Download MAARG Android APK](#)](https://drive.google.com/file/d/1Tnik5nIVXIYzb76W5cVtV51W0dtvUX7k/view?usp=drivesdk)

---

## 🎯 The Problem

India records **1,53,972 road accident deaths every year** — that's 422 deaths per day.  
Most victims don't die from the crash. They die from **waiting**.

- Only **5% of bystanders** attempt first aid
- Average ambulance response time: **18–25 minutes**
- **50% of deaths** are preventable with timely first aid
- Most first aid instructions are in **English only**
- Bystanders fear **legal consequences** for helping

---

## 💡 The Solution

MAARG fills the gap **before the ambulance arrives** — the most critical window that determines survival.

---

## ✨ Key Features

| Feature | Description |
|---|---|
| 🔴 **One-Tap Accident Reporting** | Captures GPS, alerts ambulance, starts Golden Hour timer in under 3 seconds |
| ⏱️ **Golden Hour Countdown** | 60-minute countdown visible on every screen during an active emergency |
| 📱 **QR Emergency Profile** | Print and stick on helmet/bike — bystanders scan to get victim's details instantly |
| 🆘 **Volume Button SOS** | Press volume down 3 times → SOS sent to emergency contact with GPS location |
| 🩺 **AI First Aid Triage** | Step-by-step guidance based on victim condition + AI injury photo analysis |
| 🔊 **Multilingual Voice** | Instructions read aloud in Tamil, Hindi, or English automatically |
| 👥 **Bystander Coordination** | Assigns roles: Call Facilitator, Traffic Controller, Victim Assistant |
| 🏥 **Live Hospital Relay** | Alerts nearest hospital ER before ambulance arrives |
| 👨‍👩‍👧 **Family Calm Mode** | WhatsApp message to family with GPS, hospital, and incident ID |
| 📸 **Evidence Auto-Capture** | Auto-generates verified incident report for police/insurance |
| 🗺️ **Accident Heatmap** | Chennai accident hotspot visualization with live incident data |
| 📖 **100% Offline Guide** | CPR, bleeding control, fractures, burns — works with zero internet |
| ⚖️ **Good Samaritan Protection** | Displays legal protection under Good Samaritan Act 2015 |

---

## 🚀 How It Works

```
REPORT ACCIDENT (one tap)
        ↓
WHO ARE YOU? (Victim or Bystander)
        ↓
SCAN VICTIM QR (helmet sticker)
        ↓
FAMILY NOTIFIED (WhatsApp auto-sent)
        ↓
GOLDEN HOUR STARTS (timer begins)
        ↓
FIRST AID GUIDANCE (Tamil/Hindi voice)
        ↓
COORDINATE BYSTANDERS (role assignment)
        ↓
HOSPITAL ALERTED (live relay)
        ↓
EVIDENCE CAPTURED (incident report)
        ↓
AMBULANCE ARRIVES ✅
```

---

## 🆚 MAARG vs Calling 108 Alone

| Without MAARG | With MAARG |
|---|---|
| Bystanders panic, do nothing | Step-by-step first aid guidance |
| Family notified hours later | Family notified in under 2 minutes |
| No first aid before ambulance | Correct first aid immediately |
| Hospital not prepared on arrival | Hospital ER prepared in advance |
| Victim identity unknown | Victim identity via QR scan |
| No evidence captured | Auto-generated verified report |
| English instructions only | Tamil, Hindi, English voice |
| No coordination at scene | Organized role assignment |

> **MAARG does not replace 108. MAARG fills the gap BEFORE 108 arrives.**

---

## 📖 Real Scenario

**6:30 PM — OMR Chennai**

Karthik's bike is hit. He's unconscious. Ravi, a bystander, opens MAARG.

- **6:31 PM** — Ravi scans QR on Karthik's helmet → Profile revealed instantly
- **6:31:50 PM** — WhatsApp sent to Karthik's mother with location and hospital
- **6:32 PM** — Tamil voice guides Ravi through bleeding control
- **6:33 PM** — Two more bystanders join, roles assigned
- **6:34 PM** — Apollo Hospital ER alerted, trauma bay reserved
- **6:38 PM** — Ambulance arrives, Karthik is stable ✅

*From chaos to coordination in 8 minutes.*

---

## 🛠️ Tech Stack

| Technology | Purpose |
|---|---|
| **Flutter / Dart** | Cross-platform mobile app |
| **Riverpod** | State management |
| **Featherless AI API** | AI injury assessment (LLM) |
| **OpenStreetMap Nominatim** | Free reverse geocoding |
| **Flutter Map** | Accident heatmap visualization |
| **Web Speech API** | Tamil/Hindi/English voice synthesis |
| **qr_flutter** | QR code generation |
| **mobile_scanner** | QR code scanning |
| **Geolocator** | Real-time GPS |
| **Android MethodChannel (Kotlin)** | Volume button SOS detection |
| **WhatsApp wa.me API** | Family emergency notifications |
| **sensors_plus** | Accelerometer / motion detection |
| **Vercel** | Web deployment |

---

## 📂 Project Structure

```
MAARG/
├── lib/
│   ├── screens/          # All app screens (16 screens)
│   ├── providers/        # State management (Riverpod)
│   ├── models/           # Data models
│   ├── repositories/     # Data repositories
│   ├── services/         # Business logic services
│   ├── router/           # App navigation
│   └── widgets/          # Reusable widgets
├── android/              # Android native code (Kotlin)
├── assets/               # Images, icons
└── web/                  # Web build configuration
```

---

## 🏃 Run Locally

**Prerequisites:**
- Flutter SDK 3.x
- Android Studio or VS Code
- Android device or emulator

**Steps:**
```bash
# Clone the repository
git clone https://github.com/keerthana-11ke/MAARG.git
cd MAARG

# Install dependencies
flutter pub get

# Run the app (with API key)
flutter run -d chrome \
  --dart-define=GEMINI_API_KEY=your_featherless_key \
  --dart-define=GEMINI_BASE_URL=https://api.featherless.ai/v1

# Build APK
flutter build apk --debug \
  --dart-define=GEMINI_API_KEY=your_featherless_key \
  --dart-define=GEMINI_BASE_URL=https://api.featherless.ai/v1
```

> Get a free API key at [featherless.ai](https://featherless.ai)

---

## 🌍 Social Impact

| Metric | Estimate |
|---|---|
| Lives potentially saved annually | 12,000 – 37,500 |
| Family notification time | Under 2 minutes |
| Works offline | 100% core features |
| Languages supported | English, Tamil, Hindi |
| Legal protection | Good Samaritan Act 2015 |

---

## 🗺️ Future Roadmap

- [ ] Real hospital HL7 FHIR API integration
- [ ] Background SOS service (works with screen locked)
- [ ] Real bystander proximity network
- [ ] Wearable device integration
- [ ] Tamil Nadu 108 ambulance API
- [ ] Pan-India expansion (all 22 languages)

---

## 👩‍💻 Team

Built with ❤️ for the hackathon by **Keerthana**

---

## 📄 License

This project is built for hackathon purposes.

---

<p align="center">
  <strong>MAARG — Because the path to safety should never be blocked.</strong>
</p>
