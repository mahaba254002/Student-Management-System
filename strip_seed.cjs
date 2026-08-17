const fs = require('fs');

let staff = fs.readFileSync('staff_schema.sql', 'utf8');
const lines = staff.split('\n');

let newLines = [];
for (let i = 0; i < lines.length; i++) {
    if (lines[i].includes('-- SEED DATA')) {
        break;
    }
    newLines.push(lines[i]);
}

// Just add the admin staff and system user
const adminSql = `
-- ============================================================
-- 19. ADMIN SEED DATA ONLY (As requested by user)
-- ============================================================

INSERT INTO staff (
    staff_number, first_name, last_name,
    gender, phone, email,
    employment_type, role, department, 
    employment_date, contract_type, status
) VALUES (
    'KHS/ADM003','Admin', 'User',
    'MALE', '0711100003','admin@kwalehigh.sc.ke',
    'NON_TEACHING','ADMIN','Administration', 
    '2015-06-01','PERMANENT','ACTIVE'
) ON CONFLICT (staff_number) DO NOTHING;


INSERT INTO system_users (username, password_hash, role, staff_id)
SELECT 'admin', 'admin123', 'admin', s.id
FROM staff s WHERE s.staff_number = 'KHS/ADM003'
ON CONFLICT (username) DO NOTHING;
`;

newLines.push(adminSql);

fs.writeFileSync('staff_schema.sql', newLines.join('\n'));
console.log('staff_schema.sql stripped of all seed data except admin');
