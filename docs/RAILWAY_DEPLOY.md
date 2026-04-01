# Railway Deployment Guide

This guide shows the easiest way to publish the project with one public URL where the frontend, backend, and database work together.

## Target Result

After deployment, your project will open from one link like:

`https://your-app.up.railway.app/`

That single link will load the JSP frontend, call the Java servlet backend, and use the Railway MySQL database.

## Current Live URL

The project is already deployed and live at:

`https://ai-powered-expense-analyzer-production.up.railway.app`

## Requirements

Before starting, keep these ready:

- A GitHub account
- A Railway account
- This project uploaded to a GitHub repository

## Step 1: Upload the Project to GitHub

1. Create a new GitHub repository.
2. Upload this full project folder.
3. Confirm these files are present in the repo root:
   - `Dockerfile`
   - `.dockerignore`
   - `src/`
   - `docker/`

## Step 2: Create a Railway Project

1. Open Railway dashboard.
2. Click `New Project`.
3. Choose `Empty Project`.

## Step 3: Add MySQL Database

1. Inside the Railway project, click `New`.
2. Choose `Database`.
3. Select `MySQL`.
4. Wait until the MySQL service becomes active.

Railway will create database environment variables automatically.

## Step 4: Add the Web App

1. Click `New`.
2. Choose `GitHub Repo`.
3. Select your uploaded repository.
4. Railway will detect the `Dockerfile` and build the app.

No extra build command is required because the app is already configured for Docker-based Tomcat deployment.

## Step 5: Confirm App and DB Are in the Same Project

Your Railway project should now contain:

- one `MySQL` service
- one app service from GitHub

This is important because the app reads Railway database variables during deployment/runtime.

## Step 6: Generate the Public URL

1. Open the app service in Railway.
2. Go to `Settings`.
3. Open `Networking`.
4. Click `Generate Domain`.

Railway will create a public URL such as:

`https://expense-analyzer-production.up.railway.app/`

For this project, the current generated live URL is:

`https://ai-powered-expense-analyzer-production.up.railway.app`

## Step 7: Open the Project

Open the generated Railway URL in the browser.

The app should load the login page directly because the web application is deployed at root context.

## Demo Login

Use the seeded default account:

- Email: `admin@example.com`
- Password: `admin123`

## OCR Support on Railway

Image OCR is enabled in the deployed container using Tesseract OCR.

That means Bill Scan supports:

- image upload OCR
- OCR text file upload
- pasted OCR text

## What Is Already Configured in This Project

The project was updated so Railway deployment is easier:

- `Dockerfile` deploys the JSP/Servlet app on Tomcat 9 with Java 21
- `docker/docker-entrypoint.sh` binds Tomcat to Railway's runtime port
- `DBConnection.java` reads Railway MySQL environment variables
- H2 fallback is available if MySQL is unavailable

## If Deployment Fails

Check these points:

1. The GitHub repository contains the full project, not only `docs/`.
2. The Railway app service and Railway MySQL service are inside the same Railway project.
3. The `Dockerfile` is in the repository root.
4. The deployment logs do not show Java compilation errors.
5. The generated public domain is attached to the app service, not the database service.

## Quick Submission Note

If a student or faculty member asks for the project URL, share only the generated Railway app link.

Example:

`https://your-app.up.railway.app/`

Current example:

`https://ai-powered-expense-analyzer-production.up.railway.app`

That is the single URL they need to open the full working project.
