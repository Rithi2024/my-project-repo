# Backend (Node.js + Express + SQL Server)

## Setup
```bash
npm install
```

## Configuration
Copy `.env.example` to `.env` and update values.

```bash
copy .env.example .env
```

## Run
```bash
npm run dev
```

Backend runs at:
```
http://localhost:3000
```

---

## API Endpoints

### Authentication
- POST `/api/auth/signup`
- POST `/api/auth/login`
- POST `/api/auth/forgot-password`

---

### Categories
- GET `/api/categories?search=`
- POST `/api/categories` (JWT required)
- PUT `/api/categories/:id` (JWT required)
- DELETE `/api/categories/:id` (JWT required)

---

### Products
- GET `/api/products?page=&limit=&search=&category_id=&sort_by=&order=`
- POST `/api/products` (JWT required)
- PUT `/api/products/:id` (JWT required)
- DELETE `/api/products/:id` (JWT required)

---

## Images
Images are served from:
```
backend/upload/images
```

Example:
```
http://localhost:3000/images/p001.jpg
```
