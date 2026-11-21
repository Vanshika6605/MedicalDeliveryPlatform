# MediFlow - Medical Delivery Platform

A comprehensive, state-of-the-art medical delivery and pharmacy management platform. The platform connects patients, retail pharmacists, delivery agents, and system administrators via a meticulously designed suite of tailored dashboards, real-time tracking, and automated fulfillment workflows. 

## Activity 3 deployment

Jenkins checks out this repository, installs the frontend and backend lockfiles, runs the backend tests, then builds and archives `dist/`. Create a Pipeline job named `MediFlow-Activity-3`, select **Pipeline script from SCM** with Git, and use `Jenkinsfile` as the script path. The agent needs Git and Node.js 22.12 or newer in the Node.js 22 line on its `PATH`.

For a local Docker demo, create a root `.env` with independently generated `POSTGRES_PASSWORD` and `JWT_SECRET` values made of hexadecimal characters. Use at least 24 random bytes for the database password and 32 for the JWT secret. Then run:

```sh
docker compose up --build --detach --wait
docker compose ps
curl -fsS http://localhost:8082/api/health
```

The local browser URL is `http://localhost:8082`. Nginx serves the frontend and proxies the API, uploads, and Socket.IO. Docker Compose keeps the database and uploads in named volumes. The demo starts with an empty database and uses no live payment, SMS, or prescription-processing credentials.

For the AWS demo, run these commands from `terraform/` with your AWS CLI credentials active. Set `viewer_ipv4_cidr` to your own public IPv4 address in `/32` notation and `commit_sha` to the pushed Git commit you intend to deploy.

```sh
terraform init
terraform fmt -check
terraform validate
terraform plan -out=activity3.tfplan -var="demo_cidr=$viewer_ipv4_cidr" -var="source_revision=$commit_sha"
terraform apply activity3.tfplan
terraform output
```

Terraform creates a separate AWS network and an EC2 demo host. EC2 checks out the supplied revision and builds the same Compose stack. Once instance bootstrap completes, use the `app_url` output for the browser and `/api/health` for the API check. The demo uses HTTP restricted to the specified IPv4 address and is intended for synthetic data. Replacing the instance replaces its local demo data. EC2 and its storage can incur charges while the environment exists.

## 🌟 Key Features & Core Ecosystem

The system is built on a multi-role architecture offering extensive capabilities out of the box.

### 👥 Customer Facing (B2C)
- **Product Discovery**: Rich e-commerce browsing with sidebar filtering, categorized sections (medicine, self-care, wellness), and comprehensive drug details (salt name, manufacturer, MRP, requiring prescription flags).
- **Cart & Checkout Engine**: Robust cart management with real-time price calculation, integrated Razorpay payment gateway handling, and seamless transition from adding to cart to confirming the order.
- **AI-Powered Prescription Upload**: Smart prescription management that supports drag-and-drop file uploads and allows users to order prescription-based medicines efficiently.
- **Real-Time Order Tracking**: End-to-end tracking capabilities—from order placement and packing to dispatch and final delivery. Incorporates live map simulation, pulsing courier radar, and secure OTP verification for pickup and delivery.

### 🏪 Retailer (B2B) Operations
- **Retailer Dashboard**: An analytics-driven operations center for partner pharmacies to track performance metrics, revenue, and order volume.
- **Order Fulfillment Interface**: Manage incoming requests, pack items, confirm readiness, and securely hand over packages to delivery agents using OTP-based verification.
- **Store & Inventory Management**: Handles geolocation mapping (lat/lng, delivery radius), KYC approval status workflows, and bank account integration for seamless payouts.

### 🛵 Delivery Agent Portal
- **Agent Dashboard**: A dedicated interface for delivery personnel featuring current pickups, live location streaming (upserted to backend real-time), and daily earnings overview.
- **Optimized Routing & Status**: GPS location pings to provide live tracking to the customer and the admin. Real-time updates on active delivery tasks and availability toggles (`is_online`).

### ⚙️ System Administration
- **Global Command Center**: A bird's-eye view featuring system-wide Key Performance Indicators (KPIs), user distributions (roles: user, retailer, agent, admin), and order lifecycle oversight.
- **Financial & Payment Operations**: Sophisticated transaction ledger (payments, payouts, refunds), pending disbursements tracking, Razorpay reconciliation, and detailed financial tables categorized by entity (User, Retailer, Agent).
- **User & KYC Management**: Tools to suspend/activate users, approve pending retailer KYCs, and oversee all active platform participants.

## 🏗️ Technical Architecture & Stack

### Frontend Architecture
- **Framework**: React 18+ bundled with Vite for blazing-fast performance.
- **Design System**: A highly polished, custom UI powered by Tailwind CSS. Features dynamic asymmetric Bento Grids, nuanced Glassmorphism (`backdrop-blur`), tonal layering, and sophisticated micro-animations.
- **Routing & State**: Handled smoothly via React Router DOM (v6), providing a Single Page Application (SPA) experience across multiple complex dashboards.

### Backend Infrastructure
- **Core Environment**: robust Node.js and Express.js REST API providing secure, typed interactions.
- **Relational Database**: PostgreSQL handling complex relationships (carts, users, orders, agent locations) with heavily optimized UUID indexing and strict referential integrity.
- **Authentication & Security**: Stateful JWT-based authentication combined with `bcryptjs` for secure password hashing. Role-Based Access Control (RBAC) enforced seamlessly across all endpoints.
- **Payments Engine**: Native Razorpay integration (`razorpay` Node SDK) for processing customer transactions and generating reference IDs (razorpay_order_id) directly linked to internal order states.

## 🧩 Database Schema Overview
The foundation of the platform relies on a sophisticated relational schema ensuring data consistency:
- **`users`**: Maintains multi-role identity profiles including JWT tokens, KYC states, and role assignments.
- **`medicines` & `categories`**: Deeply structured inventory supporting varying medical product types (tablet, syrup, injection) and pricing schemas (MRP vs Selling Price, HSN Code).
- **`orders` & `transactions`**: High-availability ledger for order cycles (`placed` > `packing` > `ready` > `in_transit` > `delivered`) backed by transactional integrity.
- **`cart_items`**: Highly responsive session-based cart management mapped efficiently back to users.

---

*This application is built as a proprietary, enterprise-grade demonstration of full-stack medical logistics platform capabilities. It showcases complex state management, secure payment workflows, multi-actor coordination, and real-time backend updates.*
