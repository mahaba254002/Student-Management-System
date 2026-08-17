# Implementation Plan – Mobile, Admin People & Teacher Dashboard

## What we're changing

Three separate improvements across the whole system:

1. **Mobile responsiveness** – All dashboards work well on phones
2. **Admin People section** – Add staff, view staff details (teacher or non-teaching)
3. **Teacher dashboard redesign** – Dynamic nav: Subject Teacher + optional Class Teacher section

---

## 1. Mobile Responsiveness (`dashboard.css`)

### Problem
On small screens the sidebar overlaps the content, cards overflow, and the topbar search pushes elements out of view.

### Fix
- On **mobile (≤768px)**: sidebar slides off-screen (`transform: translateX(-240px)`), toggled by an overlay
- Hamburger button stays always visible in top-left
- A dark **overlay** covers the page when sidebar is open, tap to dismiss
- Stats grid becomes **2-column on tablet**, **1-column on phone**
- Content grid becomes **1-column** on mobile
- Topbar search **hides on mobile**, replaced with a search icon that expands
- Nav cards become **3-column on mobile** instead of 4
- `page-content` padding reduces from `28px` to `16px` on mobile

---

## 2. Admin – People Section

### New pages
| File | Purpose |
|---|---|
| `pages/admin-people.html` | Staff list (Teachers + Non-Teaching) with Add Staff button |
| `pages/admin-staff-detail.html` | Individual staff profile with edit fields (except finance) |

### Admin People list
- **Tabs**: All Staff / Teachers / Non-Teaching Staff
- Each staff card shows: Avatar, Name, Role, Department, Employee No, Status badge
- **Add Staff** button opens a slide-in drawer form
- Click a staff card → goes to `admin-staff-detail.html?id=xxx`

### Admin Staff Detail
- Full staff profile: personal info, employment info, teaching assignments
- **Editable fields**: name, phone, email, address, department, assigned subjects/classes, status
- **Read-only**: Employee No (system-generated), role
- **Not shown**: Any financial data (salaries, etc.)
- Edit button → inline editing with Save/Cancel

### Admin sidebar update
- People section gets sub-items: `All Staff`, `Teachers`, `Non-Teaching`, `Add Staff`

---

## 3. Teacher Dashboard Redesign (`pages/teacher.html`)

### Two teacher types (determined by session data)
```
isClassTeacher: true/false
classTeacherOf: "Form 3 North" (if applicable)
```

### Dynamic sidebar
If **Subject Teacher only**:
```
Dashboard | My Profile
My Teaching > My Subjects, My Classes, Subject Results, Student Performance
Announcements | Notifications | Settings | Logout
```

If **Class Teacher** (in addition):
```
Dashboard | My Profile
My Teaching > My Subjects, My Classes, Subject Results, Student Performance
Class Teacher > My Class, Attendance, Class Performance, My Students
Announcements | Notifications | Settings | Logout
```

### Dashboard content
- Greeting with name, role (Subject Teacher / Class Teacher – Form X)
- 3 stat cards: My Classes, My Subjects, My Students
- Today's timetable (action-oriented)
- Class Teacher Tasks section (if class teacher): attendance reminder, pending student requests
- No finance, no other staff data, no admin controls

### Auth.js update
Add `isClassTeacher` and `classTeacherOf` fields to the teacher demo user.

---

## Files to create/modify

| File | Action |
|---|---|
| `dashboard.css` | Major mobile responsive rewrite |
| `auth.js` | Add `isClassTeacher`, `classTeacherOf` to teacher user |
| `pages/admin.html` | Update sidebar with People sub-items |
| `pages/admin-people.html` | **NEW** – Staff list with tabs + add staff drawer |
| `pages/admin-staff-detail.html` | **NEW** – Staff profile with edit (no finance) |
| `pages/teacher.html` | Complete redesign – dynamic nav + action-oriented dashboard |
| All other dashboard pages | Add mobile overlay sidebar JS snippet |

---

## Verification
- Open on Chrome DevTools → iPhone SE, Pixel 5, iPad – sidebar, cards, nav all look clean
- Login as `admin`, click Teachers → see staff list → click a staff card → see profile → click Edit → edit fields → Save
- Login as `teacher` → see dynamic sidebar without Class Teacher section
- Login as `teacher` with `isClassTeacher: true` → see Class Teacher section appear
