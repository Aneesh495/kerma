// Kerma Radiation Oncology Simulation Engine
// Clinical Protocol: RTOG 0631 Single-Fraction Spine Stereotactic Radiosurgery (SRS)

let protocol_name = "RTOG-0631 Single-Fraction Spine SRS";
let prescription_gy = 18.0;
let fractions = 1;

print("=================================================================");
print("CLINICAL PROTOCOL AUDIT: " + protocol_name);
print("Prescription: " + prescription_gy + " Gy x " + fractions + " fraction");
print("=================================================================");

// High-gradient spinal cord and cauda equina tolerances (AAPM TG-101 / RTOG 0631)
let constraints = [
    #{ organ: "Partial Spinal Cord", metric: "D_0.035cc", limit: 14.0, unit: "Gy" },
    #{ organ: "Partial Spinal Cord", metric: "V_10Gy",    limit: 10.0, unit: "%" },
    #{ organ: "Cauda Equina",        metric: "D_0.035cc", limit: 16.0, unit: "Gy" },
    #{ organ: "Esophagus",           metric: "D_0.035cc", limit: 14.5, unit: "Gy" },
    #{ organ: "Sacral Plexus",       metric: "D_0.035cc", limit: 18.0, unit: "Gy" },
    #{ organ: "Kidney Cortex (Bil)", metric: "V_8.4Gy",   limit: 200.0, unit: "cc" }
];

fn validate_spine_srs(metrics, ptv_coverage_pct, conformity_index, gradient_index) {
    let ok = true;
    for c in constraints {
        let key = c.organ + "_" + c.metric;
        let val = metrics[key];
        let pass = val <= c.limit;
        if !pass { ok = false; }
        let tag = if pass { "[PASS]" } else { "[CRITICAL]" };
        print(tag + " " + c.organ + " (" + c.metric + "): " + val + " " + c.unit + " <= " + c.limit + " " + c.unit);
    }

    // Target dose falloff steepness checks
    let cov_ok = ptv_coverage_pct >= 90.0;
    let ci_ok = conformity_index <= 1.20;
    let gi_ok = gradient_index <= 4.5;
    if !(cov_ok && ci_ok && gi_ok) { ok = false; }

    print((if cov_ok { "[PASS]" } else { "[FAIL]" }) + " PTV Coverage V_18Gy = " + ptv_coverage_pct + "% (>= 90%)");
    print((if ci_ok  { "[PASS]" } else { "[FAIL]" }) + " Paddick/RTOG Conformity Index = " + conformity_index + " (<= 1.20)");
    print((if gi_ok  { "[PASS]" } else { "[FAIL]" }) + " Gradient Index (R50%/R100%) = " + gradient_index + " (<= 4.50)");
    return ok;
}

let srs_metrics = #{
    "Partial Spinal Cord_D_0.035cc": 12.8,
    "Partial Spinal Cord_V_10Gy": 6.4,
    "Cauda Equina_D_0.035cc": 9.1,
    "Esophagus_D_0.035cc": 11.4,
    "Sacral Plexus_D_0.035cc": 4.2,
    "Kidney Cortex (Bil)_V_8.4Gy": 45.0
};

let status = validate_spine_srs(srs_metrics, 92.5, 1.09, 3.62);
print("-----------------------------------------------------------------");
print("RTOG-0631 Plan Clearance: " + if status { "CLEARED FOR TREATMENT" } else { "HOLD FOR PHYSICS REVIEW" });
print("=================================================================");
