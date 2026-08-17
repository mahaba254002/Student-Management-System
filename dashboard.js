/**
 * dashboard.js – Kwale High School SMS  v2.1
 * Shared sidebar behaviour + auth helpers + API helpers.
 * Include on every dashboard page AFTER auth.js (stub).
 */

const API_BASE = window.location.hostname === 'localhost' || window.location.hostname === '127.0.0.1' ? 'http://localhost:8001' : '';

// ── Role → dashboard URL mapping ──────────────────────────────────
const ROLE_DASHBOARD = {
    admin:            'admin.html',
    principal:        'principal.html',
    deputy_principal: 'deputy.html',
    hod:              'hod.html',
    teacher:          'teacher.html',
    accountant:       'accountant.html',
    parent:           'parent.html',
    student:          'student.html',
};

const ROLE_LABELS = {
    admin:            'Administrator',
    principal:        'Principal',
    deputy_principal: 'Deputy Principal',
    hod:              'Head of Department',
    teacher:          'Teacher',
    accountant:       'Accountant',
    parent:           'Parent',
    student:          'Student',
};

(function () {

    // ── Role Sidebar Navigation ─────────────────────────────────────
    const ROLE_NAVS = {
        admin: [
            { title: 'Main', items: [{ label: 'Dashboard', href: '/pages/admin.html', icon: '&#127968;' }] },
            { title: 'People', items: [
                { label: 'All Staff', href: '/pages/admin-people.html?type=all', icon: '&#128101;' },
                { label: 'Teachers', href: '/pages/admin-people.html?type=teachers', icon: '&#129489;' },
                { label: 'Non-Teaching', href: '/pages/admin-people.html?type=nonteaching', icon: '&#128119;' }
            ]},
            { title: 'School', items: [
                { label: 'Academic Years', href: '/pages/admin-academic-years.html', icon: '&#128197;' },
                { label: 'Dormitories', href: '/pages/admin-dormitories.html', icon: '&#127970;' },
                { label: 'Previous Schools', href: '/pages/admin-schools.html', icon: '&#127963;' }
            ]},
            { title: 'Academic', items: [
                { label: 'Classes', href: '/pages/admin-classes.html', icon: '&#127979;' },
                { label: 'Subjects', href: '/pages/admin-subjects.html', icon: '&#128218;' },
                { label: 'Exams', href: '/pages/admin-exams.html', icon: '&#128221;' }
            ]},
            { title: 'Students', items: [
                { label: 'All Students', href: '/pages/admin-students.html', icon: '&#127891;' },
                { label: 'Add New Student', href: '/pages/admin-add-student.html', icon: '&#10133;' },
                { label: 'Attendance', href: '/pages/admin-attendance.html', icon: '&#128203;' }
            ]},
            { title: 'Finance', items: [
                { label: 'Fees Collection', href: '/pages/admin-fees.html', icon: '&#128179;' },
                { label: 'Expenses', href: '/pages/admin-expenses.html', icon: '&#128202;' }
            ]},
            { title: 'System', items: [
                { label: 'Users', href: '/pages/admin-users.html', icon: '&#128100;' },
                { label: 'Settings', href: '/pages/admin-settings.html', icon: '&#9881;' }
            ]}
        ],
        principal: [
            { title: 'Main', items: [{ label: 'Overview', href: '/principal.html', icon: '&#127968;' }] },
            { title: 'Academics', items: [
                { label: 'Classes & Results', href: '/pages/admin-classes.html', icon: '&#127979;' },
                { label: 'Exams', href: '/pages/admin-exams.html', icon: '&#128221;' }
            ]},
            { title: 'People', items: [
                { label: 'Staff Directory', href: '/pages/admin-people.html?type=all', icon: '&#128101;' },
                { label: 'Student Directory', href: '/pages/admin-students.html', icon: '&#127891;' }
            ]}
        ],
        deputy_principal: [
            { title: 'Main', items: [{ label: 'Overview', href: '/deputy.html', icon: '&#127968;' }] },
            { title: 'Discipline', items: [{ label: 'Cases & Records', href: '/pages/admin-discipline.html', icon: '&#9878;' }] },
            { title: 'Academics', items: [
                { label: 'Timetable', href: '/pages/admin-timetable.html', icon: '&#128197;' },
                { label: 'Attendance', href: '/pages/admin-attendance.html', icon: '&#128203;' }
            ]}
        ],
        hod: [
            { title: 'Department', items: [{ label: 'Overview', href: '/hod.html', icon: '&#127968;' }] },
            { title: 'Academics', items: [
                { label: 'Subject Performance', href: '/pages/admin-exams.html', icon: '&#128200;' },
                { label: 'Department Staff', href: '/pages/admin-people.html?type=teachers', icon: '&#129489;' }
            ]}
        ],
        teacher: [
            { title: 'Main', items: [{ label: 'My Dashboard', href: '/teacher.html', icon: '&#127968;' }] },
            { title: 'My Work', items: [
                { label: 'My Profile', href: '/pages/my-profile.html', icon: '&#128100;' },
                { label: 'My Classes', href: '/pages/admin-classes.html', icon: '&#127979;' },
                { label: 'Enter Marks', href: '/pages/admin-exams-marks.html', icon: '&#128221;' }
            ]},
            { title: 'Records', items: [{ label: 'Attendance', href: '/pages/admin-attendance.html', icon: '&#128203;' }] }
        ],
        accountant: [
            { title: 'Finance', items: [{ label: 'Dashboard', href: '/accountant.html', icon: '&#127968;' }] },
            { title: 'Transactions', items: [
                { label: 'Fee Collection', href: '/pages/admin-fees.html', icon: '&#128176;' },
                { label: 'Expenses', href: '/pages/admin-expenses.html', icon: '&#128201;' }
            ]},
            { title: 'Reports', items: [{ label: 'Financial Reports', href: '/pages/admin-fees.html', icon: '&#128202;' }] }
        ],
        parent: [
            { title: 'Portal', items: [{ label: 'Dashboard', href: '/parent.html', icon: '&#127968;' }] },
            { title: 'My Children', items: [
                { label: 'Academic Reports', href: '/pages/admin-exams.html', icon: '&#128221;' },
                { label: 'Fee Statements', href: '/pages/admin-fees.html', icon: '&#128176;' }
            ]}
        ]
    };

    function renderSidebar() {
        const sidebar = document.getElementById('sidebar');
        if (!sidebar) return;

        // Try getting user from localStorage
        const userRaw = localStorage.getItem('khs_user_v2') || sessionStorage.getItem('khs_user');
        const user = userRaw ? JSON.parse(userRaw) : null;
        
        // Default to admin nav if no user found (useful for previewing)
        const role = user ? user.role : 'admin';
        const navConfig = ROLE_NAVS[role] || ROLE_NAVS['admin'];

        const page = (window.location.pathname.split('/').pop() || '').toLowerCase().split('?')[0];

        const navHTML = navConfig.map(section => {
            const links = section.items.map(item => {
                const targetFile = item.href.split('?')[0].toLowerCase();
                const isActive   = page === targetFile;
                return `<a href="${item.href}" class="nav-item${isActive ? ' active' : ''}">
                    <span class="nav-icon">${item.icon}</span>
                    <span class="nav-label">${item.label}</span>
                </a>`;
            }).join('');
            return `<span class="nav-section-title">${section.title}</span>${links}`;
        }).join('');

        sidebar.innerHTML = `
            <div class="sidebar-logo">
                <div class="logo-badge">KHS</div>
                <div class="logo-text">
                    <span>Kwale High</span>
                    <span>${ROLE_LABELS[role] || 'Portal'}</span>
                </div>
                <button class="sidebar-close" id="sidebar-close" title="Close menu">✕</button>
            </div>
            <nav class="sidebar-nav">${navHTML}</nav>
            <div class="sidebar-footer">
                <button class="logout-btn" onclick="logout()">
                    <span class="btn-icon">&#128682;</span>
                    <span class="btn-label">Logout</span>
                </button>
            </div>`;
    }

    function isMobile() { return window.innerWidth <= 768; }

    function initSidebar() {
        const sidebar = document.getElementById('sidebar');
        const wrapper = document.getElementById('main-wrapper');
        const toggle  = document.getElementById('sidebar-toggle');
        const overlay = document.getElementById('sidebar-overlay');
        if (!sidebar || !toggle) return;

        toggle.addEventListener('click', () => {
            if (isMobile()) {
                sidebar.classList.toggle('mobile-open');
                if (overlay) overlay.classList.toggle('active');
            } else {
                sidebar.classList.toggle('collapsed');
                if (wrapper) wrapper.classList.toggle('collapsed');
            }
        });

        if (overlay) overlay.addEventListener('click', closeMobile);

        sidebar.addEventListener('click', e => {
            if (e.target.closest('#sidebar-close')) closeMobile();
        });

        window.addEventListener('resize', () => {
            if (!isMobile()) {
                sidebar.classList.remove('mobile-open');
                if (overlay) overlay.classList.remove('active');
            }
        });

        function closeMobile() {
            sidebar.classList.remove('mobile-open');
            if (overlay) overlay.classList.remove('active');
        }
    }

    // ── Drawer helpers ─────────────────────────────────────────────
    function openDrawer(id, oid) {
        const d = document.getElementById(id);
        const o = document.getElementById(oid);
        if (d) d.classList.add('open');
        if (o) o.classList.add('open');
    }
    function closeDrawer(id, oid) {
        const d = document.getElementById(id);
        const o = document.getElementById(oid);
        if (d) d.classList.remove('open');
        if (o) o.classList.remove('open');
    }

    // ── Tab helpers ────────────────────────────────────────────────
    function initTabs(sel, cb) {
        const tabs = document.querySelectorAll(sel + ' .tab-btn');
        tabs.forEach(btn => btn.addEventListener('click', () => {
            tabs.forEach(t => t.classList.remove('active'));
            btn.classList.add('active');
            if (typeof cb === 'function') cb(btn.dataset.tab);
        }));
    }

    // ── Expose globals ─────────────────────────────────────────────
    window.KHS = { initSidebar, openDrawer, closeDrawer, initTabs, renderSidebar };

    // ── Auto-init ──────────────────────────────────────────────────
    function init() { renderSidebar(); initSidebar(); }
    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', init);
    } else { init(); }

})();


