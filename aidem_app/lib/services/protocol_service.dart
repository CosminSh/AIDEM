import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/protocol.dart';

class ProtocolService {
  Map<String, ProtocolNode> _nodes = {};
  Map<String, String> _knowledgeBase = {};
  bool _isLoaded = false;

  bool get isLoaded => _isLoaded;

  Future<void> loadProtocol() async {
    if (_isLoaded) return;

    try {
      // Load protocol tree
      final String jsonString = await rootBundle.loadString(
        'assets/data/protocol.json',
      );
      final Map<String, dynamic> jsonData = json.decode(jsonString);
      final Map<String, dynamic> nodesJson = jsonData['nodes'];

      _nodes = nodesJson.map(
        (key, value) =>
            MapEntry(key, ProtocolNode.fromJson(value as Map<String, dynamic>)),
      );

      // Load knowledge base
      final String kbString = await rootBundle.loadString(
        'assets/data/knowledge_base.json',
      );
      final Map<String, dynamic> kbData = json.decode(kbString);
      _knowledgeBase = kbData.map((k, v) => MapEntry(k, v.toString()));

      _isLoaded = true;
    } catch (e) {
      print('Error loading protocol: $e');
      rethrow;
    }
  }

  ProtocolNode? getNode(String id) => _nodes[id];

  ProtocolNode get startNode => _nodes['start']!;

  /// Returns relevant documentation for the current protocol node.
  /// Walks up related nodes to gather context (e.g. bleeding_protocol
  /// also returns injury_assessment context).
  String getDocumentationForNode(String nodeId) {
    final buffer = StringBuffer();

    // Primary match
    if (_knowledgeBase.containsKey(nodeId)) {
      buffer.writeln(_knowledgeBase[nodeId]);
    }

    // Related protocol context
    final related = _relatedNodes[nodeId] ?? [];
    for (final relId in related) {
      if (_knowledgeBase.containsKey(relId)) {
        buffer.writeln();
        buffer.writeln(_knowledgeBase[relId]);
      }
    }

    return buffer.toString().trim();
  }

