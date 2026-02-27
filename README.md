# StayOnTrack AI

## 1. Repository Overview & Team Introduction

### Repository Overview

**StayOnTrack AI** is a full-stack academic planning system designed to help university students proactively manage their semester workload.

The system combines:

- **Flutter** (Frontend)
- **Spring Boot** (Backend)
- **Firebase** (Authentication & Firestore)
- **Google Gemini AI** (Planning & Task Intelligence)

Unlike static calendars or reminder apps, StayOnTrack AI converts academic constraints into structured, AI-generated weekly plans that adapt over time.

### Team Introduction

| Name | Role |
|------|------|
|1. Thian Xin Yi (Team leader)| Planner Engine, Weekly Adaptation, & Conducted full-system validation and testing |
|2. Tan Kai Chun| Academic Constraint Engine & Deadline System |
|3. Lee Sie Ting| Group Assignment AI & Task Distribution |
|4. Alice Tang Ong Xin| System Integration & Reward System |

---

## 2. Project Overview

### Problem Statement

University students often struggle because they:

- Cannot visualize workload across the entire semester
- Do not prepare early enough for major exams
- Fail to distribute assignment effort realistically
- Mismanage group projects due to unclear task allocation
- React only after falling behind

**Existing tools:**

- Display deadlines but do not plan backward
- Do not adapt when tasks are missed
- Do not reason over workload intensity
- Do not assist with fair group task distribution

This leads to stress, overload, and last-minute preparation.

### SDG Alignment

- **SDG 4 – Quality Education**  
  Enhances structured learning through AI-assisted workload planning.

- **SDG 3 – Good Health & Well-Being**  
  Reduces academic stress through balanced effort distribution and proactive scheduling.

### Solution

**StayOnTrack AI:**

- Collects academic constraints first
- Understands study habits and energy patterns
- Generates structured year → month → week plans
- Regenerates only the next week when conditions change
- Uses AI to break down and distribute group assignments
- Reinforces consistency through achievement-based rewards

**It is not a chatbot.**  
**It is not a reminder app.**  
**It is a structured adaptive academic engine.**

---

## 3️. Key Features

### Authentication & Setup

- Firebase Authentication
- Semester configuration
- Course & exam input
- Assignment input with difficulty level
- Focus & energy profile setup

### AI-Generated Planner

- Year workload visualization
- Month-level preparation phases
- Weekly time-slotted execution plan
- No overlapping sessions

### Planner Regeneration

Triggered when:

- Deadlines are edited
- New tasks or exams are added
- Weekly availability changes

### Weekly Check-In

- Completion tracking
- Overdue detection
- Availability adjustment
- Regeneration trigger
  - Only the next week regenerates to preserve semester stability

### AI Group Assignment Assistant

- Upload assignment brief (text/file)
- AI extracts logical deliverables
- Effort estimation
- Task dependency reasoning
- Strength-based task distribution
- Regeneration options

### Achievement-Based Reward System

- Users earn marks for task completion
- Unlockable reward items
- Positive reinforcement without emotional dependency logic

---

## 4️. Technologies Used

### Google Technologies

| Technology | Purpose |
|------------|---------|
| **Google Gemini 1.5 Flash** | Planner generation, weekly planner regeneration, group assignment task extraction, effort estimation, task distribution balancing |
| **Firebase** | Firebase Authentication, Google Cloud Firestore, Firebase Admin SDK|

### Other Technologies

| Layer | Technology |
|-------|------------|
| **Backend**  | Java 21, Spring Boot 3.5, Maven, REST APIs (JSON over HTTP), CORS configuration |
| **Frontend** | Flutter (Dart 3.11+), Material 3, SharedPreferences (local session), Google Fonts |

---

## 5️. Implementation Details & Innovation

### System Architecture

```
┌──────────────────────────── Flutter Frontend ───────────────────────────┐
│                                                                         │
│  Auth Module        Planner Module        Group Module       Reward UI  │
│  ───────────        ──────────────        ─────────────      ─────────  │
│  Login / Signup     Year View             Group Setup         Marks     │
│  Profile            Month View            Task Breakdown     Unlock UI  │
│                     Week View             Distribution       Collection │
│                     Check-In                                            │
└─────────────────────────────────┬───────────────────────────────────────┘
                                  │ REST API
                                  ▼
┌──────────────────────────── Spring Boot Backend ─────────────────────────┐
│                                                                          │
│  ┌──────────────┐   ┌───────────────┐   ┌──────────────┐                 │
│  │ Auth Service │   │ PlannerEngine │   │ Group Service│                 │
│  └──────────────┘   └───────────────┘   └──────────────┘                 │
│                                                                          │
│  ┌──────────────┐   ┌───────────────┐   ┌──────────────┐                 │
│  │ RewardService│   │ GeminiService │   │ FirestoreSvc │                 │
│  └──────────────┘   └───────────────┘   └──────────────┘                 │
│                                                                          │
└───────────────────────────────┬──────────────────────────────────────────┘
                                │
        ┌───────────────────────┼────────────────────────┐
        ▼                       ▼                        ▼
 Firebase Authentication   Cloud Firestore         Google Gemini API
```

The backend acts as:
- AI orchestration layer
- Constraint processor
- Data validator
- Regeneration controller
- Secure API key handler

### System Workflow

#### A. Academic Setup & Individual Planning

1. User signs up and logs in (Firebase Authentication).
2. User completes semester setup:
   - Semester dates
   - Courses
   - Exams
   - Assignments
   - Focus & energy profile
