import '../../../core/l10n/l10n.dart';

/// A text in both of the app's languages.
class Bi {
  final String en;
  final String ne;
  const Bi(this.en, this.ne);

  /// In the language the app is being used in.
  String get text => L10n.isNepali ? ne : en;
}

/// General information about a common medicine: how to take it and the side
/// effects people most often notice.
///
/// This is patient-leaflet level guidance, not a prescription: the doctor's
/// instructions always come first, and the screens that show it say so.
class MedicineGuide {
  /// The generic name.
  final String name;

  /// Lower-case names this medicine is sold or written as (generic names and
  /// well-known brands). Matched as whole words inside the medicine's name.
  final List<String> match;
  final Bi usedFor;
  final Bi howToTake;
  final List<Bi> sideEffects;

  /// When to stop and get medical help.
  final Bi warning;

  const MedicineGuide({
    required this.name,
    required this.match,
    required this.usedFor,
    required this.howToTake,
    required this.sideEffects,
    required this.warning,
  });

  /// The guide for a medicine the user named, e.g. 'Cetamol 500' or
  /// 'Tab. Amlodipine 5mg'. Null when the medicine is not in the list.
  static MedicineGuide? find(String medicineName) {
    final name = ' ${medicineName.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), ' ')} ';
    // Combination products are listed first so they win over their parts.
    for (final guide in all) {
      for (final term in guide.match) {
        if (name.contains(' $term ')) return guide;
      }
    }
    // 'amoxicillin500' and similar: the name merely starts with a known one.
    for (final guide in all) {
      for (final term in guide.match) {
        if (term.length >= 6 && name.trimLeft().startsWith(term)) return guide;
      }
    }
    return null;
  }

  /// How to use a medicine of this form (API value such as 'tablet').
  static Bi formAdvice(String medicineType) =>
      _formAdvice[medicineType] ?? _formAdvice['other']!;

  /// What the intake timing means in practice (API value such as
  /// 'before_food'). Null for 'anytime'.
  static Bi? timingAdvice(String intakeTiming) => _timingAdvice[intakeTiming];

  /// Shown wherever this information is.
  static const disclaimer = Bi(
    'General information only. Always follow what your doctor or pharmacist '
        'told you, and ask them if you are unsure.',
    'यो सामान्य जानकारी मात्र हो। सधैँ आफ्नो डाक्टर वा फार्मेसीले भनेअनुसार '
        'गर्नुहोस्, र नबुझेमा उहाँहरूलाई सोध्नुहोस्।',
  );

  /// For a medicine that is not in the list.
  static const unknownSideEffects = Bi(
    'We do not have side-effect information for this medicine. Ask your '
        'pharmacist, or read the leaflet in the pack.',
    'यो औषधिको असरबारे हामीसँग जानकारी छैन। फार्मेसीमा सोध्नुहोस्, वा '
        'औषधिको प्याकेटभित्रको कागज पढ्नुहोस्।',
  );

  static const generalWarning = Bi(
    'Get medical help straight away for a rash, swelling of the face or '
        'lips, or trouble breathing after taking any medicine.',
    'कुनै पनि औषधि खाएपछि शरीरमा डाबर आएमा, अनुहार वा ओठ सुन्निएमा, वा सास '
        'फेर्न गाह्रो भएमा तुरुन्तै अस्पताल जानुहोस्।',
  );

  static const _timingAdvice = {
    'before_food': Bi('Take it about 30 minutes before you eat.',
        'खाना खानुभन्दा करिब 30 मिनेट अघि खानुहोस्।'),
    'after_food': Bi('Take it right after a meal, not on an empty stomach.',
        'खाना खाएलगत्तै खानुहोस्, खाली पेटमा नखानुहोस्।'),
    'with_food': Bi('Take it while you are eating.',
        'खाना खाँदाखाँदै खानुहोस्।'),
    'empty_stomach': Bi(
        'Take it on an empty stomach: 1 hour before food, or 2 hours after.',
        'खाली पेटमा खानुहोस्: खानाभन्दा 1 घण्टा अघि, वा खाएको 2 घण्टापछि।'),
    'before_sleep': Bi('Take it just before you go to bed.',
        'सुत्न जानुअघि खानुहोस्।'),
  };