// ════════════════════════════════════════════════════════════════
// AUTH — stored in localStorage so it persists across page loads
// ════════════════════════════════════════════════════════════════

const KHS_SESSION_KEY = 'khs_user_v2';

function saveSession(user) {
    localStorage.setItem(KHS_SESSION_KEY, JSON.stringify(user));
}

function saveToken(token) {
    if (token) localStorage.setItem('khs_jwt', token);
}

function getToken() {
    return localStorage.getItem('khs_jwt') || null;
}

function getSession() {
    const raw = localStorage.getItem(KHS_SESSION_KEY);
    return raw ? JSON.parse(raw) : null;
}

function clearSession() {
    localStorage.removeItem(KHS_SESSION_KEY);
    localStorage.removeItem('khs_jwt');
    // also clear old sessionStorage key if present
    sessionStorage.removeItem('khs_user');
}

/**
 * Redirect to login if no session found.
 * Call at the top of every protected dashboard page.
 */
function requireAuth(allowedRoles) {
    // Migrate old sessionStorage session to localStorage
    const oldRaw = sessionStorage.getItem('khs_user');
    if (oldRaw) {
        localStorage.setItem(KHS_SESSION_KEY, oldRaw);
        sessionStorage.removeItem('khs_user');
    }

    const user = getSession();
    if (!user) {
        // Determine correct login page path
        const depth = window.location.pathname.split('/').length - 2;
        const prefix = depth > 0 ? '../'.repeat(depth) : './';
        window.location.replace(prefix + 'index.html');
        return null;
    }

    // Role guard: redirect to own dashboard if wrong role page
    if (allowedRoles && !allowedRoles.includes(user.role)) {
        const dest = ROLE_DASHBOARD[user.role];
        if (dest) window.location.replace(dest);
        return null;
    }

    return user;
}

