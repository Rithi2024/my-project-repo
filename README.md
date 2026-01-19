# Flutter + Node.js Product Management App

## Repository Structure
/backend  - Node.js + Express API  
/frontend - Flutter application  
/sql      - Database schema & sample data  
/docs     - Documentation  

## Setup Instructions

### 1) Database
Run in SQL Server:
- sql/schema.sql
- sql/sample_data.sql

### 2) Backend
```bash
cd backend
npm install
copy .env.example .env
npm run dev
```

Backend URL:
```
http://localhost:3000
```

### 3) Frontend (Android Emulator)
```bash
cd frontend
flutter pub get
flutter run
```

## API Base URL
- Android Emulator: http://10.0.2.2:3000
- Local Browser: http://localhost:3000

## Features
- JWT Authentication (Login / Signup / Forgot Password)
- Category CRUD with Khmer search
- Product CRUD with pagination, infinite scroll, sorting, filtering
- Images served by backend and cached locally on device
