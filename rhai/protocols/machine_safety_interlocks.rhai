// Kerma Radiation Oncology Simulation Engine
// Hardware Safety Interlocks and Collision Clearance Verification

let clearance_radius_gantry_head_mm = 550.0;
let couch_clearance_limit_z_mm = -400.0;
let min_leaf_collision_gap_mm = 0.5;

print("=================================================================");
print("LINAC SAFETY INTERLOCKS & COUCH CLEARANCE ENGINE");
print("=================================================================");

fn verify_leaf_gap(leaf_pair_a, leaf_pair_b) {
    let gap = leaf_pair_b - leaf_pair_a;
    if gap < min_leaf_collision_gap_mm {
        return false;
    }
    return true;
}

fn verify_couch_gantry_collision(gantry_angle_deg, couch_angle_deg, couch_vert_mm) {
    // Non-coplanar clearance checks
    if couch_vert_mm < couch_clearance_limit_z_mm && (gantry_angle_deg > 30.0 && gantry_angle_deg < 150.0) {
        return false; // Collision danger zone
    }
    return true;
}

// Audit sample delivery state
let test_a = -10.0;
let test_b = -9.8;
let gap_valid = verify_leaf_gap(test_a, test_b);
print("Opposing Leaf Gap Check: " + if gap_valid { "[PASS]" } else { "[INTERLOCK TRIGGERED]" });

let collision_safe = verify_couch_gantry_collision(0.0, 0.0, -150.0);
print("Gantry-Couch Clearance: " + if collision_safe { "[CLEAR]" } else { "[COLLISION DETECTED]" });
print("=================================================================");
