# Shared Package

## Purpose

Contains shared TypeScript types, utility functions, and constants used
across `backend` and `frontend` packages.

## Rules

- No package-specific logic here — shared types and utilities only
- All exports must be documented with JSDoc
- Breaking changes require a major version bump

## Publishing

This package is published internally via the monorepo workspace.
Do not publish to npm.
