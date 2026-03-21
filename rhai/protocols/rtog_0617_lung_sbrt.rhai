// Kerma Radiation Oncology Simulation Engine
// Clinical Protocol: RTOG 0813 / 0617 Lung SBRT Verification Protocol

let protocol_name = "RTOG-0813 Lung SBRT";
let prescription_dose_gy = 54.0;
let fraction_count = 3;
let dose_per_fraction = prescription_dose_gy / fraction_count;

// Print protocol header
print("=================================================================");
print("CLINICAL PROTOCOL AUDIT: " + protocol_name);
print("Prescription: " + prescription_dose_gy + " Gy in " + fraction_count + " fractions (" + dose_per_fraction + " Gy/fx)");
print("=================================================================");

// Clinical constraints table
let constraints = [
    #{ organ: "Spinal Cord",   metric: "D_max", limit: 18.0, unit: "Gy" },
    #{ organ: "Esophagus",     metric: "D_max", limit: 27.0, unit: "Gy" },
    #{ organ: "Trachea / Tree",metric: "D_max", limit: 30.0, unit: "Gy" },
    #{ organ: "Heart",         metric: "V_30",  limit: 15.0, unit: "cc" },
    #{ organ: "Total Lung-GTV",metric: "V_20",  limit: 10.0, unit: "%" },
    #{ organ: "Chest Wall",    metric: "V_30",  limit: 30.0, unit: "cc" }
];

fn evaluate_organ_constraints(plan_metrics) {
    let all_passed = true;
    for c in constraints {
        let organ = c.organ;
        let metric = c.metric;
        let limit = c.limit;
        let val = plan_metrics[organ];
        
        let pass = val <= limit;
        if !pass {
            all_passed = false;
        }
        let status = if pass { "[PASS]" } else { "[VIOLATION]" };
        print(status + " " + organ + " (" + metric + "): " + val + " " + c.unit + " (Limit: <= " + limit + " " + c.unit + ")");
    }
    return all_passed;
}

// Sample clinical trial audit test
let sample_plan = #{
    "Spinal Cord": 14.2,
    "Esophagus": 22.8,
    "Trachea / Tree": 26.5,
    "Heart": 8.4,
    "Total Lung-GTV": 7.8,
    "Chest Wall": 18.2
};

let result = evaluate_organ_constraints(sample_plan);
print("-----------------------------------------------------------------");
print("Overall Protocol Compliance: " + if result { "APPROVED" } else { "REJECTED" });
print("=================================================================");
