# BhArt

**Zero-Typing Commerce for Bharatiya Artisans**

AI-powered Flutter app that turns a photo and a voice note into a bilingual, fairly-priced marketplace listing for rural Indian artisans — zero typing required.

Built for **Smart India Hackathon 2026**
| | |
|---|---|
| **Problem Statement** | SIH26090 |
| **PS Title** | AI-Driven Market Linkage and Smart Cataloging Mobile Application for Marginalized Artisans |
| **Theme** | Culture & Heritage |
| **Category** | Software |
| **Team** | Axiom8 (Team ID 168001) |

---

## Screenshots

<!-- Add screenshots below — drop image files into docs/screenshots/ and update the paths -->

| Login | Capture & AI Processing | Product Card |
|---|---|---|
| ![Login screen](docs/screenshots/login.png) | ![Capture screen](docs/screenshots/capture.png) | ![Product card](docs/screenshots/product-card.png) |

| Voice Edit | Buyer Marketplace |
|---|---|
| ![Voice edit](docs/screenshots/voice-edit.png) | ![Buyer marketplace](docs/screenshots/marketplace.png) |

<!-- Optional: add a short demo GIF or video link here -->
<!-- ![Demo](docs/screenshots/demo.gif) -->

---

## The Problem

- Only **9.9%** of rural adults can operate a computer (NSO, NSS 75th Round) — form-based listing tools exclude most artisans.
- India's handicraft sector employs **1.13 crore** workers who earn just **₹270/day**, while 3–4 intermediaries take their own margin (Institute for Human Development & Crafts Council of India, 2026).
- Crafts fairs offer market access for only a few days a year — outside that window, there's no storefront at all.

## The Solution

BhArt lets an artisan log in with just a phone number, photograph their craft, and speak any correction out loud. Everything else — bilingual copy, background cleanup, fair pricing, publishing — happens automatically.

1. **Login** — Phone number + OTP
2. **Snap photo** — the craft, as it is
3. **AI processing** (runs in parallel):
   - Understand & write — names the craft, writes English + Hindi text
   - Clean the photo — background removed, studio-style
   - Suggest a price — from material and craft effort
4. **Review card** — bilingual text + ₹ price, ready to check
5. **Speak to edit** — say a correction (e.g. *"keemat 600 rupaye kar do"*) and only that field updates
6. **Publish** — one tap, live in the buyer feed

## Tech Stack

- **Language:** Dart
- **Framework:** Flutter — single codebase for Android, iOS, and web
- **Backend:** Supabase (PostgreSQL, phone-OTP auth, storage)
- **AI:**
  - Gemini Flash Vision — bilingual text generation, pricing, voice-edit parsing
  - Hugging Face RMBG-1.4 — background removal
- **State management:** Riverpod
- **Routing:** go_router

## Getting Started

### Prerequisites

- Flutter SDK (stable channel)
- A Supabase project (URL + anon key)
- Gemini and Hugging Face API keys

### Setup

```bash
git clone https://github.com/kace6/BhArt.git
cd BhArt
flutter pub get
```

Copy the example env file and fill in your own keys:

```bash
cp env.example.json env.json
```

```json
{
  "SUPABASE_URL": "your-supabase-url",
  "SUPABASE_ANON_KEY": "your-supabase-anon-key"
}
```

> `env.json` is git-ignored — never commit real keys.

### Run

```bash
# Mobile (with a device/emulator connected)
flutter run --dart-define-from-file=env.json

# Web
flutter run -d chrome --dart-define-from-file=env.json
```

### Build for web deployment

```bash
flutter build web --dart-define-from-file=env.json
```

Output is generated in `build/web/`.

## Known Limitations / Roadmap

- API calls currently run client-side; moving them behind Supabase Edge Functions is planned before any real release.
- Product images are stored inline; migrating to Supabase Storage is planned.
- Voice-edit playback on web currently produces a `blob:` URL rather than a file path — downstream transcription handling for the web target is still being finalized.
- Planned: ONDC pan-India marketplace integration, digital payments & micro-logistics tie-ups, offline queue for patchy rural connectivity, multi-dialect voice recognition.

## Research & References

- Fourth All India Handloom Census (2019–20), Ministry of Textiles, Govt. of India
- Export Promotion Council for Handicrafts (EPCH) — official export data
- "Economics of Indian Craft" (2026), Institute for Human Development & Crafts Council of India
- Baseline survey, 2,000+ artisans across 9 states — Digital Empowerment Foundation & Commonwealth of Learning
- "Indian Artisans Are Still Missing From E-Commerce" — Sattva Knowledge Institute / India Development Review

## Team

**Team Axiom8** — Smart India Hackathon 2026
