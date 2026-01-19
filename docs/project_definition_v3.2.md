# **PROJECT DISKARTE AI: MASTER PRD (SSoT v3.1)**

Owner: Solo Developer / Project Manager  
Architecture: The "Trinity" (Google Antigravity, Firebase, Vertex AI)  
Core Model: Gemini 1.5 Flash (Exclusive)  
Status: Finalized Single Source of Truth \- Comprehensive Version

## **1\. EXECUTIVE STRATEGY & MISSION**

### **1.1 Mission Statement**

To democratize access to Artificial Intelligence for the Filipino "mass market" (minimum wage earners, students, job seekers) by removing the barrier of high monthly subscription fees.

### **1.2 The "Sachet" (Tingi) Business Model**

* **The Barrier:** Most AI tools (ChatGPT Plus, Gemini Advanced) cost \~₱1,200/month, which is prohibitive for the target demographic.  
* **The Solution:** Apply the Filipino "Tingi" (sachet) economy model: bite-sized, high-value AI services available for micro-payments (₱20–₱50).  
* **Core Brand Promise:** *"Ang Secret Weapon ng Pinoy."* (The Filipino's Secret Weapon). The app is not positioned as a luxury tech toy, but as a survival tool for "Diskarte" (resourcefulness) in work, school, and daily life.

## **2\. TARGET USER PERSONA: "JUAN"**

* **Profile:** 23-year-old high school graduate, job seeker, or contractual worker (e.g., service crew, warehouse encoder).  
* **Location:** Often in Greater Manila Area (GMA) or provincial hubs like Cavite and Bulacan.  
* **Hardware:** Low-end Android devices (Infinix, Tecno, Itel) with limited storage (\~32GB).  
* **Connectivity:** Relies strictly on prepaid mobile data; highly sensitive to data consumption and app size.  
* **Pain Point:** Needs professional help (writing, English, advice) but cannot afford consultants or expensive subscriptions.

## **3\. PLATFORM ARCHITECTURE (THE TRINITY)**

### **3.1 The Google Power Base**

1. **Google Antigravity:** The Architect & Coder. Leveraging AI Agents to write the code, manage instructions, and build application structure with minimal manual effort.  
2. **Firebase (The "Bar Studio"):** The "Engine Room." Handles Hosting, Authentication (Phone/SMS), Firestore (Database), and Cloud Functions (Python).  
3. **Vertex AI (Gemini 1.5 Flash):** The high-speed, low-cost intelligence engine with deep Taglish understanding and lowest cost per token.

### **3.2 Tech Stack Matrix**

| Component | Technology | Reasoning |
| :---- | :---- | :---- |
| **IDE / Environment** | Firebase Studio (Project IDX) | Browser-based IDE with Gemini built-in. No local setup needed. |
| **Frontend** | Flutter (Web) PWA | Single codebase. Responsive. Zero storage required; bypasses App Store delays. |
| **Authentication** | Firebase Auth | Supports Phone/SMS (primary) and Google Sign-in (fallback). Critical for management. |
| **Backend Logic** | Firebase Cloud Functions | Serverless Python logic; pay-per-execution. Python is ideal for AI logic. |
| **Webhooks** | Python Flask Route | Endpoint to listen for PayMongo success signals. |
| **AI Engine** | Vertex AI (Gemini 1.5 Flash) | Highest speed; multilingual support; native Firebase integration. |
| **Database** | Firestore | Real-time NoSQL; stores user wallets, timestamps, and chat logs. |

## **4\. FEATURE SPECIFICATIONS & PERSONA PROMPTS**

### **4.1 The "MVP" Menu**

1. **The Bureaucracy Breaker (Admin & Gov):** Generates formal letters and interprets government forms (Indigency requests, Barangay complaints, Mayor's office medical assistance, Passport appointments).  
2. **The Diskarte Toolkit (Work & Hustle):** Professionalizes the user for employment. Includes a **Resume Fixer** (service crew to BPO-ready), **Seller Reply Bot** (Shopee/Lazada), and **Grammar Polish**.  
3. **The Aral-Masa (Education):** Homework helper explaining concepts in Tagalog/English step-by-step for parents and students.  
4. **The Diskarte Coach (Motivation & Grit):** A stoic, non-religious success coach focused on ambition and resilience.

### **4.2 Intelligence & Prompt Engineering**

* **General Capability:** Primary: Taglish (Code-switching); Secondary: Cebuano/Bisaya.  
* **Persona \- General:** *"You are a helpful Filipino assistant. Reply in the same language the user uses. Be concise. Do not use flowery words."*  
* **Persona \- Bureaucracy:** *"You are a formal correspondence expert. Use High Filipino-English suitable for government officials. Be formal and respectful."*  
* **Persona \- Coach:** *"You are a stoic friend. Use 'Tropa' tone. Use slang like 'Lodi' or 'Petmalu'. Be empowering but realistic. If the user wants to quit, remind them: 'Kaya mo yan, banat ulit'."*

## **5\. USER JOURNEY & SYSTEM LOGIC**

### **5.1 Onboarding & Entry**

* **Channel:** Facebook Messenger links to PWA (diskarte.ph).  
* **Landing:** User views a Grid Menu. Features are visible but locked/blurred until payment.  
* **Auth Flow:** User logs in via Phone Number (SMS OTP). reCAPTCHA Enterprise check is mandatory to prevent bot attacks on SMS budget.

### **5.2 System Logic Flow**

1. **Input:** User types/speaks in Taglish.  
2. **Security Check:** Cloud Function checks Rate Limit (Max 10 req/min).  
3. **Subscription Check:** Function checks Firestore: if current\_time \< subscription\_end\_time.  
4. **Intelligence:** If valid, Python calls Vertex AI (Gemini 1.5 Flash).  
5. **Output:** Gemini returns text; displayed instantly.

## **6\. DATABASE SCHEMA & SECURITY (FIRESTORE)**

### **6.1 Data Structures**

* **Collection: users**  
  * uid: Unique Firebase Auth ID.  
  * phoneNumber: String.  
  * displayName: String.  
  * subscription\_end\_timestamp: Server Timestamp.  
  * is\_active: Computed Boolean.  
* **Collection: chat\_logs** (Sub-collection)  
  * feature\_type: \[Admin, Toolkit, Aral, Coach\]  
  * content: String.  
  * timestamp: ServerTimestamp.

### **6.2 Security & Governance**

* **SMS Protection:** Hard-cap on daily OTP messages. Firebase App Check integration.  
* **Webhook Security:** paymongo\_webhook MUST verify X-Paymongo-Signature header using the secret key in Environment Variables.  
* **Idempotency:** Track payment\_id to prevent double-crediting.  
* **Data Privacy:** TTL (Time To Live) policy to auto-delete chat\_logs after 30 days.

## **7\. REVENUE & PAYMENT MODEL**

### **7.1 Pricing Strategy**

* **Babad Pass (4h):** ₱20  
* **Day Pass (24h):** ₱50 (Best value standard)  
* **Weekly Pass (7d):** ₱200  
* **Future Concept:** "The Wallet" \- Load ₱50 credits; deduct ₱1.00 per request.

### **7.2 The Payment Loop**

* **Gateway:** PayMongo (GCash, Maya primary). Fees: \~2.5% per transaction.  
1. User pays via GCash on PayMongo link.  
2. PayMongo sends Webhook to Firebase Cloud Function.  
3. Function verifies secret and updates subscription\_end\_timestamp (e.g., adds 24 hours).

### **7.3 Profit Analysis (per ₱50 Pass)**

* **Gross Revenue:** ₱50.00  
* **PayMongo Fee:** \-₱1.25  
* **Est. AI Cost:** \-₱3.00 to \-₱5.00  
* **Hosting/SMS Overhead:** \-₱2.00  
* **Net Profit per User/Day:** **\~₱43.75**

## **8\. UI/UX DESIGN LANGUAGE**

* **Mental Model:** Hybrid of GCash (Financial Trust) and Facebook Messenger (Daily Familiarity).  
* **Colors:** Navy Blue (\#002D72) and Clean White. High contrast for sunlight readability.  
* **Layout:** 2x2 Grid Menu for MVP features.  
* **Thumb-Friendly:** Primary elements in the bottom 60% of the screen.  
* **Performance:** Skeleton Loaders for poor 4G/LTE; SVG icons only; system fonts (Sans Serif).  
* **Interaction:** Ghost text placeholders and contextual Action Chips (*"Gawing Formal"*, *"Translate to Bisaya"*).

## **9\. LOGISTICS & PH SCALING (PH MONTH PLAN)**

* **Legal:** DTI Registration ("Diskarte AI Services") at bnrs.dti.gov.ph. BIR Form 2303 (COR).  
* **Banking:** Open BPI or UnionBank account (requires personal appearance).  
* **Connectivity:** Buy Globe/Smart SIM. Register it. Load ₱500. Text **ROAM ON** to 8080/333. Critical for receiving OTPs abroad.  
* **Funding:** Apply for **Google for Startups Cloud Program** for $2,000 credits. Research Angle: "Low-Resource Language Resilience in Emerging Economies."  
* **Scaling:** Phase 1: FB Groups/PWA \-\> Phase 2: Barangay QR Codes \-\> Phase 3: Native Android APK.

## **10\. MARKETING NARRATIVE: "A DAY IN THE LIFE"**

1. **The Trigger:** Juan sees a post: *"Nahihirapan mag-English sa Resume? Gamitin ang Diskarte AI. ₱50 lang."*  
2. **The Action:** He clicks the link. It opens in Messenger. He pays via GCash.  
3. **The Task (Resume):** Juan types: *"Service crew ako sa Jollibee 2 years. encoder 1 year. Gusto ko mag-Call Center."*  
4. **The Result (Toolkit):** Diskarte AI generates a polished resume highlighting "Customer Service Excellence."  
5. **The Doubt (Coaching):** Juan types: *"Kinakabahan ako sa interview, baka di ko kaya."*  
6. **The Coach:** *"Normal lang kabahan, Lodi. Ibig sabihin seryoso ka. Tandaan mo: Service crew ka dati, sanay ka sa pressure. Yakang-yaka mo yan. Banat ulit\!"*  
7. **The Outcome:** Juan gets the job. He shares the link. Viral "Diskarte" loop.

## **11\. DEVELOPER EXECUTION GUIDE (PROMPTS)**

1. **Auth:** *"Scaffold a Flutter login screen using Firebase Authentication. Prioritize Phone Number login with SMS OTP. Integrate reCAPTCHA Enterprise. Ensure the user ID is passed to Firestore."*  
2. **Database:** *"Create a Firestore schema that includes a users collection. Each user document should have a subscription\_end\_timestamp field and a chat\_logs sub-collection."*  
3. **Webhooks:** *"Write a Python Cloud Function using Flask that listens for a PayMongo webhook. When a 'payment.paid' event is received and verified via secret key, find the user in Firestore and add 24 hours to their subscription\_end\_timestamp."*  
4. **Logic:** *"Write the backend logic to check if datetime.now() is less than the user's subscription\_end\_timestamp. If true, call the Vertex AI Gemini 1.5 Flash API with the system instructions for \[Feature Type\]. If false, return a 'Please Subscribe' error."*  
5. **Infrastructure:** *"Review the Firebase project configuration. Ensure the hosting location is set to asia-southeast1 (Singapore) to ensure the lowest latency for my users in the Philippines."*