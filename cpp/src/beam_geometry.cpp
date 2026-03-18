#include "kerma/beam_geometry.hpp"
#include <cmath>

namespace kerma {

constexpr float PI_F = 3.14159265358979323846f;
constexpr float DEG_TO_RAD_F = PI_F / 180.0f;

Vec3 compute_source_world_position(const BeamParameters& beam) {
    float g_rad = beam.gantry_angle_deg * DEG_TO_RAD_F;
    float c_rad = beam.couch_angle_deg * DEG_TO_RAD_F;

    // Gantry rotation around Y axis in room frame
    // At gantry = 0 deg, source is at (0, 0, -SAD) aimed along +Z towards isocenter
    float cos_g = std::cos(g_rad);
    float sin_g = std::sin(g_rad);

    Vec3 pos_room{
        -beam.sad_mm * sin_g,
        0.0f,
        -beam.sad_mm * cos_g
    };

    // Couch rotation around patient superior-inferior axis
    float cos_c = std::cos(c_rad);
    float sin_c = std::sin(c_rad);

    Vec3 pos_couch{
        pos_room.x * cos_c - pos_room.y * sin_c,
        pos_room.x * sin_c + pos_room.y * cos_c,
        pos_room.z
    };

    return beam.isocenter_mm + pos_couch;
}

bool is_point_in_field_aperture(const Vec3& point_mm, const BeamParameters& beam) {
    Vec3 source_pos = compute_source_world_position(beam);
    Vec3 ray = point_mm - source_pos;
    float dist = ray.length();
    if (dist < 1.0e-3f) return false;

    // Project onto isocenter plane at SAD
    float g_rad = beam.gantry_angle_deg * DEG_TO_RAD_F;
    float cos_g = std::cos(g_rad);
    float sin_g = std::sin(g_rad);

    // Transform point to canonical BEV coordinate system
    Vec3 d = point_mm - beam.isocenter_mm;
    float bev_x =  d.x * cos_g - d.z * sin_g;
    float bev_y =  d.y;
    float bev_z =  d.x * sin_g + d.z * cos_g; // Z along beam axis from isocenter

    float z_from_source = beam.sad_mm + bev_z;
    if (z_from_source <= 10.0f) return false;

    float scale = beam.sad_mm / z_from_source;
    float u_mm = bev_x * scale;
    float v_mm = bev_y * scale;

    // Check collimator rotation
    if (std::abs(beam.collimator_angle_deg) > 1.0e-3f) {
        float coll_rad = beam.collimator_angle_deg * DEG_TO_RAD_F;
        float cos_c = std::cos(coll_rad);
        float sin_c = std::sin(coll_rad);
        float u_rot =  u_mm * cos_c + v_mm * sin_c;
        float v_rot = -u_mm * sin_c + v_mm * cos_c;
        u_mm = u_rot;
        v_mm = v_rot;
    }

    // Jaw clipping check
    return (u_mm >= beam.jaw_x1_mm && u_mm <= beam.jaw_x2_mm &&
            v_mm >= beam.jaw_y1_mm && v_mm <= beam.jaw_y2_mm);
}

} // namespace kerma
