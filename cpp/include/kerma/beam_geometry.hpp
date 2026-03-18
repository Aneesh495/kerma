#ifndef KERMA_BEAM_GEOMETRY_HPP
#define KERMA_BEAM_GEOMETRY_HPP

#include <vector>
#include <array>
#include <cmath>

namespace kerma {

struct Vec3 {
    float x = 0.0f;
    float y = 0.0f;
    float z = 0.0f;

    Vec3 operator+(const Vec3& o) const { return {x + o.x, y + o.y, z + o.z}; }
    Vec3 operator-(const Vec3& o) const { return {x - o.x, y - o.y, z - o.z}; }
    Vec3 operator*(float s) const { return {x * s, y * s, z * s}; }
    [[nodiscard]] float dot(const Vec3& o) const { return x * o.x + y * o.y + z * o.z; }
    [[nodiscard]] Vec3 cross(const Vec3& o) const {
        return {
            y * o.z - z * o.y,
            z * o.x - x * o.z,
            x * o.y - y * o.x
        };
    }
    [[nodiscard]] float length() const { return std::sqrt(dot(*this)); }
    [[nodiscard]] Vec3 normalized() const {
        float l = length();
        return (l > 1.0e-6f) ? (*this * (1.0f / l)) : Vec3{};
    }
};

struct BeamParameters {
    Vec3 isocenter_mm{0.0f, 0.0f, 0.0f};
    float gantry_angle_deg = 0.0f;     // Gantry rotation (0 to 360 deg)
    float collimator_angle_deg = 0.0f; // Collimator rotation
    float couch_angle_deg = 0.0f;      // Couch yaw
    float sad_mm = 1000.0f;            // Source-Axis Distance
    float jaw_x1_mm = -50.0f;          // Asymmetric jaws at isocenter
    float jaw_x2_mm =  50.0f;
    float jaw_y1_mm = -50.0f;
    float jaw_y2_mm =  50.0f;
    float monitor_units = 100.0f;
    float nominal_mv = 6.0f;

    std::vector<std::pair<float, float>> mlc_leaves; // (bank_a, bank_b) for each leaf
};

/**
 * Computes source focal position in patient world coordinates based on IEC 61217 angles.
 */
Vec3 compute_source_world_position(const BeamParameters& beam);

/**
 * Determines whether a given 3D point projects inside the collimator jaw aperture.
 */
bool is_point_in_field_aperture(const Vec3& point_mm, const BeamParameters& beam);

} // namespace kerma

#endif // KERMA_BEAM_GEOMETRY_HPP
