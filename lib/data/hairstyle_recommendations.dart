class HairstyleRecommendations {
  static const Map<String, List<String>> _map = {
    'Oval|thick|Straight': ['pompadour', 'quiff', 'slick_back'],
    'Oval|thick|Wavy': ['textured_crop', 'comb_over', 'quiff'],
    'Oval|thick|curly': ['curly_top', 'undercut', 'faux_hawk'],
    'Oval|medium|Straight': ['side_part', 'french_crop', 'pompadour'],
    'Oval|medium|Wavy': ['side_part', 'textured_crop', 'quiff'],
    'Oval|medium|curly': ['curly_top', 'textured_crop', 'undercut'],
    'Oval|thin|Straight': ['side_part', 'french_crop', 'textured_crop'],
    'Oval|thin|Wavy': ['comb_over', 'textured_crop', 'side_part'],
    'Oval|thin|curly': ['curly_top', 'textured_crop', 'undercut'],
    'Round|thick|Straight': ['undercut', 'faux_hawk', 'buzz_cut'],
    'Round|thick|Wavy': ['faux_hawk', 'quiff', 'textured_crop'],
    'Round|thick|curly': ['curly_top', 'undercut', 'faux_hawk'],
    'Round|medium|Straight': ['quiff', 'slick_back', 'undercut'],
    'Round|medium|Wavy': ['side_part', 'textured_crop', 'quiff'],
    'Round|medium|curly': ['curly_top', 'undercut', 'textured_crop'],
    'Round|thin|Straight': ['side_part', 'comb_over', 'buzz_cut'],
    'Round|thin|Wavy': ['comb_over', 'side_part', 'textured_crop'],
    'Round|thin|curly': ['curly_top', 'undercut', 'textured_crop'],
    'Square|thick|Straight': ['buzz_cut', 'crew_cut', 'undercut'],
    'Square|thick|Wavy': ['textured_crop', 'faux_hawk', 'quiff'],
    'Square|thick|curly': ['curly_top', 'undercut', 'textured_crop'],
    'Square|medium|Straight': ['side_part', 'french_crop', 'slick_back'],
    'Square|medium|Wavy': ['textured_crop', 'side_part', 'quiff'],
    'Square|medium|curly': ['curly_top', 'textured_crop', 'undercut'],
    'Square|thin|Straight': ['textured_crop', 'french_crop', 'side_part'],
    'Square|thin|Wavy': ['textured_crop', 'comb_over', 'side_part'],
    'Square|thin|curly': ['curly_top', 'undercut', 'textured_crop'],
  };

  static List<String> get(
    String faceShape,
    String hairDensity,
    String hairType,
  ) {
    final key = '$faceShape|$hairDensity|$hairType';
    return _map[key] ??
        _map['$faceShape|$hairDensity'] ??
        const ['No Recommendation'];
  }
}
