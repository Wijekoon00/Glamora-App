// =============================================================================
// Style Recommendation Engine
// A multi-factor rule-based system that combines face shape, hair type,
// occasion, style preference, and gender to produce accurate recommendations.
// =============================================================================

// ─── Input profile from the user ─────────────────────────────────────────────
class StyleProfile {
  final String faceShape;       // Oval / Round / Square / Heart / Oblong
  final String hairType;        // Straight / Wavy / Curly / Thick / Thin / Unknown
  final String occasion;        // Casual / Wedding / Party / Office / Photoshoot
  final String stylePreference; // Natural / Modern / Elegant / Bold / Simple
  final String gender;          // Male / Female / Any
  final Map<String, double> measurements; // raw face ratios from ML Kit

  const StyleProfile({
    required this.faceShape,
    this.hairType = 'Unknown',
    this.occasion = 'Casual',
    this.stylePreference = 'Natural',
    this.gender = 'Any',
    this.measurements = const {},
  });
}

// ─── Output recommendation ────────────────────────────────────────────────────
class StyleRecommendation {
  final String hairstyle;
  final String beard;
  final String hairColor;
  final String reasonHairstyle;
  final String reasonBeard;
  final String reasonColor;
  final List<String> alternativeStyles;
  final List<String> avoidStyles;       // what NOT to do — adds credibility
  final String careAdvice;              // maintenance tip
  final String occasionNote;            // occasion-specific note
  final int confidenceScore;            // 0–100 how confident the engine is

  const StyleRecommendation({
    required this.hairstyle,
    required this.beard,
    required this.hairColor,
    required this.reasonHairstyle,
    required this.reasonBeard,
    required this.reasonColor,
    required this.alternativeStyles,
    required this.avoidStyles,
    required this.careAdvice,
    required this.occasionNote,
    required this.confidenceScore,
  });
}

// =============================================================================
// The Engine
// =============================================================================
class StyleRecommendationEngine {