function populateTopBar(user) {
    if (!user) return;
    const nameEl   = document.getElementById('user-name');
    const avatarEl = document.getElementById('user-avatar');
    const roleEl   = document.getElementById('user-role');

    const displayName = user.name || user.username || 'User';
    const parts       = displayName.split(' ').filter(Boolean);
    const initials    = parts.length >= 2
        ? (parts[0][0] + parts[parts.length - 1][0]).toUpperCase()
        : displayName.slice(0, 2).toUpperCase();

    if (nameEl)   nameEl.textContent   = displayName;
    if (avatarEl) avatarEl.textContent = user.avatar || initials;
    if (roleEl)   roleEl.textContent   = ROLE_LABELS[user.role] || user.role;
}

function logout() {
    clearSession();
    const depth  = window.location.pathname.split('/').length - 2;
    const prefix = depth > 0 ? '../'.repeat(depth) : './';
    window.location.replace(prefix + 'index.html');
}


// ════════════════════════════════════════════════════════════════
// API HELPERS
// ════════════════════════════════════════════════════════════════

async function apiFetch(path, opts = {}) {
    try {
        const token = getToken();
        const headers = { ...(opts.headers || {}) };
        if (token) headers['Authorization'] = `Bearer ${token}`;
        if (!headers['Content-Type'] && opts.body) headers['Content-Type'] = 'application/json';
        const resp = await fetch(API_BASE + path, { ...opts, headers });
        if (!resp.ok) {
            const err = await resp.json().catch(() => ({}));
            throw new Error(err.detail || `HTTP ${resp.status}`);
        }
        return await resp.json();
    } catch (e) {
        console.warn('[KHS API]', path, '→', e.message);
        return null;
    }
}
