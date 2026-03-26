# Medical Physics and Engineering Standards Compliance

Kerma is designed to adhere to professional guidelines and international standards established across radiation oncology and medical physics:

## 1. American Association of Physicists in Medicine (AAPM)

- **AAPM TG-43 / TG-43U1**: Standardized specification of brachytherapy dosimetry parameters for line and point sources, including air-kerma strength S_K, dose rate constant Lambda, radial dose function g(r), and 2D anisotropy function F(r, theta).
- **AAPM TG-51**: Protocol for clinical reference dosimetry of high-energy photon and electron beams using calibrated ionization chambers at reference depth d_max.
- **AAPM TG-142**: Quality assurance of medical linear accelerators, including dynamic multileaf collimator positional accuracy (<= 1.0 mm) and beam flatness / symmetry tolerances (<= 2%).
- **AAPM TG-218**: Tolerance limits and methodologies for IMRT / VMAT measurement-based verification, establishing standard criteria:
  - Universal tolerance limit: 3% dose difference / 3 mm distance-to-agreement (DTA) with 10% low-dose threshold suppression, requiring >= 95% gamma passing rate.
  - Strict tolerance limit: 2% dose difference / 2 mm DTA with >= 90% gamma passing rate.

## 2. International Commission on Radiation Units and Measurements (ICRU)

- **ICRU Report 50 & 62**: Prescribing, recording, and reporting photon beam therapy:
  - Gross Tumor Volume (GTV)
  - Clinical Target Volume (CTV)
  - Planning Target Volume (PTV)
  - Internal Margin (IM) and Set-up Margin (SM)
- **ICRU Report 83**: Prescribing, recording, and reporting intensity-modulated photon-beam therapy (IMRT):
  - Standardized DVH metric reporting: D98 (near-minimum dose), D50 (median dose), D2 (near-maximum dose).
  - Homogeneity Index: HI = (D2 - D98) / D50.

## 3. International Electrotechnical Commission (IEC)

- **IEC 61217**: Radiotherapy equipment: coordinates, movements, and scales:
  - Standardized definitions of gantry, collimator, table (couch), wedge, and patient coordinate systems.
  - Directional sign conventions for gantry rotation (clockwise looking from front) and couch yaw.
