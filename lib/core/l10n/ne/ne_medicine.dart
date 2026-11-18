/// Nepali texts, keyed by the English text. See ne.dart.
///
/// One word is used throughout for each idea: "मात्रा" for a dose, "सम्झना"
/// for a reminder, and "खानु" for taking a medicine.
const Map<String, String> neMedicine = {
  // ---------------------------------------------------------------------------
  // Dashboard
  // ---------------------------------------------------------------------------
  'Good morning': 'शुभ प्रभात',
  'Good afternoon': 'शुभ दिन',
  'Good evening': 'शुभ साँझ',
  '{greeting}, {name}': '{greeting}, {name}',
  "Today's doses": 'आज खाने औषधि',
  "Could not load today's doses.": 'आज खाने औषधि ल्याउन सकिएन।',
  'No doses scheduled for today.\nAdd a medicine with a schedule to get reminders.':
      'आज खानुपर्ने औषधि छैन।\nसम्झना पाउन खाने समय राखेर औषधि थप्नुहोस्।',
  'My medicines': 'मेरा औषधि',
  'Medicines': 'औषधि',
  '{n} stopped': '{n} रोकिएको',
  'To refill soon': 'चाँडै किन्नुपर्ने',
  'Refill soon': 'चाँडै किन्नुहोस्',

  // Today's chart (dose_timing_card.dart)
  "Today's medicines": 'आजका औषधि',
  'No doses scheduled': 'खानुपर्ने औषधि छैन',
  '{n} of {total} taken on time': '{total} मध्ये {n} समयमा खानुभयो',
  'Late or missed': 'ढिला भएका वा छुटेका',
  'Nothing late or missed today. Well done!':
      'आज कुनै औषधि ढिला भएन, छुटेन पनि। स्याबास!',
  'On time': 'समयमा खाएको',
  'Taken late': 'ढिला खाएको',
  'Still to take': 'खान बाँकी',
  '{n} min': '{n} मिनेट',
  '{h} h': '{h} घण्टा',
  '{h} h {m} min': '{h} घण्टा {m} मिनेट',
  'Taken {time} late': '{time} ढिला खानुभयो',
  'Take it now · {time} late': 'अहिले नै खानुहोस् · {time} ढिला भयो',
  'Last 7 days': 'पछिल्लो 7 दिन',

  // ---------------------------------------------------------------------------
  // Doses: marking them and their history
  // ---------------------------------------------------------------------------
  // The button that marks a dose as taken. A tablet is eaten, a cream is
  // applied, drops are put in (see MedicationFormat.takeLabel).
  'Take': 'खानुहोस्',
  'Take (apply)': 'लगाउनुहोस्',
  'Take (drops)': 'हाल्नुहोस्',
  'Take (other)': 'लिनुहोस्',
  'Taken': 'खाएको',
  'Skipped': 'छोडेको',
  'Missed': 'छुटेको',
  'Due now': 'खाने बेला भयो',
  'Upcoming': 'पछि खाने',
  'Remaining': 'बाँकी',
  'Change to skipped': '"छोडेको" मा बदल्नुहोस्',
  'Change to taken': '"खाएको" मा बदल्नुहोस्',
  'Last {n} days': 'पछिल्लो {n} दिन',
  'Could not load your history.': 'तपाईंको इतिहास ल्याउन सकिएन।',
  'No scheduled doses in this period.':
      'यो अवधिमा खानुपर्ने कुनै औषधि थिएन।',
  '{n}% adherence': '{n}% खानुभयो',
  '{taken} of {total} doses taken': '{total} मध्ये {taken} मात्रा खानुभयो',

  // ---------------------------------------------------------------------------
  // Notifications
  // ---------------------------------------------------------------------------
  'Mark all read': 'सबै पढिसकें',
  'Could not load notifications': 'सूचनाहरू ल्याउन सकिएन',
  'Something went wrong.': 'केही गडबड भयो।',
  'No notifications yet': 'अहिलेसम्म कुनै सूचना आएको छैन',
  'Dose reminders and refill reminders will appear here.':
      'औषधि खाने सम्झना र औषधि सकिन लागेको सूचना यहाँ देखिन्छ।',
  'Load older': 'पुराना सूचना हेर्नुहोस्',
  'Just now': 'भर्खरै',
  '{n} min ago': '{n} मिनेट अघि',
  '{n} h ago': '{n} घण्टा अघि',
  'Today, {time}': 'आज, {time}',
  'Yesterday, {time}': 'हिजो, {time}',

  // ---------------------------------------------------------------------------
  // Medicine list
  // ---------------------------------------------------------------------------
  'Add medicine': 'नयाँ औषधि थप्नुहोस्',
  'Save my medicine list as a PDF': 'मेरा औषधिको सूची PDF मा सेभ गर्नुहोस्',
  'Could not refresh': 'नयाँ जानकारी ल्याउन सकिएन',
  'Could not load your medicines': 'तपाईंका औषधि ल्याउन सकिएन',
  'No medicines yet': 'अहिलेसम्म कुनै औषधि थपिएको छैन',
  'Add your first medicine to start getting reminders on time.':
      'समयमा सम्झना पाउन आफ्नो पहिलो औषधि थप्नुहोस्।',
  'Stopped ({n})': 'रोकिएका औषधि ({n})',
  'Medicine added': 'औषधि थपियो',
  'Medicine updated': 'औषधिको विवरण बदलियो',
  'Medicine deleted': 'औषधि हटाइयो',
  'Medicine stopped': 'औषधि रोकियो',
  'Medicine resumed': 'औषधि फेरि सुरु भयो',
  'Delete medicine?': 'औषधि हटाउने हो?',
  '"{name}", its reminders and its dose history will be removed. This cannot be undone.\n\nTo keep the history, stop the medicine instead.':
      '"{name}", यसको सम्झना र खाएको पुरानो हिसाब सबै हट्छ। हटाएपछि फिर्ता ल्याउन मिल्दैन।\n\nपुरानो हिसाब राख्न चाहनुहुन्छ भने औषधि नहटाउनुहोस्, बरु रोक्नुहोस्।',
  'Stop this medicine?': 'यो औषधि रोक्ने हो?',
  'You will get no more doses or reminders for "{name}". Its history is kept and you can resume it any time.':
      'अब "{name}" खाने समय र सम्झना आउँदैन। पुरानो हिसाब रहिरहन्छ र जुनसुकै बेला फेरि सुरु गर्न सकिन्छ।',
  'Stop': 'रोक्नुहोस्',

  // Medicine card
  'How to take & side effects': 'खाने तरिका र नराम्रो असर',
  'Add stock': 'औषधि थप्नुहोस्',
  'Stop medicine': 'औषधि रोक्नुहोस्',
  'Resume medicine': 'औषधि फेरि सुरु गर्नुहोस्',
  'Stopped · no doses or reminders': 'रोकिएको · खाने समय र सम्झना आउँदैन',
  'Reminders off': 'सम्झना बन्द',
  'Course finished': 'औषधि खाने अवधि सकियो',
  'Course: {doses} left · ends {date}': 'खान बाँकी: {doses} · {date} सम्म',

  // Schedule and stock summaries (medication_format.dart)
  'Every day': 'हरेक दिन',
  'As needed': 'चाहिएको बेला मात्र',
  'Mon': 'सोम',
  'Tue': 'मंगल',
  'Wed': 'बुध',
  'Thu': 'बिही',
  'Fri': 'शुक्र',
  'Sat': 'शनि',
  'Sun': 'आइत',
  '1 dose': '1 मात्रा',
  '{n} doses': '{n} मात्रा',
  '{doses} left': '{doses} बाँकी',
  '{amount} left ({doses})': '{amount} बाँकी ({doses})',
  'runs out today': 'आज सकिन्छ',
  'runs out tomorrow': 'भोलि सकिन्छ',
  'lasts {n} days': '{n} दिन पुग्छ',
  'Today: {left} of {doses} left': 'आज: {doses} मध्ये {left} खान बाँकी',
  'Today: {taken} of {total} taken': 'आज: {total} मध्ये {taken} खाइसक्नुभयो',

  // Medicine types (API values, see MedicationOptions.fallback)
  'Tablet': 'चक्की (ट्याब्लेट)',
  'Capsule': 'क्याप्सुल',
  'Syrup': 'झोल औषधि (सिरप)',
  'Injection': 'सुई',
  'Cream': 'क्रिम',
  'Ointment': 'मलम',
  'Gel': 'जेल',
  'Drops': 'थोपा औषधि (ड्रप)',
  'Inhaler': 'इन्हेलर',
  'Spray': 'स्प्रे',
  'Powder': 'धुलो औषधि (पाउडर)',
  'Patch': 'टाँस्ने औषधि (प्याच)',
  'Suppository': 'मलद्वारमा राख्ने औषधि',

  // When to take it (API values)
  'Before food': 'खाना खानुअघि',
  'After food': 'खाना खाएपछि',
  'With food': 'खानासँगै',
  'Empty stomach': 'खाली पेटमा',
  'Before sleep': 'सुत्नुअघि',
  'Anytime': 'जुनसुकै बेला',

  // Add stock
  '{name}: {amount} in stock now.': '{name}: अहिले {amount} बाँकी छ।',
  'Amount added': 'कति थप्नुभयो',
  'e.g. 30': 'जस्तै: 30',
  'Enter how much you added': 'कति थप्नुभयो लेख्नुहोस्',
  'Too many': 'धेरै भयो',

  // ---------------------------------------------------------------------------
  // Add medicine: choose how
  // ---------------------------------------------------------------------------
  'Enter manually': 'आफैं लेख्नुहोस्',
  'Type the name, dose and schedule': 'औषधिको नाम, मात्रा र खाने समय लेख्नुहोस्',
  'Scan prescription or label': 'पुर्जा वा लेबल स्क्यान गर्नुहोस्',
  'Take a photo and review what was read':
      'फोटो खिच्नुहोस् र पढिएको कुरा जाँच्नुहोस्',

  // ---------------------------------------------------------------------------
  // Add / edit medicine form
  // ---------------------------------------------------------------------------
  'Edit medicine': 'औषधि सच्याउनुहोस्',
  'Filled in from your scan. Check every detail against the prescription before saving.':
      'यो विवरण तपाईंले स्क्यान गरेको फोटोबाट भरिएको हो। सेभ गर्नुअघि हरेक कुरा पुर्जासँग दाँजेर हेर्नुहोस्।',
  'Name': 'नाम',
  'Medicine name': 'औषधिको नाम',
  'e.g. Paracetamol': 'जस्तै: Paracetamol',
  'Type': 'किसिम',
  'Type is required': 'किसिम छान्नुहोस्',
  'Dose': 'मात्रा',
  'e.g. 500 mg': 'जस्तै: 500 mg',
  'When to take it': 'कहिले खाने',
  'Choose when to take it': 'कहिले खाने हो छान्नुहोस्',
  'Instructions (optional)': 'खाने तरिका (नलेखे पनि हुन्छ)',
  'e.g. Take 1 tablet twice a day with water':
      'जस्तै: दिनको 2 पटक 1 चक्की पानीसँग खाने',

  // Schedule
  'Schedule': 'खाने समय',
  'Take on a schedule': 'तोकिएको समयमा खाने',
  'Set the times you take this medicine': 'यो औषधि कति बजे खाने हो राख्नुहोस्',
  'Off: taken only when needed': 'बन्द: चाहिएको बेला मात्र खाने',
  'Times': 'समय',
  'Add time': 'समय थप्नुहोस्',
  'Reminder time': 'सम्झाउने समय',
  'Days': 'बार',
  'Course dates (optional)': 'कहिलेदेखि कहिलेसम्म खाने (नलेखे पनि हुन्छ)',
  'Start': 'सुरु',
  'End': 'अन्तिम',
  'Start date': 'सुरु गर्ने मिति',
  'End date (last day)': 'सकिने मिति (अन्तिम दिन)',
  'Clear {label} date': '{label} मिति हटाउनुहोस्',
  'Add at least one reminder time': 'कम्तीमा एउटा समय थप्नुहोस्',
  'Select at least one day': 'कम्तीमा एउटा बार छान्नुहोस्',
  'Remind me': 'मलाई सम्झाउनुहोस्',
  'Alert me with': 'कसरी सम्झाउने',
  'Notification': 'सूचना',
  'Alarm': 'अलार्म',
  'Rings with your alarm sound at alarm volume and vibrates strongly.':
      'अलार्मकै आवाजमा ठूलो स्वरले बज्छ र फोन बेस्सरी थर्किन्छ।',
  'A normal notification with its usual sound.':
      'अरू सूचना जस्तै सामान्य आवाजमा आउँछ।',

  // Stock and refills
  'Stock and refills': 'बाँकी औषधि र किन्ने सम्झना',
  'Track my stock': 'मेरो औषधि कति बाँकी छ हिसाब राख्नुहोस्',
  'Each dose you mark as taken is deducted':
      'औषधि खाएँ भनेर जनाएको हरेक पटक गन्ती घट्छ',
  'Off: no stock count or refill reminders':
      'बन्द: बाँकी औषधिको हिसाब र किन्ने सम्झना आउँदैन',
  'In stock now': 'अहिले कति बाँकी छ',
  'Used per dose': 'एक पटकमा कति चाहिन्छ',
  'e.g. 1': 'जस्तै: 1',
  'Count in your own unit: tablets, ml, puffs...':
      'जसरी गन्नुहुन्छ त्यसरी नै लेख्नुहोस्: चक्की, ml, पफ...',
  'Remind me to refill': 'औषधि सकिन लागेपछि सम्झाउनुहोस्',
  'Only on the day it runs out': 'औषधि सकिने दिन मात्र',
  '1 day before it runs out': 'औषधि सकिनुभन्दा 1 दिन अघि',
  '{n} days before it runs out': 'औषधि सकिनुभन्दा {n} दिन अघि',
  'Fewer days': 'दिन घटाउनुहोस्',
  'More days': 'दिन बढाउनुहोस्',
  'You get one reminder, on the day your stock runs out.':
      'औषधि सकिने दिन एक पटक सम्झना आउँछ।',
  'You get a second reminder on the day your stock runs out.':
      'औषधि सकिने दिन फेरि एक पटक सम्झना आउँछ।',
  'Refill reminders need a schedule. Without one the stock is only counted.':
      'औषधि किन्ने सम्झना आउन खाने समय राख्नुपर्छ। समय नराखे बाँकी औषधिको गन्ती मात्र हुन्छ।',

  // ---------------------------------------------------------------------------
  // Scan a prescription or label
  // ---------------------------------------------------------------------------
  'Scan medicine': 'औषधि स्क्यान गर्नुहोस्',
  'Scan a prescription or label': 'पुर्जा वा लेबल स्क्यान गर्नुहोस्',
  'Take a clear photo of printed text. MediSathi reads the medicine names and doses on your phone, and you check each one before it is saved.':
      'छापिएको अक्षरको प्रस्ट फोटो खिच्नुहोस्। MediSathi ले औषधिको नाम र मात्रा तपाईंकै फोनमा पढ्छ। सेभ हुनुअघि हरेक औषधि तपाईं आफैंले जाँच्न पाउनुहुन्छ।',
  'Works best with printed text. Handwriting is often misread.':
      'छापिएको अक्षर राम्ररी पढिन्छ। हातले लेखेको अक्षर प्रायः गलत पढिन्छ।',
  'Reading the picture...': 'फोटो पढ्दै छ...',
  'No medicines were found in that picture. Try a sharper, well-lit photo, or add it manually.':
      'त्यो फोटोमा कुनै औषधि भेटिएन। अझ प्रस्ट र उज्यालोमा खिचेको फोटो राखेर हेर्नुहोस्, वा औषधि आफैं लेख्नुहोस्।',
  'Found 1 medicine': '1 औषधि भेटियो',
  'Found {n} medicines': '{n} औषधि भेटिए',
  'Scans can be wrong. Open each one, compare it with your prescription, then save it.':
      'स्क्यान गर्दा गल्ती हुन सक्छ। हरेक औषधि खोलेर आफ्नो पुर्जासँग दाँज्नुहोस्, अनि मात्र सेभ गर्नुहोस्।',
  'Review & add': 'जाँचेर थप्नुहोस्',
  'Added': 'थपियो',
  'Scan another': 'अर्को स्क्यान गर्नुहोस्',
  'Save to Health Records': 'स्वास्थ्य कागजपत्रमा राख्नुहोस्',
  'Saved to Health Records': 'स्वास्थ्य कागजपत्रमा राखियो',
  'Keep this prescription photo in your Prescriptions folder':
      'पुर्जाको यो फोटो "डाक्टरको पुर्जा" फोल्डरमा राख्नुहोस्',
  'Find it under Profile > Health Records':
      'प्रोफाइल > स्वास्थ्य कागजपत्रमा भेटिन्छ',
  'Allow camera and photo access in Settings to scan.':
      'स्क्यान गर्न फोनको सेटिङमा गएर क्यामेरा र फोटो चलाउने अनुमति दिनुहोस्।',
  'Could not read the picture. Please try again.':
      'फोटो पढ्न सकिएन। फेरि प्रयास गर्नुहोस्।',
  'Scanning is not available on this device.': 'यो फोनमा स्क्यान गर्न मिल्दैन।',

  // ---------------------------------------------------------------------------
  // Medicine details
  // ---------------------------------------------------------------------------
  'This medicine is no longer in your list.': 'यो औषधि अब तपाईंको सूचीमा छैन।',
  'Add a photo': 'फोटो राख्नुहोस्',
  'Change photo': 'फोटो फेर्नुहोस्',
  'Remove photo': 'फोटो हटाउनुहोस्',
  'A photo of the strip or bottle makes the medicine easy to recognise. It is also shown in the reminder.':
      'औषधिको पत्ता वा बोतलको फोटो राखे औषधि चिन्न सजिलो हुन्छ। यो फोटो सम्झनामा पनि देखिन्छ।',
  'Could not open the camera or gallery. Check the app permissions.':
      'क्यामेरा वा ग्यालरी खुलेन। एपलाई अनुमति दिइएको छ कि छैन हेर्नुहोस्।',
  'How to take it': 'कसरी खाने',
  'Your instructions': 'तपाईंले लेखेको तरिका',
  'What it is for': 'यो औषधि केका लागि हो',
  'Possible side effects': 'हुन सक्ने नराम्रो असर',
  'Get help if': 'यस्तो भए डाक्टरकहाँ जानुहोस्',

  // Saving the medicine list as a PDF (the PDF itself stays in English)
  'Save my medicine list': 'मेरा औषधिको सूची सेभ गर्नुहोस्',
  'Medicine list saved to your phone': 'औषधिको सूची तपाईंको फोनमा सेभ भयो',
  'Open': 'खोल्नुहोस्',
  'Could not save the medicine list.': 'औषधिको सूची सेभ गर्न सकिएन।',
};
