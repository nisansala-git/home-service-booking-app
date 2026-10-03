# FixIt Home – Home Service Booking Mobile Application

> **Course**: IT3060 – Human Computer Interaction  
> **Milestone**: 03 – Mobile App Implementation & Final Evaluation  
> **Group Number**: `KND_HCI_G05`  
> **Academic Institution**: Sri Lanka Institute of Information Technology (SLIIT) – Faculty of Computing  

---

## 📌 1. Project Overview

**FixIt Home** is a cross-platform mobile application designed to bridge the trust and transparency gap in the home-services sector (plumbers, electricians, cleaners, carpenters, etc.). Grounded in empirical user research from Milestone 01 and validated through interactive high-fidelity prototyping in Milestone 02, this application directly tackles:
- **Unclear and fluctuating pricing** via mandatory upfront quote tables.
- **Weak booking confirmations** through automated status tracking with ticket-style summaries.
- **Provider registration drop-offs** through resilient multi-step verification with fallbacks.
- **Scope disputes mid-job** with a digital contract and refundable escrow deposit system.
- **Unverified testimonials** through verified, timestamped ratings and past work galleries.

---

## 👥 2. Team Members & Workload Distribution

| Student ID | Full Name | Assigned Module / Workload | Core Interfaces Implemented | CRUD Operations |
|---|---|---|---|---|
| **IT23684980** | Amarasinghe A.A.P.D | **Discovery & Provider Authentication** | 1. Home / Service Discovery<br>2. Search Results + Filters<br>3. Provider Registration Form<br>4. Provider Registration & Verification | • **Create**: Register provider account<br>• **Read**: Search & filter providers<br>• **Update**: Filter query states<br>• **Delete**: Clear search filters |
| **IT23707122** | Ariyathilake N.M. | **Booking, Scheduling & Digital Contract** | 5. Provider Profile<br>6. Availability & Booking<br>7. Booking Confirmation<br>8. Digital Contract & Deposit | • **Create**: New service booking<br>• **Read**: Provider profiles & upfront pricing<br>• **Update**: Sign digital contract & deposit<br>• **Delete**: Cancel pending booking slot |
| **IT23710610** | Karunathilaka T G C N | **Payments, Reviews & Provider Dashboard** | 9. Secure Payment & Receipt<br>10. Completed Job & Review<br>11. Provider Dashboard / Job Requests | • **Create**: Submit verified customer review<br>• **Read**: Provider live requests & schedule<br>• **Update**: Accept / Decline incoming jobs<br>• **Delete**: Dismiss completed orders |
| **IT23630802** | Musharaf M J M | **Notifications, Job Lifecycle & History** | 12. Provider Notifications & Job Details<br>13. My Bookings / Job History<br>14. Job History & Rebooking | • **Create**: Dispatch job alerts & notifications<br>• **Read**: Chronological alerts & booking history<br>• **Update**: Mark alert as read / update lifecycle<br>• **Delete**: Clear notification from inbox |

---

## 🎯 3. Traceability Matrix (Requirements → Implementation)

| Req ID | Requirement Description | Mapped Interface(s) | Implementation File | Status |
|---|---|---|---|---|
| **FR001** | Verified accounts for homeowners and providers | Provider Registration & Verification | `provider_registration_screen.dart` | ✅ Implemented |
| **FR002** | Reliable OTP step with resend option & fallback | Provider Verification Screen | `provider_verification_screen.dart` | ✅ Implemented |
| **FR003** | Upfront price / quote before booking confirmed | Provider Profile, Availability | `provider_profile_screen.dart` | ✅ Implemented |
| **FR004** | Immediate, automated booking confirmation | Booking Confirmation Screen | `booking_confirmation_screen.dart` | ✅ Implemented |
| **FR005** | Verified reviews + provider past work / history | Provider Profile, Job History | `job_history_screen.dart` | ✅ Implemented |
| **FR006** | Digital contract + deposit before job starts | Digital Contract & Deposit Screen | `digital_contract_deposit_screen.dart` | ✅ Implemented |
| **FR007** | Real-time job requests & push notifications | Provider Dashboard, Notifications | `provider_dashboard_screen.dart` | ✅ Implemented |
| **FR008** | Service categories with filtering | Home Discovery, Search Results | `home_discovery_screen.dart` | ✅ Implemented |
| **FR009** | Secure in-app payment with digital receipt | Secure Payment & Receipt Screen | `secure_payment_receipt_screen.dart` | ✅ Implemented |
| **FR010** | Homeowner rates/reviews provider after completion | Completed Job & Review Screen | `completed_job_review_screen.dart` | ✅ Implemented |
| **NFR001** | Usability: No dead ends or silent failures | Verification & Booking Flows | Across all flows | ✅ Implemented |
| **NFR002** | Performance: Confirmation within seconds | Booking & Checkout Steppers | Reactive State Engine | ✅ Implemented |
| **NFR004** | Security: Payment data encrypted in transit | Secure Checkout Gateway | `secure_payment_receipt_screen.dart` | ✅ Implemented |
| **NFR006** | Mobile responsiveness & reference UI parity | All Screens (390 × 844 Reference) | `app_constants.dart` | ✅ Implemented |
| **NFR007** | Scalability: Conflict prevention on time slots | Availability & Booking Screen | `availability_booking_screen.dart` | ✅ Implemented |

