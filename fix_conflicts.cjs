/**
 * Fix all bare "ON CONFLICT DO NOTHING" in seed_extra.sql and staff_schema.sql
 * by replacing them with proper alternatives:
 * - Tables with UNIQUE constraints: use ON CONFLICT (col) DO NOTHING
 * - Tables without UNIQUE constraints: remove ON CONFLICT entirely (data already guarded by CONTINUE WHEN EXISTS or WHERE clauses)
 */
const fs = require('fs');

// ── Fix seed_extra.sql ────────────────────────────────────────────────────────
let seed = fs.readFileSync('seed_extra.sql', 'utf8');

// 1. dormitories — has UNIQUE(name) per staff_schema.sql
seed = seed.replace(
    `    ('Chui Block',    60,  'MALE')\nON CONFLICT DO NOTHING;`,
    `    ('Chui Block',    60,  'MALE')\nON CONFLICT (name) DO NOTHING;`
);

// 2. classes — has UNIQUE(level, stream) per staff_schema.sql
seed = seed.replace(
    `    ('Form 4 West',  '4', 'West',  45)\nON CONFLICT DO NOTHING;`,
    `    ('Form 4 West',  '4', 'West',  45)\nON CONFLICT (level, stream) DO NOTHING;`
);

// 3. student_enrollments — has UNIQUE(student_id, academic_year_id)
seed = seed.replace(
    `        ON CONFLICT DO NOTHING;\n\n        -- Assign 70% of students to dorms`,
    `        ON CONFLICT (student_id, academic_year_id) DO NOTHING;\n\n        -- Assign 70% of students to dorms`
);

// 4. student_boarding_assignments — no unique constraint: remove ON CONFLICT (already a new insert)
seed = seed.replace(
    `            ON CONFLICT DO NOTHING;\n        END IF;`,
    `        END IF;`
);

// 5. staff_class_assignments — no unique constraint: remove ON CONFLICT
seed = seed.replace(
    `            ON CONFLICT DO NOTHING;\n        END LOOP;\n    END IF;\nEND;\n$$;\n\n-- ── 7.`,
    `        END LOOP;\n    END IF;\nEND;\n$$;\n\n-- ── 7.`
);

// 6. fee_structure — no unique constraint: remove ON CONFLICT
seed = seed.replace(
    `WHERE ay.is_current = TRUE\nON CONFLICT DO NOTHING;\n\n-- Sample fee payments`,
    `WHERE ay.is_current = TRUE;\n\n-- Sample fee payments`
);

// 7. fee_payments — no unique constraint: remove ON CONFLICT
seed = seed.replace(
    `  AND s.id % 10 < 6  -- 60% paid\nON CONFLICT DO NOTHING;`,
    `  AND s.id % 10 < 6;  -- 60% paid`
);

fs.writeFileSync('seed_extra.sql', seed);
console.log('seed_extra.sql patched');

// ── Fix staff_schema.sql ─────────────────────────────────────────────────────
let staff = fs.readFileSync('staff_schema.sql', 'utf8');

// Lines 553-644: multiple bare ON CONFLICT DO NOTHING on various tables
// Check each context

// student_parents — has UNIQUE(student_id, parent_id)
staff = staff.replace(/ON CONFLICT DO NOTHING;\s*$/mg, (match, offset) => {
    // We'll handle generically - replace ALL bare ON CONFLICT DO NOTHING with nothing
    // for tables without unique constraints, and handle specific ones separately
    return match; // placeholder - handle below
});

// Better approach: read line by line context
const staffLines = staff.split('\n');
const patchedLines = [];
for (let i = 0; i < staffLines.length; i++) {
    const line = staffLines[i];
    if (line.trim() === 'ON CONFLICT DO NOTHING;') {
        // Look back to find what table this belongs to
        let insertLine = '';
        for (let j = i - 1; j >= Math.max(0, i - 30); j--) {
            if (/INSERT INTO/i.test(staffLines[j])) {
                insertLine = staffLines[j];
                break;
            }
        }

        if (/student_parents/i.test(insertLine)) {
            patchedLines.push('ON CONFLICT (student_id, parent_id) DO NOTHING;');
        } else if (/student_enrollments/i.test(insertLine)) {
            patchedLines.push('ON CONFLICT (student_id, academic_year_id) DO NOTHING;');
        } else if (/staff_subject_assignments/i.test(insertLine)) {
            patchedLines.push('ON CONFLICT (staff_id, subject_id) DO NOTHING;');
        } else {
            // No unique constraint: just skip the conflict clause entirely
            // (don't push this line - remove it)
            console.log(`  Removing bare ON CONFLICT near: ${insertLine.trim()}`);
        }
    } else {
        patchedLines.push(line);
    }
}

fs.writeFileSync('staff_schema.sql', patchedLines.join('\n'));
console.log('staff_schema.sql patched');

console.log('\nDone! Commit and push, then call /api/init-db');
