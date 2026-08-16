# Campus Marketplace --- Project Synopsis

## Overview

Campus Marketplace is a mobile application built with Flutter that
allows students to buy and sell used items --- books, electronics,
furniture, calculators, notes, and more --- within their own college
community.

## Problem Statement

Students often have unused items they'd like to sell, while other
students look for the same items at lower prices. There is no simple,
campus-focused platform for this. Campus Marketplace solves that by
giving students one app to list, browse, search, and buy items from
peers.

## Objective

To build a full-stack mobile application where students can create
accounts, list products with images, browse/search/filter listings,
view seller details, and manage their own listings --- demonstrating a
complete real-world app rather than a basic CRUD project.

## Key Features

- User registration & login (JWT-based authentication)
- Create, edit, delete product listings
- Upload product images (camera/gallery)
- Browse and search products
- Filter by category, price, and condition
- Product details with seller information
- Contact seller (call/email/WhatsApp)
- Mark items as sold
- User dashboard and profile management

## Technology Stack

| Layer | Technology |
|---|---|
| Mobile App | Flutter (Dart) |
| State Management | Riverpod / Provider |
| Navigation | go_router |
| API Client | Dio |
| Backend | Node.js + Express.js |
| Database | MongoDB (Mongoose) |
| Authentication | JWT + bcrypt |
| Image Storage | Cloudinary |
| Hosting | MongoDB Atlas, Render/Railway |
| Version Control | Git & GitHub |

## System Architecture

```text
Flutter App  →  REST API (Node.js + Express)  →  MongoDB
                          ↓
                     Cloudinary (images)
```

## Expected Outcome

A working cross-platform (Android/iOS) marketplace app with secure
authentication, image-based listings, search & filters, and full CRUD
functionality --- suitable as a resume/portfolio project demonstrating
full-stack mobile development skills.