  static const _formAdvice = {
    'tablet': Bi(
        'Swallow the tablet with a full glass of water. Do not crush or '
            'break it unless you were told to.',
        'चक्की एक गिलास पानीसँग निल्नुहोस्। डाक्टरले नभनेसम्म नफुटाउनुहोस्, '
            'नपिँध्नुहोस्।'),
    'capsule': Bi(
        'Swallow the capsule whole with a glass of water. Do not open or '
            'chew it.',
        'क्याप्सुल एक गिलास पानीसँग सिङ्गै निल्नुहोस्। नखोल्नुहोस्, '
            'नचपाउनुहोस्।'),
    'syrup': Bi(
        'Shake the bottle well. Measure the dose with the cup or spoon that '
            'came with it, not a kitchen spoon.',
        'बोतल राम्ररी हल्लाउनुहोस्। औषधिसँगै आएको कप वा चम्चाले नापेर '
            'खानुहोस्, भान्साको चम्चा प्रयोग नगर्नुहोस्।'),
    'injection': Bi(
        'Inject exactly as you were shown. Use a new needle every time and '
            'change the place you inject.',
        'सिकाइएअनुसार नै सुई लगाउनुहोस्। हरेक पटक नयाँ सुई प्रयोग गर्नुहोस् र '
            'लगाउने ठाउँ फेर्नुहोस्।'),
    'cream': Bi(
        'Wash and dry the skin. Put on a thin layer and rub it in gently. '
            'Wash your hands afterwards.',
        'छाला धोएर सुकाउनुहोस्। पातलो गरी लगाएर बिस्तारै दल्नुहोस्। त्यसपछि '
            'हात धुनुहोस्।'),
    'ointment': Bi(
        'Wash and dry the skin. Put on a thin layer. Wash your hands '
            'afterwards.',
        'छाला धोएर सुकाउनुहोस्। पातलो गरी लगाउनुहोस्। त्यसपछि हात धुनुहोस्।'),
    'gel': Bi(
        'Put a thin layer on clean, dry skin and let it dry. Wash your hands '
            'afterwards.',
        'सफा र सुक्खा छालामा पातलो गरी लगाउनुहोस् र सुक्न दिनुहोस्। त्यसपछि '
            'हात धुनुहोस्।'),
    'drops': Bi(
        'Wash your hands. Do not let the tip of the bottle touch your eye, '
            'ear or fingers. Close the bottle straight after use.',
        'हात धुनुहोस्। बोतलको टुप्पोले आँखा, कान वा औँला छुन नदिनुहोस्। '
            'प्रयोगपछि तुरुन्तै बिर्को लगाउनुहोस्।'),
    'inhaler': Bi(
        'Shake it. Breathe out fully, press once while breathing in slowly, '
            'then hold your breath for 10 seconds. Rinse your mouth after a '
            'steroid inhaler.',
        'हल्लाउनुहोस्। पूरै सास बाहिर फाल्नुहोस्, बिस्तारै सास तान्दै एक पटक '
            'थिच्नुहोस्, अनि 10 सेकेन्ड सास रोक्नुहोस्। स्टेरोइड इन्हेलरपछि '
            'मुख कुल्ला गर्नुहोस्।'),
    'spray': Bi(
        'Shake the bottle and use the number of sprays you were told. Wipe '
            'the nozzle after use.',
        'बोतल हल्लाउनुहोस् र भनिएजति पटक मात्र स्प्रे गर्नुहोस्। प्रयोगपछि '
            'टुप्पो पुछ्नुहोस्।'),
    'powder': Bi(
        'Mix the powder in the amount of clean water written on the pack and '
            'drink it straight away.',
        'प्याकेटमा लेखिएजति सफा पानीमा धुलो घोल्नुहोस् र तुरुन्तै पिउनुहोस्।'),
    'patch': Bi(
        'Stick the patch on clean, dry skin without hair. Use a different '
            'place each time.',
        'रौँ नभएको सफा, सुक्खा छालामा प्याच टाँस्नुहोस्। हरेक पटक फरक ठाउँमा '
            'टाँस्नुहोस्।'),
    'suppository': Bi(
        'Wash your hands, remove the wrapper and insert it as you were '
            'shown. Lie down for a few minutes afterwards.',
        'हात धुनुहोस्, खोल निकाल्नुहोस् र सिकाइएअनुसार राख्नुहोस्। त्यसपछि '
            'केही मिनेट पल्टिनुहोस्।'),
    'other': Bi('Use it exactly as your doctor or pharmacist told you.',
        'डाक्टर वा फार्मेसीले भनेअनुसार नै प्रयोग गर्नुहोस्।'),
  };

