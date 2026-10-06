# APF — Pediatric Therapy & Child Developmental Assessment Platform

An advanced Flutter-based healthcare and developmental tracking application designed to bridge parents and pediatric therapists. The platform enables multi-role collaboration, structured hierarchical clinical questionnaires, developmental milestone tracking, and automated clinical report generation.

---

## 🌟 Key Features

### 👨‍👩‍👧 Parent Portal
- **Child Profile Management**: Register and manage profiles for children receiving therapy or undergoing developmental evaluations.
- **Hierarchical Questionnaires**: Complete structured, category-based developmental assessments tailored to age and therapy goals.
- **Milestone & Progress Tracking**: Real-time visual progress monitoring of developmental achievements and therapy interventions.
- **Direct Feedback & Reports**: Access therapist-reviewed reports and progress notes.

### 🩺 Therapist Portal
- **Patient Roster**: Search, filter, and maintain detailed clinical profiles of children under care.
- **Clinical Assessment Engine**: Conduct standardized assessments across motor, cognitive, speech, and behavioral domains.
- **Session Feedback**: Submit diagnostic feedback, clinical remarks, and customized home therapy plans.
- **Automated PDF Reports**: Generate structured diagnostic and progress reports for clinical record-keeping and parental review.

### 🔐 Authentication & Cloud Architecture
- **Role-Based Access Control (RBAC)**: Distinct permissions and secure routing for parents vs. certified therapists.
- **Firebase Integration**: Built on Firebase Authentication and Cloud Firestore with strict security rules (`firestore.rules`).
- **Cloud Document Storage**: Automated generation and storage of printable PDF evaluation summaries.

---

## 🏗️ Technology Stack

- **Framework**: [Flutter](https://flutter.dev/) (Dart)
- **Backend / BaaS**: [Firebase](https://firebase.google.com/) (Auth, Cloud Firestore)
- **Document Services**: `pdf` / `printing` for on-device PDF generation
- **Platform Support**: Android, iOS, Web

---

## 📁 Project Architecture

```
lib/
├── services/                                # Core services & APIs
│   ├── auth_service.dart                    # Firebase Authentication & session state
│   ├── child_service.dart                   # Firestore child profiles & milestone queries
│   └── pdf_service.dart                     # Clinical PDF evaluation report generation
├── role_selection_page.dart                 # Initial role routing (Parent / Therapist)
├── parent_dashboard.dart                    # Parent home & status overview
├── therapist_dashboard.dart                 # Therapist overview & patient roster
├── parent_hierarchical_question_response_page.dart  # Interactive parent assessment forms
├── therapist_hierarchical_question_page.dart        # Clinical questionnaire review & scoring
├── parent_reports_page.dart                 # Downloadable PDF progress reports
└── therapist_reports_page.dart              # Therapist report publishing
```

---

## 🚀 Getting Started

### Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (v3.0+)
- Android Studio / Xcode
- Configured Firebase project

### Installation
1. Clone the repository:
   ```bash
   git clone https://github.com/Kabhilan-VS-05/APF-Flutter.git
   cd APF-Flutter
   ```

2. Install dependencies:
   ```bash
   flutter pub get
   ```

3. Configure Firebase:
   Ensure `google-services.json` (Android) and `GoogleService-Info.plist` (iOS) are properly placed in their respective platform directories.

4. Run the app:
   ```bash
   flutter run
   ```

---

## 📄 License
This project is proprietary and developed by [Kabhilan VS](https://github.com/Kabhilan-VS-05). All rights reserved.