---

## 🛠️ 4. Technology Stack & Justification

- **Frontend**: **Flutter (Dart)**  
  *Justification*: High-performance single-codebase rendering engine providing native iOS/Android look and feel, responsive layout scaling tailored for 390 × 844 reference resolution, and rich micro-animations.
- **Backend & Database**: **Firebase Cloud Firestore**  
  *Justification*: Flexible NoSQL document database supporting real-time listeners for live booking status changes, conflict-free scheduling, and verified reviews.
- **Authentication**: **Firebase Authentication**  
  *Justification*: Robust multi-channel authentication (Phone SMS OTP, Email/Password) with fallback mechanisms addressing Milestone 01's provider registration findings.
- **Storage**: **Firebase Storage**  
  *Justification*: Scalable media storage for provider National ID verification documents, past work project galleries, and customer review photos.
- **Version Control**: **Git & GitHub**  
  *Justification*: Distributed version control facilitating seamless collaborative development among all 4 group members with feature branch isolation.

---

## 📂 5. Project Directory Structure

```text
home-service-booking-app/
├── assets/                          # Images, icons, and illustrations
├── lib/
│   ├── main.dart                    # Application entry point & Viva role-switcher shell
│   ├── core/
│   │   ├── constants/
│   │   │   └── app_constants.dart   # Reference size (390x844), categories, constants
│   │   ├── theme/
│   │   │   └── app_theme.dart       # Forest Green & Cream Material 3 design system
│   │   └── widgets/
│   │       └── common_widgets.dart  # CustomAppBar, StarRating, StatusBadge
│   ├── models/
│   │   └── models.dart              # ServiceProvider, Booking, Review, Notification models
│   ├── services/
│   │   ├── app_state_service.dart   # Reactive CRUD state management (2+ ops per member)
│   │   └── mock_data.dart           # Realistic personas & seed data (Kamal, Poornima, etc.)
│   └── features/
│       ├── member1_discovery_auth/
│       │   ├── home_discovery_screen.dart
│       │   ├── search_results_screen.dart
│       │   ├── provider_registration_screen.dart
│       │   └── provider_verification_screen.dart
│       ├── member2_booking_contract/
│       │   ├── provider_profile_screen.dart
│       │   ├── availability_booking_screen.dart
│       │   ├── booking_confirmation_screen.dart
│       │   └── digital_contract_deposit_screen.dart
│       ├── member3_payment_reviews/
│       │   ├── secure_payment_receipt_screen.dart
│       │   ├── completed_job_review_screen.dart
│       │   └── provider_dashboard_screen.dart
│       └── member4_notifications_history/
│           ├── provider_notifications_screen.dart
│           ├── my_bookings_screen.dart
│           └── job_history_screen.dart
├── test/                            # Unit and widget test cases
├── pubspec.yaml                     # Dependencies and project metadata
└── README.md                        # Documentation and team instructions
```

---

## 🚀 6. Setup & Running Instructions

### Prerequisites
1. **Flutter SDK**: Version `3.24.0` or higher (`brew install --cask flutter` on macOS or download from [flutter.dev](https://flutter.dev)).
2. **Git**: Installed and configured.
3. An Android Emulator, iOS Simulator, or Chrome browser.

### Clone and Run
```bash
# 1. Clone the repository
git clone https://github.com/<YOUR_ORGANIZATION_OR_USERNAME>/home-service-booking-app.git

# 2. Navigate to project root
cd home-service-booking-app

# 3. Fetch dependencies
flutter pub get

# 4. Run the application
flutter run
# Or run on Chrome for quick evaluation:
# flutter run -d chrome
```

---

## 🌿 7. Team Git Collaboration Workflow

To ensure smooth collaboration between all 4 team members without merge conflicts:

1. **Main Branch Protection**:
   `main` is protected and always holds stable, runnable code.
2. **Member Feature Branches**:
   Each member branches from `main` using their designated prefix:
   - Member 1: `git checkout -b feature/member1-discovery-auth`
   - Member 2: `git checkout -b feature/member2-booking-contract`
   - Member 3: `git checkout -b feature/member3-payment-reviews`
   - Member 4: `git checkout -b feature/member4-notifications-history`
3. **Commit Messages**:
   Use conventional commits: `feat:`, `fix:`, `docs:`, `style:`.
4. **Pull Requests**:
   Submit PRs to `main` with code reviews from at least one other team member before merging.

---

## 🎓 8. Assignment Evaluation Notes
- A top navigation banner in the app allows examiners to toggle between **Homeowner View** and **Provider View** on the fly.
- All 14 user interfaces from Milestone 02 are linked and functional.
- Each member's interface contains at least 2 working CRUD operations connected to `AppStateService`.
