/**
 * auth.js – Kwale High School SMS
 *
 * This file is now a thin compatibility shim.
 * All auth logic (requireAuth, populateTopBar, logout, apiFetch)
 * lives in dashboard.js which is loaded after this file.
 *
 * Keeping this file so existing pages that include it don't break.
 *
 * ── Demo users (offline fallback only) ──────────────────────────
 * These are used by the login page when the API is unreachable.
 * The real credentials are stored in the system_users DB table.
 */

// No-op: functions are defined in dashboard.js
// This file intentionally left minimal.