  /// Maps each node to related nodes whose documentation is also relevant.
  static final Map<String, List<String>> _relatedNodes = {
    'start': ['triage_selection', 'lost_protocol', 'disaster_selection'],
    'injury_assessment': ['clean_wound', 'evacuation_triage'],
    'bleeding_protocol': ['injury_assessment'],
    'clean_wound': ['injury_assessment', 'evacuation_triage'],
    'apply_tourniquet': ['bleeding_protocol'],
    'pressure_dressing': ['bleeding_protocol'],
    'lost_protocol': ['signaling_protocol', 'shelter_protocol'],
    'signaling_protocol': ['lost_protocol', 'signal_ground_to_air'],
    'anaphylaxis_protocol': ['triage_selection', 'allergic_triage'],
    'snake_bite_protocol': ['triage_selection'],
    'heat_stroke': ['heat_protocol'],
    'thermal_burn': ['burn_protocol'],
    'chemical_burn': ['burn_protocol'],
    'electrical_burn': ['burn_protocol'],
    'sunburn_protocol': ['burn_protocol'],
    'eye_injury_protocol': ['triage_selection'],
    'chemical_eye_splash': ['eye_injury_protocol'],
    'foreign_object_eye': ['eye_injury_protocol'],
    'snow_blindness': ['eye_injury_protocol'],
    'dental_emergency_protocol': ['triage_selection'],
    'broken_tooth': ['dental_emergency_protocol'],
    'lost_filling_crown': ['dental_emergency_protocol'],
    'dental_abscess': ['dental_emergency_protocol'],
    'avulsed_tooth': ['dental_emergency_protocol'],
    'splint_protocol': ['fracture_sprain_protocol', 'triage_selection'],
    'improvised_splinting': ['splint_protocol'],
    'blister_management_protocol': ['triage_selection'],
    'how_to_drain_blister': ['blister_management_protocol'],
    'blister_padding': ['blister_management_protocol'],
    'blister_infection_watch': ['blister_management_protocol'],
    'allergic_triage': ['triage_selection'],
    'mild_allergic_reaction': ['allergic_triage'],
    'nosebleed_protocol': ['triage_selection'],
    'ear_bleed_protocol': ['triage_selection', 'concussion_protocol'],
    'heart_attack_protocol': ['triage_selection', 'drowning_cpr_protocol'],
    'diabetic_triage': ['triage_selection'],
    'hypoglycemia_management': ['diabetic_triage'],
    'hyperglycemia_management': ['diabetic_triage'],
    'stroke_protocol': ['triage_selection', 'vitals_triage'],
    'stroke_fast_check': ['stroke_protocol'],
    'asthma_breathing_protocol': ['triage_selection', 'vitals_triage'],
    'asthma_inhaler_steps': ['asthma_breathing_protocol'],
    'opioid_overdose_protocol': ['poisoning_protocol', 'drowning_cpr_protocol'],
    'naloxone_steps': ['opioid_overdose_protocol', 'vitals_triage'],
    'pregnancy_labor_protocol': ['triage_selection', 'vitals_triage'],
    'imminent_birth_steps': ['pregnancy_labor_protocol'],
    'newborn_immediate_care': ['pregnancy_labor_protocol', 'vitals_triage'],
    'mental_health_crisis_protocol': ['panic_triage', 'rescue_call'],
    'mental_health_stabilize': ['mental_health_crisis_protocol'],
    'mass_casualty_triage': ['triage_selection', 'evacuation_triage'],
    'seizure_protocol': ['triage_selection'],
    'seizure_recovery': ['seizure_protocol'],
    'seizure_rescue_criteria': ['seizure_protocol'],
    'fire_starting_protocol': ['triage_selection'],
    'fire_ignition_selection': ['fire_starting_protocol'],
    'fire_layout_selection': ['fire_starting_protocol'],
    'fire_skills': ['fire_starting_protocol'],
    'fire_starting_methods': ['fire_starting_protocol'],
    'fire_structure': ['fire_starting_protocol'],
    'rope_knot_protocol': ['triage_selection'],
    'rope_knot_skills': ['rope_knot_protocol'],
    'improvised_cordage': ['rope_knot_protocol'],
    'signaling_improv_protocol': ['triage_selection'],
    'visual_signal_triage': ['signaling_improv_protocol'],
    'signaling_improvisation': ['visual_signal_triage'],
    'ground_to_air_codes': ['visual_signal_triage'],
    'whistle_alternatives': ['signaling_improv_protocol'],
    'animal_hazard_triage': ['triage_selection'],
    'bear_encounter_protocol': ['animal_hazard_triage'],
    'wolf_encounter_protocol': ['animal_hazard_triage'],
    'boar_encounter_protocol': ['animal_hazard_triage'],
    'river_crossing_protocol': ['triage_selection'],
    'water_rescue_swimming': ['river_crossing_protocol'],
    'avalanche_triage': ['triage_selection'],
    'avalanche_survival_protocol': ['avalanche_triage'],
    'avalanche_rescue_steps': ['avalanche_triage'],
    'navigation_selection': ['triage_selection'],
    'watch_compass_method': ['navigation_selection'],
    'polaris_info': ['navigation_selection'],
    'terrain_features_guide': ['navigation_selection'],
    'pace_counting_guide': ['navigation_selection'],
    'ranger_beads_tracking': ['navigation_selection'],
    'tsunami_protocol': ['disaster_selection'],
    'tsunami_warning_signs': ['tsunami_protocol'],
    'nuclear_radiation_protocol': ['disaster_selection'],
    'radiation_triage': ['nuclear_radiation_protocol'],
    'radiation_decontamination': ['radiation_triage'],
    'power_outage_protocol': ['disaster_selection', 'carbon_monoxide_protocol'],
    'power_medical_device_plan': ['power_outage_protocol', 'rescue_call'],
    'gas_co_triage': ['disaster_selection'],
    'carbon_monoxide_protocol': ['gas_co_triage', 'poisoning_protocol'],
    'gas_leak_protocol': ['gas_co_triage'],
    'chemical_spill_protocol': ['disaster_selection', 'poisoning_protocol'],
    'infectious_disease_protocol': ['disaster_selection', 'vitals_triage'],
    'infection_control_steps': ['infectious_disease_protocol'],
    'civil_unrest_protocol': ['disaster_selection'],
    'urban_emergency_safety': ['civil_unrest_protocol'],
    'lightning_survival_protocol': ['disaster_selection'],
    'lightning_triage': ['lightning_survival_protocol'],
    'lightning_crouch_myth': ['lightning_survival_protocol'],
    'landslide_mudslide_protocol': ['disaster_selection'],
    'landslide_triage': ['landslide_mudslide_protocol'],
    'landslide_warning_signs': ['landslide_mudslide_protocol'],
    'hypothermia_prevention_triage': ['skills_selection'],
    'hypothermia_prevention_cold': ['hypothermia_prevention_triage'],
    'layering_system_protocol': ['hypothermia_prevention_triage'],
    'water_purification_triage': ['water_skills'],
    'water_purification_detailed': ['water_purification_triage'],
    'water_disinfection_safety': ['water_purification_detailed'],
    'infection_triage': ['triage_selection'],
    'wound_infection_monitoring': ['infection_triage'],
    'infection_treatment_wfa': ['infection_triage'],
    'vitals_triage': ['triage_selection'],
    'patient_monitoring_vitals': ['vitals_triage'],
    'avpu_responsiveness_scale': ['vitals_triage'],
    'evacuation_triage': ['rescue_call'],
    'evacuation_decision_logic': ['evacuation_triage'],
    'evacuation_vs_wait': ['evacuation_triage'],
    'panic_triage': ['start'],
    'stop_protocol': ['panic_triage'],
    'box_breathing_technique': ['panic_triage'],
    'hypothermia_protocol': ['shelter_protocol'],
    'concussion_protocol': ['spinal_protocol'],
    'rescue_call': ['signaling_protocol'],
    'earthquake_protocol': ['disaster_selection'],
    'flood_protocol': ['disaster_selection'],
    'wildfire_protocol': ['disaster_selection'],
    'storm_protocol': ['disaster_selection'],
    'poisoning_protocol': ['triage_selection'],
    'choking_protocol': ['triage_selection'],
    'drowning_cpr_protocol': ['triage_selection'],
    'tick_removal_protocol': ['triage_selection'],
    'frostbite_protocol': ['hypothermia_protocol'],
    'vehicle_emergency_protocol': ['signaling_protocol', 'lost_protocol'],
    'water_skills': ['skills_selection'],
    'food_skills': ['skills_selection'],
    'shelter_skills': ['skills_selection'],
    'nav_skills': ['skills_selection'],
    'solar_still_info': ['water_skills'],
    'transpiration_info': ['water_skills'],
    'finding_water_info': ['water_skills'],
    'edibility_test': ['food_skills'],
    'safe_plants_info': ['food_skills'],
    'avoid_plants_info': ['food_skills'],
    'snow_shelter': ['shelter_skills'],
    'desert_shelter': ['shelter_skills'],
    'shadow_tip_info': ['nav_skills'],
    'southern_cross_info': ['nav_skills'],
  };
}