  static const all = <MedicineGuide>[
    // ---- combinations first ----
    MedicineGuide(
      name: 'Amoxicillin + clavulanic acid',
      match: ['augmentin', 'co amoxiclav', 'amoxiclav', 'clavulanate', 'clavulanic', 'clavam', 'moxclav'],
      usedFor: Bi('An antibiotic for infections caused by bacteria.',
          'ब्याक्टेरियाले गराउने संक्रमणको एन्टिबायोटिक।'),
      howToTake: Bi(
          'Take it at the start of a meal. Finish the whole course even if '
              'you feel better.',
          'खाना खान सुरु गर्दा खानुहोस्। निको भएजस्तो लागे पनि पूरा मात्रा '
              'सकाउनुहोस्।'),
      sideEffects: [
        Bi('Loose stools (diarrhoea)', 'पखाला'),
        Bi('Feeling sick (nausea)', 'वाकवाकी'),
        Bi('Thrush (white patches in the mouth, itching)', 'मुखमा सेतो दाग वा चिलाउने (ढुसी)'),
      ],
      warning: Bi(
          'Stop and get help for a rash, swelling or trouble breathing, or '
              'for yellow skin or eyes.',
          'डाबर, सुन्निने वा सास फेर्न गाह्रो भएमा, वा छाला/आँखा पहेँलो भएमा '
              'औषधि रोकेर तुरुन्त जँचाउनुहोस्।'),
    ),

    // ---- pain and fever ----
    MedicineGuide(
      name: 'Paracetamol',
      match: ['paracetamol', 'acetaminophen', 'cetamol', 'calpol', 'crocin', 'panadol', 'niko', 'pcm'],
      usedFor: Bi('For fever and mild pain such as headache.',
          'ज्वरो र टाउको दुखाइजस्तो हल्का दुखाइका लागि।'),
      howToTake: Bi(
          'With or without food. Leave at least 4 hours between doses and '
              'never take more than the dose you were given.',
          'खानासँग वा खाली पेटमा खान मिल्छ। दुई मात्राबीच कम्तीमा 4 घण्टा '
              'फरक राख्नुहोस् र भनिएभन्दा बढी कहिल्यै नखानुहोस्।'),
      sideEffects: [
        Bi('Side effects are rare at the right dose', 'ठीक मात्रामा खाँदा असर विरलै देखिन्छ'),
        Bi('Feeling sick (nausea)', 'वाकवाकी'),
      ],
      warning: Bi(
          'Too much paracetamol harms the liver. Many cold medicines also '
              'contain it: do not take both. Get help at once after an overdose.',
          'धेरै प्यारासिटामोलले कलेजो बिगार्छ। रुघाका धेरै औषधिमा पनि यो '
              'हुन्छ: दुवै सँगै नखानुहोस्। बढी खाएमा तुरुन्त अस्पताल जानुहोस्।'),
    ),
    MedicineGuide(
      name: 'Ibuprofen',
      match: ['ibuprofen', 'brufen', 'advil', 'nurofen'],
      usedFor: Bi('For pain, swelling and fever.', 'दुखाइ, सुन्निने र ज्वरोका लागि।'),
      howToTake: Bi('Take it with or after food, with water.',
          'खानासँग वा खाना खाएपछि पानीसँग खानुहोस्।'),
      sideEffects: [
        Bi('Stomach pain or heartburn', 'पेट दुख्ने वा छाती पोल्ने'),
        Bi('Feeling sick (nausea)', 'वाकवाकी'),
        Bi('Dizziness', 'रिँगटा'),
      ],
      warning: Bi(
          'Stop and see a doctor for black stools or vomiting blood. Ask '
              'first if you have stomach ulcers, kidney disease or asthma, or '
              'are pregnant.',
          'कालो दिसा वा रगत बान्ता भएमा औषधि रोकेर डाक्टरलाई देखाउनुहोस्। '
              'पेटको अल्सर, मिर्गौला रोग, दम छ वा गर्भवती हुनुहुन्छ भने पहिले '
              'सोध्नुहोस्।'),
    ),
    MedicineGuide(
      name: 'Diclofenac',
      match: ['diclofenac', 'voveran', 'voltaren'],
      usedFor: Bi('For pain and swelling of joints and muscles.',
          'जोर्नी र मांसपेशीको दुखाइ र सुन्निनेका लागि।'),
      howToTake: Bi('Take it with or after food, with water.',
          'खानासँग वा खाना खाएपछि पानीसँग खानुहोस्।'),
      sideEffects: [
        Bi('Stomach pain or heartburn', 'पेट दुख्ने वा छाती पोल्ने'),
        Bi('Feeling sick (nausea)', 'वाकवाकी'),
        Bi('Headache or dizziness', 'टाउको दुख्ने वा रिँगटा'),
      ],
      warning: Bi(
          'Stop and see a doctor for black stools or vomiting blood. Ask '
              'first if you have stomach ulcers, heart or kidney disease.',
          'कालो दिसा वा रगत बान्ता भएमा औषधि रोकेर डाक्टरलाई देखाउनुहोस्। '
              'पेटको अल्सर, मुटु वा मिर्गौला रोग छ भने पहिले सोध्नुहोस्।'),
    ),
    MedicineGuide(
      name: 'Aspirin',
      match: ['aspirin', 'ecosprin', 'disprin'],
      usedFor: Bi('A low dose keeps the blood from clotting, to protect the heart.',
          'थोरै मात्राले रगत जम्न दिँदैन र मुटुलाई जोगाउँछ।'),
      howToTake: Bi('Take it after food, at the same time each day.',
          'खाना खाएपछि, हरेक दिन एउटै समयमा खानुहोस्।'),
      sideEffects: [
        Bi('Stomach upset or heartburn', 'पेट गडबड वा छाती पोल्ने'),
        Bi('Bruising or bleeding more easily', 'सजिलै नीलडाम बस्ने वा रगत बग्ने'),
      ],
      warning: Bi(
          'See a doctor for black stools, vomiting blood or bleeding that '
              'does not stop. Not for children under 16.',
          'कालो दिसा, रगत बान्ता वा नरोकिने रगत बगेमा डाक्टरलाई देखाउनुहोस्। '
              '16 वर्षमुनिका बालबालिकालाई नदिनुहोस्।'),
    ),

    // ---- antibiotics ----
    MedicineGuide(
      name: 'Amoxicillin',
      match: ['amoxicillin', 'amoxycillin', 'amoxil', 'mox'],
      usedFor: Bi('An antibiotic for infections caused by bacteria.',
          'ब्याक्टेरियाले गराउने संक्रमणको एन्टिबायोटिक।'),
      howToTake: Bi(
          'With or without food, at evenly spaced times. Finish the whole '
              'course even if you feel better.',
          'खानासँग वा खाली पेटमा, बराबर समयको फरकमा खानुहोस्। निको भएजस्तो '
              'लागे पनि पूरा मात्रा सकाउनुहोस्।'),
      sideEffects: [
        Bi('Loose stools (diarrhoea)', 'पखाला'),
        Bi('Feeling sick (nausea)', 'वाकवाकी'),
        Bi('Skin rash', 'छालामा डाबर'),
      ],
      warning: Bi(
          'Stop and get help at once for a rash, swelling of the face or '
              'trouble breathing: this can be an allergy.',
          'डाबर, अनुहार सुन्निने वा सास फेर्न गाह्रो भएमा औषधि रोकेर तुरुन्त '
              'अस्पताल जानुहोस्: यो एलर्जी हुन सक्छ।'),
    ),
    MedicineGuide(
      name: 'Azithromycin',
      match: ['azithromycin', 'azithral', 'zithromax', 'azee'],
      usedFor: Bi('An antibiotic for infections caused by bacteria.',
          'ब्याक्टेरियाले गराउने संक्रमणको एन्टिबायोटिक।'),
      howToTake: Bi(
          'Once a day at the same time. Finish the whole course even if you '
              'feel better.',
          'दिनको एक पटक एउटै समयमा खानुहोस्। निको भएजस्तो लागे पनि पूरा मात्रा '
              'सकाउनुहोस्।'),
      sideEffects: [
        Bi('Loose stools (diarrhoea)', 'पखाला'),
        Bi('Feeling sick (nausea)', 'वाकवाकी'),
        Bi('Stomach pain', 'पेट दुख्ने'),
      ],
      warning: Bi(
          'See a doctor for a fast or uneven heartbeat, severe diarrhoea, or '
              'a rash or swelling.',
          'मुटु छिटो वा अनियमित धड्केमा, धेरै पखाला लागेमा, वा डाबर/सुन्निएमा '
              'डाक्टरलाई देखाउनुहोस्।'),
    ),
    MedicineGuide(
      name: 'Ciprofloxacin',
      match: ['ciprofloxacin', 'cipro', 'ciplox', 'cifran'],
      usedFor: Bi('An antibiotic for infections caused by bacteria.',
          'ब्याक्टेरियाले गराउने संक्रमणको एन्टिबायोटिक।'),
      howToTake: Bi(
          'Take it with plenty of water. Do not take it with milk, antacids, '
              'iron or calcium: keep 2 hours apart. Finish the course.',
          'प्रशस्त पानीसँग खानुहोस्। दूध, एन्टासिड, आइरन वा क्याल्सियमसँग '
              'नखानुहोस्: 2 घण्टाको फरक राख्नुहोस्। पूरा मात्रा सकाउनुहोस्।'),
      sideEffects: [
        Bi('Feeling sick (nausea)', 'वाकवाकी'),
        Bi('Loose stools (diarrhoea)', 'पखाला'),
        Bi('Dizziness', 'रिँगटा'),
        Bi('Skin burns more easily in the sun', 'घाममा छाला छिटो पोल्ने'),
      ],
      warning: Bi(
          'Stop and see a doctor for pain or swelling in a tendon (often '
              'the heel), or tingling in hands or feet.',
          'नसा (प्राय: कुर्कुच्चा) दुखेमा वा सुन्निएमा, वा हात-खुट्टा झमझम '
              'गरेमा औषधि रोकेर डाक्टरलाई देखाउनुहोस्।'),
    ),
    MedicineGuide(
      name: 'Metronidazole',
      match: ['metronidazole', 'flagyl', 'metrogyl'],
      usedFor: Bi('For some infections of the gut, teeth and other parts.',
          'आन्द्रा, दाँत र अरू भागका केही संक्रमणका लागि।'),
      howToTake: Bi(
          'Take it with or after food. Do not drink alcohol while taking it '
              'and for 2 days after. Finish the course.',
          'खानासँग वा खाना खाएपछि खानुहोस्। औषधि खाँदासम्म र सकिएको 2 दिनसम्म '
              'रक्सी नखानुहोस्। पूरा मात्रा सकाउनुहोस्।'),
      sideEffects: [
        Bi('A metal taste in the mouth', 'मुखमा फलामजस्तो स्वाद'),
        Bi('Feeling sick (nausea)', 'वाकवाकी'),
        Bi('Dark urine (harmless)', 'गाढा पिसाब (हानि गर्दैन)'),
      ],
      warning: Bi('See a doctor for numbness or tingling in hands or feet.',
          'हात-खुट्टा लाटो भएमा वा झमझम गरेमा डाक्टरलाई देखाउनुहोस्।'),
    ),
    MedicineGuide(
      name: 'Doxycycline',
      match: ['doxycycline', 'doxy'],
      usedFor: Bi('An antibiotic for infections caused by bacteria.',
          'ब्याक्टेरियाले गराउने संक्रमणको एन्टिबायोटिक।'),
      howToTake: Bi(
          'Take it sitting or standing with a full glass of water, and do '
              'not lie down for 30 minutes. Not with milk, iron or antacids.',
          'बसेर वा उभिएर एक गिलास पानीसँग खानुहोस्, र 30 मिनेटसम्म '
              'नपल्टिनुहोस्। दूध, आइरन वा एन्टासिडसँग नखानुहोस्।'),
      sideEffects: [
        Bi('Feeling sick (nausea)', 'वाकवाकी'),
        Bi('Heartburn', 'छाती पोल्ने'),
        Bi('Skin burns more easily in the sun', 'घाममा छाला छिटो पोल्ने'),
      ],
      warning: Bi(
          'Tell your doctor if you are pregnant. See a doctor for pain when '
              'swallowing.',
          'गर्भवती हुनुहुन्छ भने डाक्टरलाई भन्नुहोस्। निल्दा दुखेमा डाक्टरलाई '
              'देखाउनुहोस्।'),
    ),
    MedicineGuide(
      name: 'Cefixime',
      match: ['cefixime', 'taxim o', 'zifi'],
      usedFor: Bi('An antibiotic for infections caused by bacteria.',
          'ब्याक्टेरियाले गराउने संक्रमणको एन्टिबायोटिक।'),
      howToTake: Bi(
          'With or without food, at the same times each day. Finish the '
              'whole course.',
          'खानासँग वा खाली पेटमा, हरेक दिन एउटै समयमा खानुहोस्। पूरा मात्रा '
              'सकाउनुहोस्।'),
      sideEffects: [
        Bi('Loose stools (diarrhoea)', 'पखाला'),
        Bi('Stomach pain', 'पेट दुख्ने'),
        Bi('Feeling sick (nausea)', 'वाकवाकी'),
      ],
      warning: Bi(
          'Stop and get help at once for a rash, swelling or trouble '
              'breathing.',
          'डाबर, सुन्निने वा सास फेर्न गाह्रो भएमा औषधि रोकेर तुरुन्त अस्पताल '
              'जानुहोस्।'),
    ),

    // ---- stomach ----
    MedicineGuide(
      name: 'Omeprazole',
      match: ['omeprazole', 'omez', 'prilosec'],
      usedFor: Bi('Lowers stomach acid: for heartburn, gastritis and ulcers.',
          'पेटको एसिड घटाउँछ: छाती पोल्ने, ग्यास्ट्रिक र अल्सरका लागि।'),
      howToTake: Bi(
          'Take it 30 to 60 minutes before food, usually in the morning. '
              'Swallow it whole.',
          'खानाभन्दा 30 देखि 60 मिनेट अघि, प्राय: बिहान खानुहोस्। सिङ्गै '
              'निल्नुहोस्।'),
      sideEffects: [
        Bi('Headache', 'टाउको दुख्ने'),
        Bi('Stomach pain or gas', 'पेट दुख्ने वा ग्यास'),
        Bi('Loose stools or constipation', 'पखाला वा कब्जियत'),
      ],
      warning: Bi(
          'See a doctor if you have trouble swallowing, vomit blood, have '
              'black stools or lose weight without trying.',
          'निल्न गाह्रो भएमा, रगत बान्ता भएमा, कालो दिसा आएमा वा बिनाकारण तौल '
              'घटेमा डाक्टरलाई देखाउनुहोस्।'),
    ),
    MedicineGuide(
      name: 'Pantoprazole',
      match: ['pantoprazole', 'pantop', 'pantocid', 'protonix'],
      usedFor: Bi('Lowers stomach acid: for heartburn, gastritis and ulcers.',
          'पेटको एसिड घटाउँछ: छाती पोल्ने, ग्यास्ट्रिक र अल्सरका लागि।'),
      howToTake: Bi(
          'Take it 30 to 60 minutes before food, usually in the morning. '
              'Swallow it whole.',
          'खानाभन्दा 30 देखि 60 मिनेट अघि, प्राय: बिहान खानुहोस्। सिङ्गै '
              'निल्नुहोस्।'),
      sideEffects: [
        Bi('Headache', 'टाउको दुख्ने'),
        Bi('Stomach pain or gas', 'पेट दुख्ने वा ग्यास'),
        Bi('Loose stools or constipation', 'पखाला वा कब्जियत'),
      ],
      warning: Bi(
          'See a doctor if you have trouble swallowing, vomit blood, have '
              'black stools or lose weight without trying.',
          'निल्न गाह्रो भएमा, रगत बान्ता भएमा, कालो दिसा आएमा वा बिनाकारण तौल '
              'घटेमा डाक्टरलाई देखाउनुहोस्।'),
    ),
    MedicineGuide(
      name: 'Oral rehydration salts (ORS)',
      match: ['ors', 'jeevan jal', 'jeevanjal', 'rehydration', 'electral'],
      usedFor: Bi('Replaces water and salts lost in diarrhoea or vomiting.',
          'पखाला वा बान्तामा गुमेको पानी र नुन पूर्ति गर्छ।'),
      howToTake: Bi(
          'Mix one packet in the amount of clean water written on it '
              '(usually 1 litre). Sip it often. Throw away what is left after '
              '24 hours.',
          'एक प्याकेट त्यसमा लेखिएजति सफा पानीमा (प्राय: 1 लिटर) घोल्नुहोस्। '
              'थोरै-थोरै गरी पटक-पटक पिउनुहोस्। 24 घण्टापछि बाँकी फाल्नुहोस्।'),
      sideEffects: [
        Bi('Vomiting if drunk too fast: take small sips', 'छिटो पिउँदा बान्ता हुन सक्छ: थोरै-थोरै पिउनुहोस्'),
      ],
      warning: Bi(
          'See a doctor if the person cannot drink, is very sleepy, has '
              'blood in the stool, or diarrhoea lasts more than 2 days.',
          'बिरामीले पिउन नसकेमा, धेरै लठ्ठ परेमा, दिसामा रगत आएमा वा पखाला '
              '2 दिनभन्दा बढी रहेमा डाक्टरलाई देखाउनुहोस्।'),
    ),
    MedicineGuide(
      name: 'Zinc',
      match: ['zinc'],
      usedFor: Bi('Helps children recover from diarrhoea.',
          'बालबालिकालाई पखालाबाट निको हुन मद्दत गर्छ।'),
      howToTake: Bi(
          'Once a day for the number of days you were told (usually 10 to '
              '14), even after the diarrhoea stops.',
          'दिनको एक पटक, भनिएजति दिनसम्म (प्राय: 10 देखि 14 दिन), पखाला '
              'रोकिए पनि खुवाउनुहोस्।'),
      sideEffects: [
        Bi('Feeling sick or vomiting: give it after food', 'वाकवाकी वा बान्ता: खानापछि खुवाउनुहोस्'),
      ],
      warning: Bi('See a doctor if vomiting does not stop.',
          'बान्ता नरोकिएमा डाक्टरलाई देखाउनुहोस्।'),
    ),
    MedicineGuide(
      name: 'Albendazole',
      match: ['albendazole', 'zentel'],
      usedFor: Bi('For worms.', 'जुकाका लागि।'),
      howToTake: Bi(
          'Chew the tablet or swallow it with food. Often it is a single '
              'dose.',
          'चक्की चपाएर वा खानासँग निल्नुहोस्। प्राय: एक मात्रा मात्र हुन्छ।'),
      sideEffects: [
        Bi('Stomach pain', 'पेट दुख्ने'),
        Bi('Feeling sick (nausea)', 'वाकवाकी'),
        Bi('Headache', 'टाउको दुख्ने'),
      ],
      warning: Bi('Do not take it in the first 3 months of pregnancy.',
          'गर्भको पहिलो 3 महिनामा नखानुहोस्।'),
    ),

    // ---- allergy and breathing ----
    MedicineGuide(
      name: 'Cetirizine',
      match: ['cetirizine', 'cetzine', 'zyrtec', 'okacet'],
      usedFor: Bi('For allergy: sneezing, runny nose, itching and hives.',
          'एलर्जीका लागि: हाच्छिउँ, नाकबाट पानी बग्ने, चिलाउने र डाबर।'),
      howToTake: Bi('Once a day. Take it in the evening if it makes you sleepy.',
          'दिनको एक पटक। निद्रा लाग्छ भने बेलुका खानुहोस्।'),
      sideEffects: [
        Bi('Sleepiness', 'निद्रा लाग्ने'),
        Bi('Dry mouth', 'मुख सुक्ने'),
        Bi('Tiredness', 'थकाइ'),
      ],
      warning: Bi(
          'Do not drive or use machines if you feel sleepy. Avoid alcohol.',
          'निद्रा लागेमा सवारी नचलाउनुहोस्, मेसिनमा काम नगर्नुहोस्। रक्सी '
              'नखानुहोस्।'),
    ),
    MedicineGuide(
      name: 'Levocetirizine',
      match: ['levocetirizine', 'levocet', 'xyzal'],
      usedFor: Bi('For allergy: sneezing, runny nose, itching and hives.',
          'एलर्जीका लागि: हाच्छिउँ, नाकबाट पानी बग्ने, चिलाउने र डाबर।'),
      howToTake: Bi('Once a day, in the evening.', 'दिनको एक पटक, बेलुका।'),
      sideEffects: [
        Bi('Sleepiness', 'निद्रा लाग्ने'),
        Bi('Dry mouth', 'मुख सुक्ने'),
        Bi('Tiredness', 'थकाइ'),
      ],
      warning: Bi(
          'Do not drive or use machines if you feel sleepy. Avoid alcohol.',
          'निद्रा लागेमा सवारी नचलाउनुहोस्, मेसिनमा काम नगर्नुहोस्। रक्सी '
              'नखानुहोस्।'),
    ),
    MedicineGuide(
      name: 'Loratadine',
      match: ['loratadine', 'claritin', 'lorfast'],
      usedFor: Bi('For allergy: sneezing, runny nose and itching.',
          'एलर्जीका लागि: हाच्छिउँ, नाकबाट पानी बग्ने र चिलाउने।'),
      howToTake: Bi('Once a day, with or without food.',
          'दिनको एक पटक, खानासँग वा खाली पेटमा।'),
      sideEffects: [
        Bi('Headache', 'टाउको दुख्ने'),
        Bi('Dry mouth', 'मुख सुक्ने'),
        Bi('Mild sleepiness in some people', 'कसैकसैलाई हल्का निद्रा लाग्ने'),
      ],
      warning: Bi('See a doctor if the allergy does not get better.',
          'एलर्जी निको नभएमा डाक्टरलाई देखाउनुहोस्।'),
    ),
    MedicineGuide(
      name: 'Salbutamol',
      match: ['salbutamol', 'albuterol', 'asthalin', 'ventolin', 'ventorlin'],
      usedFor: Bi('Opens the airways quickly in asthma and wheezing.',
          'दम र सास फेर्दा स्याँस्याँ हुँदा सासनली छिट्टै खोल्छ।'),
      howToTake: Bi(
          'Inhaler: shake, breathe out, press once while breathing in '
              'slowly, hold your breath 10 seconds. Use it when you need it, '
              'as you were told.',
          'इन्हेलर: हल्लाउनुहोस्, सास फाल्नुहोस्, बिस्तारै सास तान्दै एक पटक '
              'थिच्नुहोस्, 10 सेकेन्ड सास रोक्नुहोस्। भनिएअनुसार चाहिएको बेला '
              'प्रयोग गर्नुहोस्।'),
      sideEffects: [
        Bi('Shaky hands', 'हात काम्ने'),
        Bi('Fast heartbeat', 'मुटु छिटो धड्कने'),
        Bi('Headache', 'टाउको दुख्ने'),
      ],
      warning: Bi(
          'Get help at once if it does not ease your breathing. Tell your '
              'doctor if you need it more often than before.',
          'यसले सास फेर्न सजिलो नबनाएमा तुरुन्त अस्पताल जानुहोस्। पहिलेभन्दा '
              'धेरै पटक चाहिन थालेमा डाक्टरलाई भन्नुहोस्।'),
    ),
    MedicineGuide(
      name: 'Montelukast',
      match: ['montelukast', 'montair', 'singulair'],
      usedFor: Bi('Prevents asthma attacks and eases allergy.',
          'दमको आक्रमण रोक्छ र एलर्जी कम गर्छ।'),
      howToTake: Bi('Once a day in the evening, even when you feel well.',
          'दिनको एक पटक बेलुका, सन्चो भए पनि खानुहोस्।'),
      sideEffects: [
        Bi('Headache', 'टाउको दुख्ने'),
        Bi('Stomach pain', 'पेट दुख्ने'),
      ],
      warning: Bi(
          'Tell your doctor about mood changes, bad dreams or trouble '
              'sleeping. It does not stop an attack that has started.',
          'मन बदलिएमा, नराम्रो सपना देखेमा वा निद्रा नलागेमा डाक्टरलाई '
              'भन्नुहोस्। सुरु भइसकेको दमको आक्रमण यसले रोक्दैन।'),
    ),
    MedicineGuide(
      name: 'Prednisolone',
      match: ['prednisolone', 'prednisone', 'wysolone', 'omnacortil'],
      usedFor: Bi('A steroid that calms swelling and allergy.',
          'सुन्निने र एलर्जी कम गर्ने स्टेरोइड।'),
      howToTake: Bi(
          'Take it in the morning with or after food. Do not stop it '
              'suddenly if you have taken it for more than a few weeks.',
          'बिहान खानासँग वा खाना खाएपछि खानुहोस्। केही हप्ताभन्दा बढी खानुभएको '
              'छ भने एक्कासि नछोड्नुहोस्।'),
      sideEffects: [
        Bi('Feeling hungrier', 'धेरै भोक लाग्ने'),
        Bi('Trouble sleeping', 'निद्रा नलाग्ने'),
        Bi('Mood changes', 'मन बदलिने'),
        Bi('Stomach upset', 'पेट गडबड'),
        Bi('Higher blood sugar', 'रगतमा चिनी बढ्ने'),
      ],
      warning: Bi(
          'See a doctor for fever or other signs of infection, black '
              'stools, or blurred vision.',
          'ज्वरो वा संक्रमणका अरू लक्षण, कालो दिसा वा धमिलो देखिएमा डाक्टरलाई '
              'देखाउनुहोस्।'),
    ),

    // ---- diabetes ----
    MedicineGuide(
      name: 'Metformin',
      match: ['metformin', 'glycomet', 'glucophage', 'glyciphage'],
      usedFor: Bi('Lowers blood sugar in diabetes.', 'मधुमेहमा रगतको चिनी घटाउँछ।'),
      howToTake: Bi('Take it with food or right after eating.',
          'खानासँग वा खाना खाएलगत्तै खानुहोस्।'),
      sideEffects: [
        Bi('Feeling sick (nausea)', 'वाकवाकी'),
        Bi('Loose stools (diarrhoea)', 'पखाला'),
        Bi('Stomach upset: often settles in a few weeks', 'पेट गडबड: प्राय: केही हप्तामा ठीक हुन्छ'),
        Bi('A metal taste in the mouth', 'मुखमा फलामजस्तो स्वाद'),
      ],
      warning: Bi(
          'Stop and see a doctor if you are vomiting a lot, very weak, or '
              'breathing fast.',
          'धेरै बान्ता भएमा, धेरै कमजोर भएमा वा सास छिटो चलेमा औषधि रोकेर '
              'डाक्टरलाई देखाउनुहोस्।'),
    ),
    MedicineGuide(
      name: 'Glimepiride',
      match: ['glimepiride', 'amaryl', 'glimy'],
      usedFor: Bi('Lowers blood sugar in diabetes.', 'मधुमेहमा रगतको चिनी घटाउँछ।'),
      howToTake: Bi(
          'Take it with breakfast or your first main meal. Do not skip '
              'meals.',
          'बिहानको खाजा वा दिनको पहिलो मुख्य खानासँग खानुहोस्। खाना '
              'नछुटाउनुहोस्।'),
      sideEffects: [
        Bi('Low blood sugar: sweating, shaking, hunger, dizziness', 'रगतमा चिनी घट्ने: पसिना, काम्ने, भोक, रिँगटा'),
        Bi('Weight gain', 'तौल बढ्ने'),
      ],
      warning: Bi(
          'For low blood sugar eat sugar or drink something sweet at once. '
              'Get help if the person is confused or faints.',
          'चिनी घटेमा तुरुन्त चिनी वा गुलियो खानुहोस्/पिउनुहोस्। बिरामी '
              'अलमलिएमा वा बेहोस भएमा तुरुन्त अस्पताल लैजानुहोस्।'),
    ),
    MedicineGuide(
      name: 'Insulin',
      match: ['insulin', 'mixtard', 'lantus', 'actrapid', 'novomix', 'humulin'],
      usedFor: Bi('Lowers blood sugar in diabetes.', 'मधुमेहमा रगतको चिनी घटाउँछ।'),
      howToTake: Bi(
          'Inject under the skin as you were shown and change the place '
              'each time. Keep it in the fridge, never frozen.',
          'सिकाइएअनुसार छालामुनि सुई लगाउनुहोस् र हरेक पटक ठाउँ फेर्नुहोस्। '
              'फ्रिजमा राख्नुहोस्, कहिल्यै नजमाउनुहोस्।'),
      sideEffects: [
        Bi('Low blood sugar: sweating, shaking, hunger, dizziness', 'रगतमा चिनी घट्ने: पसिना, काम्ने, भोक, रिँगटा'),
        Bi('Lumps or soreness where you inject', 'सुई लगाएको ठाउँमा गिर्खा वा दुखाइ'),
      ],
      warning: Bi(
          'For low blood sugar eat sugar or drink something sweet at once. '
              'Get help if the person is confused or faints.',
          'चिनी घटेमा तुरुन्त चिनी वा गुलियो खानुहोस्/पिउनुहोस्। बिरामी '
              'अलमलिएमा वा बेहोस भएमा तुरुन्त अस्पताल लैजानुहोस्।'),
    ),

    // ---- blood pressure, heart, cholesterol ----
    MedicineGuide(
      name: 'Amlodipine',
      match: ['amlodipine', 'amlod', 'amlong', 'norvasc', 'amlopres'],
      usedFor: Bi('Lowers high blood pressure.', 'उच्च रक्तचाप (ब्लड प्रेसर) घटाउँछ।'),
      howToTake: Bi(
          'Once a day at the same time, with or without food. Keep taking '
              'it even when you feel well.',
          'दिनको एक पटक एउटै समयमा, खानासँग वा खाली पेटमा। सन्चो भए पनि खान '
              'नछोड्नुहोस्।'),
      sideEffects: [
        Bi('Swollen ankles or feet', 'गोलीगाँठो वा खुट्टा सुन्निने'),
        Bi('Headache', 'टाउको दुख्ने'),
        Bi('Flushed, warm face', 'अनुहार रातो र तातो हुने'),
        Bi('Dizziness', 'रिँगटा'),
      ],
      warning: Bi(
          'Do not stop it without asking your doctor. See a doctor for '
              'chest pain or a very fast heartbeat.',
          'डाक्टरलाई नसोधी नछोड्नुहोस्। छाती दुखेमा वा मुटु धेरै छिटो धड्केमा '
              'डाक्टरलाई देखाउनुहोस्।'),
    ),
    MedicineGuide(
      name: 'Losartan',
      match: ['losartan', 'losar', 'cozaar', 'repace'],
      usedFor: Bi('Lowers high blood pressure and protects the kidneys.',
          'उच्च रक्तचाप घटाउँछ र मिर्गौला जोगाउँछ।'),
      howToTake: Bi('Once a day at the same time, with or without food.',
          'दिनको एक पटक एउटै समयमा, खानासँग वा खाली पेटमा।'),
      sideEffects: [
        Bi('Dizziness, mostly when standing up', 'रिँगटा, खास गरी उठ्दा'),
        Bi('Tiredness', 'थकाइ'),
      ],
      warning: Bi(
          'Do not take it if you are pregnant. Get help at once for '
              'swelling of the face, lips or tongue.',
          'गर्भवती हुनुहुन्छ भने नखानुहोस्। अनुहार, ओठ वा जिब्रो सुन्निएमा '
              'तुरुन्त अस्पताल जानुहोस्।'),
    ),
    MedicineGuide(
      name: 'Telmisartan',
      match: ['telmisartan', 'telma', 'micardis'],
      usedFor: Bi('Lowers high blood pressure.', 'उच्च रक्तचाप (ब्लड प्रेसर) घटाउँछ।'),
      howToTake: Bi('Once a day at the same time, with or without food.',
          'दिनको एक पटक एउटै समयमा, खानासँग वा खाली पेटमा।'),
      sideEffects: [
        Bi('Dizziness, mostly when standing up', 'रिँगटा, खास गरी उठ्दा'),
        Bi('Tiredness', 'थकाइ'),
      ],
      warning: Bi(
          'Do not take it if you are pregnant. Get help at once for '
              'swelling of the face, lips or tongue.',
          'गर्भवती हुनुहुन्छ भने नखानुहोस्। अनुहार, ओठ वा जिब्रो सुन्निएमा '
              'तुरुन्त अस्पताल जानुहोस्।'),
    ),
    MedicineGuide(
      name: 'Enalapril',
      match: ['enalapril', 'envas', 'ramipril', 'lisinopril'],
      usedFor: Bi('Lowers high blood pressure and helps the heart.',
          'उच्च रक्तचाप घटाउँछ र मुटुलाई मद्दत गर्छ।'),
      howToTake: Bi('At the same time each day, with or without food.',
          'हरेक दिन एउटै समयमा, खानासँग वा खाली पेटमा।'),
      sideEffects: [
        Bi('A dry cough', 'सुक्खा खोकी'),
        Bi('Dizziness, mostly when standing up', 'रिँगटा, खास गरी उठ्दा'),
      ],
      warning: Bi(
          'Do not take it if you are pregnant. Get help at once for '
              'swelling of the face, lips or tongue.',
          'गर्भवती हुनुहुन्छ भने नखानुहोस्। अनुहार, ओठ वा जिब्रो सुन्निएमा '
              'तुरुन्त अस्पताल जानुहोस्।'),
    ),
    MedicineGuide(
      name: 'Atenolol',
      match: ['atenolol', 'aten', 'tenormin', 'metoprolol'],
      usedFor: Bi('Lowers blood pressure and slows a fast heartbeat.',
          'रक्तचाप घटाउँछ र छिटो चलेको मुटुलाई बिस्तारो बनाउँछ।'),
      howToTake: Bi('At the same time each day.', 'हरेक दिन एउटै समयमा।'),
      sideEffects: [
        Bi('Tiredness', 'थकाइ'),
        Bi('Cold hands and feet', 'हात-खुट्टा चिसो हुने'),
        Bi('Slow heartbeat', 'मुटु बिस्तारै धड्कने'),
        Bi('Dizziness', 'रिँगटा'),
      ],
      warning: Bi(
          'Do not stop it suddenly. Tell your doctor if you have asthma, or '
              'if you become short of breath.',
          'एक्कासि नछोड्नुहोस्। दम छ भने, वा सास फेर्न गाह्रो भएमा डाक्टरलाई '
              'भन्नुहोस्।'),
    ),
    MedicineGuide(
      name: 'Atorvastatin',
      match: ['atorvastatin', 'atorva', 'lipitor', 'rosuvastatin', 'rosuvas'],
      usedFor: Bi('Lowers cholesterol to protect the heart.',
          'मुटु जोगाउन कोलेस्टेरोल घटाउँछ।'),
      howToTake: Bi('Once a day at the same time, with or without food.',
          'दिनको एक पटक एउटै समयमा, खानासँग वा खाली पेटमा।'),
      sideEffects: [
        Bi('Muscle aches', 'मांसपेशी दुख्ने'),
        Bi('Stomach upset', 'पेट गडबड'),
        Bi('Headache', 'टाउको दुख्ने'),
      ],
      warning: Bi(
          'See a doctor for strong muscle pain or weakness with no reason, '
              'or for dark urine.',
          'बिनाकारण मांसपेशी धेरै दुखेमा वा कमजोर भएमा, वा पिसाब गाढा भएमा '
              'डाक्टरलाई देखाउनुहोस्।'),
    ),

    // ---- thyroid, vitamins ----
    MedicineGuide(
      name: 'Levothyroxine',
      match: ['levothyroxine', 'thyroxine', 'eltroxin', 'thyronorm', 'thyrox'],
      usedFor: Bi('Replaces thyroid hormone when the thyroid is underactive.',
          'थाइराइडले कम काम गर्दा थाइराइड हर्मोन पूर्ति गर्छ।'),
      howToTake: Bi(
          'In the morning on an empty stomach with water only, 30 to 60 '
              'minutes before breakfast. Keep 4 hours away from iron and '
              'calcium.',
          'बिहान खाली पेटमा पानीसँग मात्र, खाजाभन्दा 30 देखि 60 मिनेट अघि '
              'खानुहोस्। आइरन र क्याल्सियमसँग 4 घण्टाको फरक राख्नुहोस्।'),
      sideEffects: [
        Bi('If the dose is too high: fast heartbeat, shaking, sweating, trouble sleeping', 'मात्रा बढी भएमा: मुटु छिटो धड्कने, काम्ने, पसिना, निद्रा नलाग्ने'),
      ],
      warning: Bi('See a doctor for chest pain or a racing heartbeat.',
          'छाती दुखेमा वा मुटु धेरै छिटो धड्केमा डाक्टरलाई देखाउनुहोस्।'),
    ),
    MedicineGuide(
      name: 'Iron',
      match: ['iron', 'ferrous', 'fefol', 'livogen', 'autrin'],
      usedFor: Bi('For low blood (anaemia) and in pregnancy.',
          'रगतको कमी (एनिमिया) र गर्भावस्थाका लागि।'),
      howToTake: Bi(
          'Best on an empty stomach with water or juice; after food if it '
              'upsets your stomach. Not with tea or milk.',
          'खाली पेटमा पानी वा जुससँग खानु राम्रो; पेट गडबड भए खानापछि '
              'खानुहोस्। चिया वा दूधसँग नखानुहोस्।'),
      sideEffects: [
        Bi('Black stools (harmless)', 'कालो दिसा (हानि गर्दैन)'),
        Bi('Constipation', 'कब्जियत'),
        Bi('Feeling sick or stomach pain', 'वाकवाकी वा पेट दुख्ने'),
      ],
      warning: Bi(
          'Keep it away from children: too much iron is dangerous for them.',
          'बालबालिकाको पहुँचबाट टाढा राख्नुहोस्: धेरै आइरन उनीहरूका लागि '
              'खतरनाक हुन्छ।'),
    ),
    MedicineGuide(
      name: 'Folic acid',
      match: ['folic', 'folate', 'folvite'],
      usedFor: Bi('A vitamin for healthy blood, and before and during pregnancy.',
          'स्वस्थ रगतका लागि, र गर्भअघि र गर्भावस्थामा चाहिने भिटामिन।'),
      howToTake: Bi('Once a day, with or without food.',
          'दिनको एक पटक, खानासँग वा खाली पेटमा।'),
      sideEffects: [
        Bi('Side effects are rare', 'असर विरलै देखिन्छ'),
      ],
      warning: Bi('Take only the dose you were given.',
          'भनिएजति मात्रा मात्र खानुहोस्।'),
    ),
    MedicineGuide(
      name: 'Calcium and vitamin D',
      match: ['calcium', 'vitamin d', 'vitamin d3', 'shelcal', 'calcimax', 'cholecalciferol'],
      usedFor: Bi('For strong bones.', 'बलियो हड्डीका लागि।'),
      howToTake: Bi(
          'Take it with food. Keep 2 to 4 hours away from iron, thyroid '
              'tablets and some antibiotics.',
          'खानासँग खानुहोस्। आइरन, थाइराइडको औषधि र केही एन्टिबायोटिकसँग '
              '2 देखि 4 घण्टाको फरक राख्नुहोस्।'),
      sideEffects: [
        Bi('Constipation', 'कब्जियत'),
        Bi('Gas or bloating', 'ग्यास वा पेट फुल्ने'),
      ],
      warning: Bi(
          'Tell your doctor if you have had kidney stones.',
          'पहिले मिर्गौलामा पत्थरी भएको थियो भने डाक्टरलाई भन्नुहोस्।'),
    ),
  ];
}