  static StyleRecommendation recommend(StyleProfile profile) {
    final shape = profile.faceShape.toLowerCase();
    final hair  = profile.hairType.toLowerCase();
    final occ   = profile.occasion.toLowerCase();
    final style = profile.stylePreference.toLowerCase();
    final gen   = profile.gender.toLowerCase();

    // Step 1 — base recommendation from face shape
    final base = _baseFromFaceShape(shape);

    // Step 2 — refine hairstyle based on hair type
    final refinedHair = _refineForHairType(base.hairstyle, hair, shape);

    // Step 3 — refine for occasion
    final occasionNote = _occasionNote(occ, shape, hair);
    final occasionHair = _refineForOccasion(refinedHair, occ, style);

    // Step 4 — refine beard for gender + occasion
    final refinedBeard = _refineBeard(base.beard, gen, occ, shape);

    // Step 5 — refine color for hair type + occasion + style
    final refinedColor = _refineColor(base.hairColor, hair, occ, style, shape);
    final colorReason  = _colorReason(refinedColor, shape, hair, style);

    // Step 6 — care advice based on hair type
    final care = _careAdvice(hair, occasionHair);

    // Step 7 — confidence score based on how many factors matched
    final confidence = _calculateConfidence(profile);

    // Step 8 — avoid list (what NOT to do)
    final avoid = _avoidList(shape, hair);

    return StyleRecommendation(
      hairstyle:        occasionHair,
      beard:            refinedBeard,
      hairColor:        refinedColor,
      reasonHairstyle:  _hairstyleReason(occasionHair, shape, hair),
      reasonBeard:      _beardReason(refinedBeard, shape, gen),
      reasonColor:      colorReason,
      alternativeStyles: _alternatives(shape, hair, occ, style, gen),
      avoidStyles:      avoid,
      careAdvice:       care,
      occasionNote:     occasionNote,
      confidenceScore:  confidence,
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // STEP 1 — Base recommendation from face shape alone
  // ───────────────────────────────────────────────────────────────────────────
  static _Base _baseFromFaceShape(String shape) {
    switch (shape) {
      case 'oval':
        return _Base(
          hairstyle: 'Textured Layers',
          beard: 'Short Boxed Beard',
          hairColor: 'Warm Caramel',
        );
      case 'round':
        return _Base(
          hairstyle: 'High Fade with Volume on Top',
          beard: 'Goatee',
          hairColor: 'Dark Chocolate',
        );
      case 'square':
        return _Base(
          hairstyle: 'Soft Waves',
          beard: 'Light Stubble',
          hairColor: 'Soft Blonde',
        );
      case 'heart':
        return _Base(
          hairstyle: 'Side Swept Layers',
          beard: 'Full Beard',
          hairColor: 'Honey Blonde',
        );
      case 'oblong':
      case 'oblong / long':
        return _Base(
          hairstyle: 'Medium Layers with Volume',
          beard: 'Wide Full Beard',
          hairColor: 'Balayage',
        );
      default:
        return _Base(
          hairstyle: 'Layered Cut',
          beard: 'Medium Stubble',
          hairColor: 'Natural Brown',
        );
    }
  }

  // ───────────────────────────────────────────────────────────────────────────
  // STEP 2 — Refine hairstyle based on hair type
  // Hair type is a major factor — curly hair behaves completely differently
  // from straight hair even on the same face shape.
  // ───────────────────────────────────────────────────────────────────────────
  static String _refineForHairType(String base, String hair, String shape) {
    switch (hair) {
      case 'straight':
        // Straight hair holds structure well — precision cuts work great
        if (shape == 'round')  return 'High Fade with Slick Back';
        if (shape == 'square') return 'Side Part with Taper Fade';
        if (shape == 'oval')   return 'Undercut with Textured Top';
        if (shape == 'heart')  return 'Side Swept with Taper';
        if (shape == 'oblong') return 'Blunt Bob or Curtain Bangs';
        return 'Classic Taper Cut';

      case 'wavy':
        // Wavy hair adds natural volume — use it to your advantage
        if (shape == 'round')  return 'Wavy Quiff with Fade';
        if (shape == 'square') return 'Tousled Waves with Side Part';
        if (shape == 'oval')   return 'Textured Wavy Layers';
        if (shape == 'heart')  return 'Wavy Lob (Long Bob)';
        if (shape == 'oblong') return 'Wavy Bob with Volume on Sides';
        return 'Textured Wavy Cut';

      case 'curly':
        // Curly hair adds width — great for oblong/heart, needs control for round
        if (shape == 'round')  return 'Curly Frohawk (height, not width)';
        if (shape == 'square') return 'Loose Curls with Soft Fringe';
        if (shape == 'oval')   return 'Natural Curly Layers';
        if (shape == 'heart')  return 'Curly Lob with Volume at Chin';
        if (shape == 'oblong') return 'Full Curly Afro or Curly Bob';
        return 'Natural Curl Definition Cut';

      case 'thick':
        // Thick hair needs thinning and layering to avoid bulk
        if (shape == 'round')  return 'Layered Fade (removes bulk on sides)';
        if (shape == 'square') return 'Textured Layers with Thinning';
        if (shape == 'oval')   return 'Long Layers with Thinning';
        if (shape == 'heart')  return 'Layered Cut with Thinned Ends';
        if (shape == 'oblong') return 'Thick Bob with Layers';
        return 'Layered Cut with Thinning Shears';

      case 'thin':
        // Thin hair needs volume — avoid heavy styles that flatten it
        if (shape == 'round')  return 'Volumizing Blowout with Fade';
        if (shape == 'square') return 'Textured Crop (adds volume)';
        if (shape == 'oval')   return 'Voluminous Layers';
        if (shape == 'heart')  return 'Wispy Layers with Volume';
        if (shape == 'oblong') return 'Shoulder Length with Layers';
        return 'Volumizing Layered Cut';

      default:
        return base;
    }
  }

  // ───────────────────────────────────────────────────────────────────────────
  // STEP 3 — Refine for occasion + style preference
  // ───────────────────────────────────────────────────────────────────────────
  static String _refineForOccasion(String base, String occ, String style) {
    switch (occ) {
      case 'wedding':
        if (style == 'elegant') return 'Elegant Updo / Bridal Waves';
        if (style == 'modern')  return 'Sleek Low Bun or Polished Blowout';
        if (style == 'bold')    return 'Dramatic Updo with Accessories';
        return 'Classic Bridal Style';

      case 'office':
        if (style == 'bold')    return '$base (toned down for office)';
        if (style == 'elegant') return 'Polished ${base.split(' ').first} Style';
        return 'Clean Professional $base';

      case 'party':
        if (style == 'bold')    return 'Statement $base with Highlights';
        if (style == 'modern')  return 'Edgy $base';
        return 'Styled $base';

      case 'photoshoot':
        if (style == 'bold')    return 'High-Fashion $base';
        if (style == 'elegant') return 'Editorial $base';
        return 'Camera-Ready $base';

      case 'casual':
      default:
        if (style == 'simple')  return base.split(' ').take(3).join(' ');
        return base;
    }
  }

  // ───────────────────────────────────────────────────────────────────────────
  // STEP 4 — Beard refinement (gender + occasion + face shape)
  // ───────────────────────────────────────────────────────────────────────────
  static String _refineBeard(String base, String gen, String occ, String shape) {
    // Female / Any — return feminine equivalent
    if (gen == 'female') {
      return 'N/A — Focus on jawline contouring makeup';
    }

    // Occasion overrides
    if (occ == 'wedding') {
      if (shape == 'round')  return 'Neatly Trimmed Goatee';
      if (shape == 'square') return 'Clean Shave or Light Stubble';
      if (shape == 'oval')   return 'Well-Groomed Short Beard';
      return 'Neatly Groomed Beard';
    }

    if (occ == 'office') {
      if (base.contains('Full')) return 'Neatly Trimmed Full Beard';
      return 'Clean Stubble or Clean Shave';
    }

    // Face shape specific refinements
    switch (shape) {
      case 'round':
        // Need vertical lines to elongate — goatee is best
        if (occ == 'casual') return 'Goatee or Extended Goatee';
        return 'Chin Strap Beard';

      case 'square':
        // Soften the jaw — avoid heavy jaw beards
        return 'Light Stubble (3–5 day)';

      case 'heart':
        // Add width to chin — fuller beard helps
        return 'Full Beard or Chin Curtain';

      case 'oblong':
      case 'oblong / long':
        // Add width — wide beard balances length
        return 'Wide Full Beard or Mutton Chops';

      case 'oval':
        // Most styles work — match to occasion
        if (occ == 'party') return 'Styled Short Beard';
        return 'Short Boxed Beard';

      default:
        return base;
    }
  }

  // ───────────────────────────────────────────────────────────────────────────
  // STEP 5 — Hair color refinement
  // Considers: hair type (some colors damage thin hair), occasion, style, shape
  // ───────────────────────────────────────────────────────────────────────────
  static String _refineColor(
      String base, String hair, String occ, String style, String shape) {

    // Thin hair — avoid bleach-heavy processes that damage
    if (hair == 'thin') {
      if (style == 'bold') return 'Subtle Highlights (gentle on thin hair)';
      return 'Natural Brown or Dark Blonde (no bleach needed)';
    }

    // Curly hair — color enhances curl definition
    if (hair == 'curly') {
      if (style == 'bold')    return 'Rich Mahogany or Deep Auburn';
      if (style == 'natural') return 'Natural Black or Dark Brown';
      return 'Warm Auburn or Chestnut Brown';
    }

    // Occasion-based color
    if (occ == 'wedding') {
      if (style == 'elegant') return 'Rich Chocolate Brown or Champagne Blonde';
      return 'Natural Warm Tones';
    }

    if (occ == 'party' && style == 'bold') {
      return 'Bold Highlights or Fashion Color Streaks';
    }

    if (occ == 'office') {
      return 'Natural Brown, Dark Blonde, or Black';
    }

    // Style preference
    if (style == 'bold')    return 'Platinum Blonde or Vivid Highlights';
    if (style == 'elegant') return 'Rich Brunette or Champagne Blonde';
    if (style == 'modern')  return 'Ash Brown or Cool Blonde';
    if (style == 'simple')  return 'Natural Brown or Black';

    // Face shape color logic
    switch (shape) {
      case 'round':  return 'Dark Chocolate or Ash Brown';
      case 'square': return 'Soft Blonde or Light Ash';
      case 'heart':  return 'Honey Blonde or Auburn';
      case 'oblong': return 'Balayage or Two-Tone';
      case 'oval':   return 'Warm Caramel or Natural Brown';
      default:       return base;
    }
  }

  // ───────────────────────────────────────────────────────────────────────────
  // STEP 6 — Care advice based on hair type
  // ───────────────────────────────────────────────────────────────────────────
  static String _careAdvice(String hair, String hairstyle) {
    switch (hair) {
      case 'curly':
        return 'Use a sulfate-free shampoo and curl-defining cream. '
            'Diffuse dry instead of towel drying to preserve curl shape. '
            'Deep condition weekly.';
      case 'thin':
        return 'Use a volumizing shampoo and lightweight conditioner. '
            'Avoid heavy oils near the roots. '
            'Blow dry with a round brush for lift.';
      case 'thick':
        return 'Use a moisturizing shampoo and regular deep conditioning. '
            'Ask your stylist for thinning shears to reduce bulk. '
            'Anti-frizz serum helps on humid days.';
      case 'wavy':
        return 'Use a wave-enhancing mousse while hair is damp. '
            'Scrunch dry or diffuse — avoid brushing when dry. '
            'Refresh waves with a water spray bottle.';
      case 'straight':
        return 'Use a smoothing shampoo to maintain shine. '
            'A heat protectant is essential before styling. '
            'Trim every 6–8 weeks to prevent split ends.';
      default:
        return 'Use products suited to your hair type. '
            'Regular trims every 6–8 weeks keep the style fresh. '
            'Protect hair from heat with a quality heat protectant.';
    }
  }

  // ───────────────────────────────────────────────────────────────────────────
  // STEP 7 — Confidence score
  // Higher when more specific inputs are provided
  // ───────────────────────────────────────────────────────────────────────────
  static int _calculateConfidence(StyleProfile profile) {
    int score = 50; // base from face shape detection

    if (profile.hairType != 'Unknown') score += 15;
    if (profile.occasion != 'Casual')  score += 10;
    if (profile.stylePreference != 'Natural') score += 10;
    if (profile.gender != 'Any')       score += 10;
    if (profile.measurements.isNotEmpty) score += 5;

    return score.clamp(0, 100);
  }

  // ───────────────────────────────────────────────────────────────────────────
  // STEP 8 — Avoid list (what NOT to do for this face shape)
  // ───────────────────────────────────────────────────────────────────────────
  static List<String> _avoidList(String shape, String hair) {
    final List<String> avoid = [];

    switch (shape) {
      case 'round':
        avoid.addAll([
          'Bowl cuts (add width)',
          'Very short all-over cuts',
          'Heavy side parts that widen the face',
        ]);
        break;
      case 'square':
        avoid.addAll([
          'Blunt straight fringes (emphasize squareness)',
          'Very short sides with flat top',
          'Heavy jaw-line beards',
        ]);
        break;
      case 'heart':
        avoid.addAll([
          'Very voluminous top styles (widen forehead further)',
          'Chin-length blunt bobs (emphasize narrow chin)',
          'Heavy fringes',
        ]);
        break;
      case 'oblong':
      case 'oblong / long':
        avoid.addAll([
          'Very long straight styles (add length)',
          'High pompadours or quiffs',
          'Centre parts with no volume on sides',
        ]);
        break;
      case 'oval':
        avoid.addAll([
          'Styles that hide your balanced features',
          'Extremely heavy fringes',
        ]);
        break;
    }

    // Hair type specific avoids
    if (hair == 'thin') {
      avoid.add('Heavy layering that removes volume');
      avoid.add('Very long styles that weigh hair down');
    }
    if (hair == 'curly') {
      avoid.add('Brushing dry curls (causes frizz)');
      avoid.add('Very short cuts that cause shrinkage');
    }
    if (hair == 'thick') {
      avoid.add('One-length blunt cuts (too heavy)');
    }

    return avoid;
  }

  // ───────────────────────────────────────────────────────────────────────────
  // STEP 9 — Alternatives list
  // Varies by face shape + hair type + occasion + style + gender
  // ───────────────────────────────────────────────────────────────────────────
  static List<String> _alternatives(
      String shape, String hair, String occ, String style, String gen) {

    // Build a pool of alternatives based on face shape
    final Map<String, List<String>> pool = {
      'oval': [
        'Pompadour', 'Quiff', 'Slick Back', 'French Crop',
        'Buzz Cut', 'Faux Hawk', 'Curtain Hair', 'Shag Cut',
      ],
      'round': [
        'Faux Hawk', 'Mohawk Fade', 'Long Layers', 'Side Part',
        'Pompadour', 'Textured Fringe', 'Angular Fringe',
      ],
      'square': [
        'Textured Crop', 'Curtain Hair', 'Messy Fringe', 'Layered Bob',
        'Shaggy Layers', 'Soft Lob', 'Wavy Mid-Length',
      ],
      'heart': [
        'Lob (Long Bob)', 'Wispy Bangs', 'Shoulder Length',
        'Curtain Bangs', 'Pixie Cut', 'Chin-Length Bob',
      ],
      'oblong': [
        'Blunt Bob', 'Shaggy Layers', 'Curtain Bangs',
        'Wavy Lob', 'Bixie Cut', 'Textured Fringe',
      ],
    };

    List<String> alts = List.from(pool[shape] ?? pool['oval']!);

    // Filter by gender
    if (gen == 'male') {
      alts.removeWhere((s) => ['Lob (Long Bob)', 'Pixie Cut',
          'Chin-Length Bob', 'Bixie Cut'].contains(s));
    }
    if (gen == 'female') {
      alts.removeWhere((s) => ['Mohawk Fade', 'Faux Hawk',
          'Buzz Cut', 'French Crop'].contains(s));
    }

    // Add occasion-specific alternatives
    if (occ == 'wedding') alts.insert(0, 'Elegant Updo');
    if (occ == 'party')   alts.insert(0, 'Textured Party Style');
    if (occ == 'office')  alts.insert(0, 'Classic Professional Cut');

    // Return top 5
    return alts.take(5).toList();
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Reason generators — explain WHY each recommendation was made
  // ───────────────────────────────────────────────────────────────────────────
  static String _hairstyleReason(String style, String shape, String hair) {
    final shapeReasons = {
      'oval':   'Your oval face shape is the most versatile — it suits almost any style.',
      'round':  'Adding height and volume on top creates the illusion of a longer, slimmer face.',
      'square': 'Soft, flowing styles reduce the angularity of a strong square jawline.',
      'heart':  'This style balances your wider forehead with your narrower chin.',
      'oblong': 'Volume on the sides and medium length reduce the appearance of face length.',
    };

    final hairReasons = {
      'curly':  'Your natural curl texture adds beautiful volume and definition to this style.',
      'thin':   'This style maximises volume and creates the appearance of fuller hair.',
      'thick':  'Layering removes bulk and makes your thick hair easier to manage.',
      'wavy':   'Your natural wave texture works perfectly with this style\'s movement.',
      'straight': 'Your straight hair holds this style\'s structure and shape beautifully.',
    };

    final shapeReason = shapeReasons[shape] ?? 'This style suits your face shape well.';
    final hairReason  = hairReasons[hair] ?? '';

    return hairReason.isNotEmpty
        ? '$shapeReason $hairReason'
        : shapeReason;
  }

  static String _beardReason(String beard, String shape, String gen) {
    if (gen == 'female') {
      return 'Jawline contouring with makeup can enhance and define your face shape.';
    }
    final reasons = {
      'round':  'Vertical beard lines elongate the face and reduce roundness.',
      'square': 'Light stubble keeps the look clean without adding jaw bulk.',
      'heart':  'A fuller beard adds width to the chin, balancing the wider forehead.',
      'oblong': 'A wide beard adds horizontal width to balance face length.',
      'oval':   'Your balanced face shape suits most beard styles — this one complements it well.',
    };
    return reasons[shape] ?? 'This beard style complements your face shape.';
  }

  static String _colorReason(
      String color, String shape, String hair, String style) {
    if (hair == 'thin') {
      return 'Gentle color processes protect your fine hair while enhancing its appearance.';
    }
    if (hair == 'curly') {
      return 'This color enhances your natural curl definition and adds depth.';
    }
    final styleReasons = {
      'bold':    'Bold color choices make a strong statement and highlight your features.',
      'elegant': 'Rich, refined tones add sophistication and complement your face shape.',
      'modern':  'Cool-toned modern shades give a fresh, contemporary look.',
      'natural': 'Natural tones are universally flattering and low maintenance.',
      'simple':  'Classic colors are timeless and easy to maintain.',
    };
    return styleReasons[style] ??
        'This color complements your face shape and skin tone beautifully.';
  }

  static String _occasionNote(String occ, String shape, String hair) {
    switch (occ) {
      case 'wedding':
        return 'For a wedding, longevity is key — ask your stylist about setting spray '
            'and pinning techniques to keep your style perfect all day.';
      case 'office':
        return 'Office styles should be polished and low-maintenance. '
            'Choose a style you can recreate at home in under 10 minutes.';
      case 'party':
        return 'Party styles can be bolder — consider temporary color sprays '
            'or accessories to elevate your look for the night.';
      case 'photoshoot':
        return 'For photos, avoid styles with too much flyaway. '
            'Smooth, defined styles photograph better under studio lighting.';
      case 'casual':
      default:
        return 'A casual style should be easy to maintain and reflect your personality. '
            'Ask your stylist for a wash-and-go friendly version of this look.';
    }
  }
}

// ─── Internal helper ─────────────────────────────────────────────────────────
class _Base {
  final String hairstyle;
  final String beard;
  final String hairColor;
  const _Base({
    required this.hairstyle,
    required this.beard,
    required this.hairColor,
  });
}
