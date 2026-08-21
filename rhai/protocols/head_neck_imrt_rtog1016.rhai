// Kerma Radiation Oncology Simulation Engine
// Clinical Protocol: RTOG 1016 Head & Neck Simultaneous Integrated Boost (SIB) IMRT/VMAT

let protocol_name = "RTOG-1016 Oropharyngeal SIB-IMRT";
let fractions = 35;
let ptv_high_gy = 70.0;
let ptv_int_gy = 60.0;
let ptv_low_gy = 54.0;

print("=================================================================");
print("CLINICAL PROTOCOL AUDIT: " + protocol_name);
print("Prescription: " + ptv_high_gy + " / " + ptv_int_gy + " / " + ptv_low_gy + " Gy in " + fractions + " fractions");
print("=================================================================");

// Organ-At-Risk (OAR) Dose-Volume Constraints (QUANTEC / RTOG 1016)
let oar_constraints = [
    #{ organ: "Brainstem",       metric: "D_0.03cc", limit: 54.0, unit: "Gy" },
    #{ organ: "Spinal Cord",     metric: "D_0.03cc", limit: 45.0, unit: "Gy" },
    #{ organ: "Spinal Cord PRV", metric: "D_0.03cc", limit: 50.0, unit: "Gy" },
    #{ organ: "Parotid_L",       metric: "D_mean",   limit: 26.0, unit: "Gy" },
    #{ organ: "Parotid_R",       metric: "D_mean",   limit: 26.0, unit: "Gy" },
    #{ organ: "Larynx",          metric: "D_mean",   limit: 40.0, unit: "Gy" },
    #{ organ: "Mandible",        metric: "D_max",    limit: 70.0, unit: "Gy" },
    #{ organ: "Optic Chiasm",    metric: "D_max",    limit: 54.0, unit: "Gy" }
];

// Target coverage criteria (V_100% >= 95%, D_0.03cc <= 107% of PTV_High)
fn check_target_coverage(ptv_high_v95_gy, ptv_high_dmax_gy) {
    let min_coverage = 0.95 * ptv_high_gy;
    let max_hotspot = 1.07 * ptv_high_gy;
    let pass_cov = ptv_high_v95_gy >= min_coverage;
    let pass_hot = ptv_high_dmax_gy <= max_hotspot;
    print((if pass_cov { "[PASS]" } else { "[FAIL]" }) + " PTV_70 D95 = " + ptv_high_v95_gy + " Gy (Req >= " + min_coverage + " Gy)");
    print((if pass_hot { "[PASS]" } else { "[FAIL]" }) + " PTV_70 D_max = " + ptv_high_dmax_gy + " Gy (Req <= " + max_hotspot + " Gy)");
    return pass_cov && pass_hot;
}

fn audit_sib_plan(oar_metrics, ptv_d95, ptv_dmax) {
    let targets_ok = check_target_coverage(ptv_d95, ptv_dmax);
    let oars_ok = true;

    for c in oar_constraints {
        let val = oar_metrics[c.organ];
        let pass = val <= c.limit;
        if !pass {
            oars_ok = false;
        }
        let tag = if pass { "[PASS]" } else { "[VIOLATION]" };
        print(tag + " " + c.organ + " (" + c.metric + "): " + val + " " + c.unit + " (Limit <= " + c.limit + " " + c.unit + ")");
    }
    return targets_ok && oars_ok;
}

let candidate_oars = #{
    "Brainstem": 48.2,
    "Spinal Cord": 39.4,
    "Spinal Cord PRV": 44.1,
    "Parotid_L": 24.3,
    "Parotid_R": 22.8,
    "Larynx": 35.6,
    "Mandible": 68.5,
    "Optic Chiasm": 12.1
};

let compliant = audit_sib_plan(candidate_oars, 68.4, 73.2);
print("-----------------------------------------------------------------");
print("RTOG-1016 Protocol Determination: " + if compliant { "APPROVED" } else { "RE-OPTIMIZE" });
print("=================================================================");
