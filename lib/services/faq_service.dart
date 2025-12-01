// lib/services/faq_service.dart
import 'dart:async';

class FaqItem {
  final String id;
  final String question;
  final String answer;
  final List<String> tags;

  FaqItem({
    required this.id,
    required this.question,
    required this.answer,
    this.tags = const [],
  });
}

class MatchedFaq {
  final FaqItem item;
  final double confidence; // 0..1

  MatchedFaq({required this.item, required this.confidence});
}

class FaqService {
  // Lightweight stopword list
  static final Set<String> _stopwords = {
    'the', 'is', 'a', 'an', 'and', 'or', 'to', 'of', 'in', 'on', 'for', 'my', 'me', 'i', 'you', 'how', 'what', 'do', 'does', 'can',
  };

  // Simple synonyms map -> map variant -> canonical token
  static final Map<String, String> _synonyms = {
    'evict': 'eviction',
    'evicted': 'eviction',
    'eviction': 'eviction',
    'tenant': 'tenant',
    'landlord': 'landlord',
    'rent': 'rent',
    'rental': 'rent',
    'lease': 'lease',
    'divorce': 'divorce',
    'marriage': 'divorce',
    'traffic': 'traffic',
    'ticket': 'fine',
    'fine': 'fine',
    'accident': 'accident',
    'contract': 'contract',
    'agreement': 'contract',
    'employment': 'employment',
    'fired': 'employment',
    'dismissed': 'employment',
    // add more as you expand the FAQ
  };

  // Small sample dataset (extend this heavily)
  final List<FaqItem> _faq = [
    FaqItem(
      id: 'faq_rent_1',
      question: 'What are my rights as a tenant?',
      answer:
      'As a tenant, you generally have the right to a habitable home, privacy, and proper notice before entry. Check your lease and local tenancy regulations for specifics.',
      tags: ['tenant', 'rent', 'lease'],
    ),
    FaqItem(
      id: 'faq_eviction_1',
      question: 'How can I stop an eviction?',
      answer:
      'If you received an eviction notice, respond quickly. Check deadlines on the notice, gather proof of payments, and contact a local legal aid service; procedures vary by area.',
      tags: ['eviction', 'landlord'],
    ),
    FaqItem(
      id: 'faq_divorce_1',
      question: 'How does divorce work?',
      answer:
      'Divorce rules differ by jurisdiction — common steps include filing paperwork, asset division, and custody decisions. Consult a family lawyer for a local checklist.',
      tags: ['divorce', 'marriage', 'family'],
    ),
    FaqItem(
      id: 'faq_fines_1',
      question: 'What to do about a traffic fine?',
      answer:
      'Check the ticket for payment amount and due date. Look for appeal instructions if you want to contest it; some places allow online payment or traffic school options.',
      tags: ['traffic', 'fine', 'ticket'],
    ),
    // Add many more items here for real coverage
  ];

  // Public API — find best match
  Future<MatchedFaq?> matchQuestion(String userQuestion) async {
    await Future.delayed(const Duration(milliseconds: 200)); // simulate short processing

    final queryTokens = _normalizeWords(userQuestion);
    if (queryTokens.isEmpty) return null;

    double bestScore = 0.0;
    FaqItem? bestItem;

    for (final f in _faq) {
      final questionPlusTags = '${f.question} ${f.tags.join(' ')}';
      final docTokens = _normalizeWords(questionPlusTags);

      final tokenScore = _jaccard(queryTokens, docTokens); // 0..1
      final bigramScore = _bigramJaccard(userQuestion.toLowerCase(), f.question.toLowerCase()); // 0..1

      // Boost if any tag token present
      final tagBoost = f.tags.any((t) => queryTokens.contains(_canonical(t))) ? 0.12 : 0.0;

      // Combined score (weights chosen to favour token overlap but reward phrase similarity)
      final score = (tokenScore * 0.7) + (bigramScore * 0.3) + tagBoost;

      if (score > bestScore) {
        bestScore = score;
        bestItem = f;
      }
    }

    if (bestItem == null) return null;
    final normalizedConfidence = bestScore.clamp(0.0, 1.0);
    return MatchedFaq(item: bestItem, confidence: normalizedConfidence);
  }

  // ----- Helpers -----

  Set<String> _normalizeWords(String s) {
    final reg = RegExp(r"[a-z0-9]+");
    final matches = reg.allMatches(s.toLowerCase());
    final Set<String> tokens = {};
    for (final m in matches) {
      final w = m.group(0)!;
      if (_stopwords.contains(w)) continue;
      final canon = _canonical(w);
      if (canon.isNotEmpty) tokens.add(canon);
    }
    return tokens;
  }

  String _canonical(String token) {
    // map synonyms to canonical, otherwise return token
    if (_synonyms.containsKey(token)) return _synonyms[token]!;
    return token;
  }

  double _jaccard(Set<String> a, Set<String> b) {
    if (a.isEmpty || b.isEmpty) return 0.0;
    final intersect = a.intersection(b).length.toDouble();
    final union = a.union(b).length.toDouble();
    if (union == 0) return 0.0;
    return intersect / union;
  }

  // Compute simple bigram jaccard on raw lowercased strings (keeps word order signals)
  double _bigramJaccard(String aRaw, String bRaw) {
    final a = _normalizeForNGram(aRaw);
    final b = _normalizeForNGram(bRaw);
    final aBigrams = _ngrams(a, 2);
    final bBigrams = _ngrams(b, 2);
    if (aBigrams.isEmpty || bBigrams.isEmpty) return 0.0;
    final inter = aBigrams.intersection(bBigrams).length.toDouble();
    final union = aBigrams.union(bBigrams).length.toDouble();
    return union == 0.0 ? 0.0 : inter / union;
  }

  String _normalizeForNGram(String s) {
    // remove punctuation, multiple spaces
    return s.toLowerCase().replaceAll(RegExp(r'[^a-z0-9\s]'), ' ').replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  Set<String> _ngrams(String s, int n) {
    final tokens = s.split(' ');
    final Set<String> grams = {};
    if (tokens.length < n) return grams;
    for (var i = 0; i <= tokens.length - n; i++) {
      grams.add(tokens.sublist(i, i + n).join(' '));
    }
    return grams;
  }
}