3. Academic data stored in Firestore.
4. Backend retrieves constraints.
5. Backend constructs structured AI prompt.
6. Google Gemini generates weekly study schedule.
7. Backend validates:
   - No overlapping sessions
   - Proper break spacing
   - Coverage of deadlines
8. Validated tasks stored in Firestore.
9. Planner rendered in Flutter (Year → Month → Week views).

#### B. Weekly Adaptation Flow

1. User completes tasks during the week.
2. Weekly Check-In collects:
   - Completion rate
   - Updated available study hours
3. Backend regenerates next week only using updated constraints.
4. Updated tasks replace next week's schedule.
5. Historical weeks remain unchanged.

#### C. Group Assignment AI Flow

1. User creates a group and adds members.
2. User inputs assignment brief (text or file).
3. Backend sends structured brief to Gemini.
4. Gemini returns:
   - Extracted deliverables
   - Task breakdown
   - Effort estimation
   - Suggested distribution
5. Backend validates structured response.
6. Group tasks stored in Firestore.
7. User confirms distribution.
8. Confirmed tasks optionally synced into personal planner as deadlines.

#### D. Reward System Flow

1. When task is marked as completed:
   - RewardService calculates marks.
   - Marks stored in UserMarks.
2. If weekly completion ≥ threshold:
   - Bonus marks awarded.
3. User can unlock reward items using accumulated marks.
4. Unlock state stored in UnlockedRewards.

### Core Innovation

| Innovation | Description |
|------------|-------------|
| **Constraint-First Planning Model** | Planning begins with structured academic constraints rather than reactive reminders. |
| **Controlled Regeneration Model** | Only the next week adapts — preventing instability across the semester. |
| **AI-Validated Scheduling** | Backend enforces: no overlapping sessions, proper breaks between sessions, difficulty alignment with peak focus time. |
| **AI-Based Task Decomposition** | Assignment briefs are analyzed to extract logical, effort-balanced subtasks. |
| **Achievement-Based Reinforcement** | Consistency is rewarded through structured gamification. |

This moves beyond calendar apps into an **intelligent academic engine**.

---

## 6️. Challenges Faced

1. **Structured AI Output**  
   Gemini responses required careful prompt engineering and backend validation to ensure consistent JSON parsing.

2. **Preventing Overlapping Sessions**  
   AI occasionally generated back-to-back sessions. We implemented post-processing logic to enforce time spacing.

3. **Regeneration Stability**  
   Designing adaptation logic that updates only the next week required careful architectural separation.

4. **Cross-Platform Development**  
   Handling Web, Android emulator, and CORS differences required environment-aware configuration.

5. **Firestore Data Mapping**  
   Ensuring consistent date formats and data structures across frontend and backend required validation layers.

---

## 7️. Installation & Setup

### Prerequisites

- Java 21+
- Maven
- Flutter SDK 3.11+
- Firebase project
- Google Gemini API key

### Backend Setup

git clone https://github.com/Nonmixx/StayOnTrack.git
cd Kitahack2026/backend


**Add:**
- `src/main/resources/firebase-key.json`

**Set Gemini API key:**

- **Option A — Environment Variable:** 
  export GOOGLE_AI_API_KEY=your_key

- **Option B — application-local.properties:**
  spring.ai.google.api-key=your_key

**Run backend:**
mvn spring-boot:run

Runs at: **http://localhost:9091**

### Frontend Setup
cd ../frontend
flutter pub get
flutter run

| Platform | Backend URL |
|----------|-------------|
| Android emulator | `http://10.0.2.2:9091` |
| Web | `http://localhost:9091` |

---

## 8️. Future Roadmap

### 1. Smart Push Notification System

Implement intelligent push notifications that:
- Remind users before critical study blocks
- Detect missed sessions and suggest recovery slots
- Alert users when workload intensity increases
- Provide motivational nudges before exams

Instead of simple reminders, notifications will be **workload-aware**.

### 2. Advanced Study Analytics Dashboard

Introduce a visual analytics module showing:
- Weekly completion trends
- Effort distribution across courses
- Study time vs. deadline proximity correlation
- Burnout risk indicators
- Consistency score over semester

This will transform StayOnTrack from a planner into a **reflective academic tool**.

### 3. Predictive Workload Risk Detection

Enhance AI to:
- Detect future overload weeks
- Predict risk of deadline clustering
- Recommend early redistribution of effort
- Suggest preventive plan adjustments before overload happens

This moves the system from **reactive adaptation** to **predictive prevention**.

### 4. Calendar Integration
Enable export and sync with:
- Google Calendar
- iCal
- Outlook

This allows users to integrate AI-generated study sessions into their daily life ecosystem.

### 5. Offline Mode with Sync Recovery

Implement:
- Local caching of planner tasks
- Offline task completion
- Background synchronization when connection is restored
- Conflict resolution strategy

This improves reliability and accessibility.

### 6. LMS Integration

Future integration with:
- University LMS platforms
- Automated deadline import
- Assignment brief auto-detection
- Real-time grade tracking integration

This reduces manual input and enhances automation.

### 7. Evolution Into Interactive Animal Companion System

**Currently:**
- Users unlock animals using achievement marks.
- Animals are static reward collectibles.

**Future enhancement:**
- Animals become interactive companions.
- Reflect academic consistency (without negative emotional manipulation).
- Provide visual feedback when weekly goals are achieved.
- Unlock behavior animations as user progresses.

This transforms the reward system into a deeper gamified engagement layer while preserving academic seriousness.

### 8. Accessibility & Inclusive Design Improvements

- High contrast mode
- Adjustable font scaling
- Screen reader compatibility
- Multi-language support
- Cognitive-friendly UI mode

Aligns with SDG 4's inclusive education goals.
