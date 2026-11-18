/// Nepali texts, keyed by the English text. See ne.dart.
const Map<String, String> neAccount = {
  // ---------------------------------------------------------------------------
  // Sign in / sign up
  // ---------------------------------------------------------------------------
  'Something went wrong': 'केही गडबड भयो',
  'Welcome back': 'फेरि स्वागत छ',
  'Sign in to keep track of your medicines':
      'आफ्नो औषधिको हिसाब राख्न लग इन गर्नुहोस्',
  'Email': 'इमेल',
  'Password': 'पासवर्ड',
  'Sign in': 'लग इन गर्नुहोस्',
  'New to MediSathi?': 'MediSathi मा नयाँ हुनुहुन्छ?',
  'Create account': 'खाता खोल्नुहोस्',
  'Create your account': 'आफ्नो खाता खोल्नुहोस्',
  'Start your journey to never missing a dose':
      'अब औषधि खान कहिल्यै नबिर्सनुहोस्',
  'Full name': 'पूरा नाम',
  'Confirm password': 'पासवर्ड फेरि लेख्नुहोस्',
  'Already have an account?': 'पहिले नै खाता छ?',
  'Continue with Google': 'Google बाट अगाडि बढ्नुहोस्',
  'or': 'वा',
  'MediSathi logo': 'MediSathi को लोगो',
  'I have read and agree to the {terms} and {privacy}.':
      'मैले {terms} र {privacy} पढेको छु र म यसमा सहमत छु।',
  'By continuing, you agree to our {terms} and {privacy}.':
      'अगाडि बढ्नुभयो भने तपाईं हाम्रा {terms} र {privacy} मा सहमत हुनुहुन्छ।',
  'Terms & Conditions': 'नियम र सर्तहरू',
  'Privacy Policy': 'गोपनीयता नीति',
  'Please accept the Terms & Conditions and Privacy Policy to continue.':
      'अगाडि बढ्न नियम र सर्तहरू अनि गोपनीयता नीति मान्नुपर्छ।',

  // Form checks (core/utils/validators.dart).
  '{label} is required': '{label} लेख्नुहोस्',
  'Email is required': 'इमेल लेख्नुहोस्',
  'Enter a valid email address': 'इमेल ठीकसँग लेख्नुहोस्',
  'Password is required': 'पासवर्ड लेख्नुहोस्',
  'Use at least 8 characters': 'कम्तीमा 8 अक्षर राख्नुहोस्',
  'Please confirm your password': 'पासवर्ड फेरि लेख्नुहोस्',
  'Passwords do not match': 'दुवै पासवर्ड मिलेन',

  // ---------------------------------------------------------------------------
  // Error messages
  // ---------------------------------------------------------------------------
  'The server is taking too long to respond. It may be waking up, please try again in a moment.':
      'सर्भरले जवाफ दिन धेरै समय लगायो। एकछिन पछि फेरि प्रयास गर्नुहोस्।',
  'Cannot reach the server. Please check your internet connection.':
      'सर्भरसँग जोडिन सकिएन। इन्टरनेट चलेको छ कि छैन हेर्नुहोस्।',
  'This feature is not available on the server yet. Please try again later.':
      'यो सुविधा अहिले चलेको छैन। पछि फेरि प्रयास गर्नुहोस्।',
  'Incorrect email or password.': 'इमेल वा पासवर्ड मिलेन।',
  'An account with this email already exists.':
      'यो इमेलबाट पहिले नै खाता खोलिएको छ।',
  'Please check the details you entered.':
      'तपाईंले लेखेको विवरण फेरि हेर्नुहोस्।',
  'Server error. Please try again later.':
      'सर्भरमा समस्या आयो। पछि फेरि प्रयास गर्नुहोस्।',
  'Something went wrong. Please try again.':
      'केही गडबड भयो। फेरि प्रयास गर्नुहोस्।',
  'Your session has expired. Please sign in again.':
      'धेरै समय भयो। फेरि लग इन गर्नुहोस्।',
  'Unexpected response from the server.': 'सर्भरबाट ठीक जवाफ आएन।',
  'Google sign-in is not enabled on the server yet.':
      'Google बाट लग इन गर्ने सुविधा अहिले चलेको छैन।',
  'Sign-in cancelled': 'लग इन रद्द भयो',
  'Could not sign out.': 'लग आउट गर्न सकिएन।',
  'Could not read login status': 'लग इन भएको छ कि छैन थाहा पाउन सकिएन',
  'Could not read user': 'तपाईंको जानकारी पढ्न सकिएन',
  'Could not read onboarding status': 'सुरुको जानकारी पढ्न सकिएन',
  'Could not save onboarding status': 'सुरुको जानकारी राख्न सकिएन',

  // ---------------------------------------------------------------------------
  // Splash and onboarding
  // ---------------------------------------------------------------------------
  'Your friend in taking medicine': 'औषधि खान सम्झाउने तपाईंको साथी',
  'Your companion for never missing a dose':
      'औषधि खान बिर्सन नदिने तपाईंको साथी',
  'Skip': 'छोड्नुहोस्',
  'Next': 'अर्को',
  'Back': 'पछाडि',
  'I already have an account': 'मेरो खाता पहिले नै छ',
  'Never miss a dose': 'औषधि खान कहिल्यै नबिर्सनुहोस्',
  'Gentle reminders at the right time, every day, so taking your medicines becomes a habit.':
      'हरेक दिन ठीक समयमा सम्झना आउँछ, अनि औषधि खाने बानी बस्छ।',
  'Add medicines your way': 'आफ्नै तरिकाले औषधि थप्नुहोस्',
  'Snap a photo of your prescription and we will read it for you, or enter medicines manually.':
      'डाक्टरको पुर्जाको फोटो खिच्नुहोस्, हामी पढिदिन्छौं। नभए औषधिको नाम आफैं लेख्नुहोस्।',
  'Track your progress': 'आफ्नो प्रगति हेर्नुहोस्',
  'See your daily, weekly and monthly adherence and build streaks that keep you going.':
      'हरेक दिन, हप्ता र महिनामा कति औषधि समयमा खानुभयो हेर्नुहोस् र यो बानी नछुटाउनुहोस्।',
  'Never run out': 'औषधि सकिन नदिनुहोस्',
  'Know how many pills are left and get an alert before it is time to refill.':
      'कति चक्की बाँकी छ थाहा पाउनुहोस्। सकिनुअघि नै औषधि किन्ने सम्झना आउँछ।',

  // ---------------------------------------------------------------------------
  // App tour
  // ---------------------------------------------------------------------------
  'Welcome to MediSathi': 'MediSathi मा स्वागत छ',
  'Take a quick tour to see where everything is. It only takes a few seconds.':
      'कुन कुरा कहाँ छ, छोटकरीमा हेरौं। केही सेकेन्ड मात्र लाग्छ।',
  'Tell us how you are feeling, see today\'s doses and tap "Take" when you take a medicine.':
      'आज कस्तो महसुस भइरहेको छ भन्नुहोस्, आजका औषधि हेर्नुहोस् र औषधि खाएपछि "खानुहोस्" थिच्नुहोस्।',
  'Notifications': 'सूचनाहरू',
  'Dose reminders and refill alerts are collected here.':
      'औषधि खाने सम्झना र औषधि सकिन लागेको सूचना यहाँ भेटिन्छ।',
  'Add medicines by typing them in or by scanning a prescription. Track stock and get refill alerts.':
      'औषधिको नाम लेखेर वा पुर्जा स्क्यान गरेर औषधि थप्नुहोस्। कति बाँकी छ हेर्नुहोस् र सकिनुअघि सूचना पाउनुहोस्।',
  'See which doses you took, skipped or missed over the last days and weeks.':
      'पछिल्ला दिन र हप्तामा कुन औषधि खानुभयो, छोड्नुभयो वा बिर्सनुभयो हेर्नुहोस्।',
  'Health Records for prescriptions and reports, weight and blood pressure, and period and pregnancy trackers.':
      'पुर्जा र रिपोर्ट राख्ने स्वास्थ्य कागजपत्र, तौल र ब्लड प्रेसर, अनि महिनावारी पात्रो र गर्भ पात्रो यहाँ छन्।',
  'Menu': 'मेनु',
  'Switch between light and dark mode, replay this tour, get help, send feedback, read our policies or sign out.':
      'यहाँबाट उज्यालो वा अँध्यारो रूप छान्न, यो परिचय फेरि हेर्न, मद्दत लिन, सुझाव पठाउन, हाम्रा नीति पढ्न वा लग आउट गर्न सकिन्छ।',
  'You\'re all set!': 'सबै तयार भयो!',
  'Add your first medicine and MediSathi will remind you when it\'s time. You can replay this tour from the Profile menu.':
      'आफ्नो पहिलो औषधि थप्नुहोस्, समय भएपछि MediSathi ले सम्झाउँछ। यो परिचय प्रोफाइलको मेनुबाट फेरि हेर्न सकिन्छ।',
  'Get started': 'सुरु गर्नुहोस्',

  // ---------------------------------------------------------------------------
  // Profile menu
  // ---------------------------------------------------------------------------
  'Appearance': 'एपको रूप',
  'System': 'फोनअनुसार',
  'Light': 'उज्यालो',
  'Dark': 'अँध्यारो',
  'About': 'एपको जानकारी',
  'App tour': 'एपको परिचय',
  'See how MediSathi works': 'MediSathi कसरी चल्छ हेर्नुहोस्',
  'Help & support': 'मद्दत र सहयोग',
  'FAQs and contact': 'प्रश्न-उत्तर र सम्पर्क',
  'Send feedback': 'सुझाव पठाउनुहोस्',
  'Ideas, problems, praise': 'सुझाव, समस्या, तारिफ',
  'About the app': 'यो एपको बारेमा',
  'About us': 'हाम्रो बारेमा',
  'Account': 'खाता',
  'Delete account': 'खाता हटाउनुहोस्',
  'Request deletion by email': 'इमेल पठाएर खाता हटाउन भन्नुहोस्',
  'Sign out': 'लग आउट गर्नुहोस्',
  'Settings': 'सेटिङ',

  // ---------------------------------------------------------------------------
  // Profile
  // ---------------------------------------------------------------------------
  'Delete your account?': 'खाता हटाउने हो?',
  'To delete your account, send us an email from the address you signed up with. We will delete your account and all its data - medicines, health records, readings and trackers - within 30 days and reply to confirm.':
      'खाता हटाउन, खाता खोल्दा राखेको इमेलबाट हामीलाई इमेल पठाउनुहोस्। हामी 30 दिनभित्र तपाईंको खाता र त्यसका सबै जानकारी (औषधि, स्वास्थ्य कागजपत्र, नाप र हिसाब) हटाउँछौं र हटाएको खबर इमेलमा पठाउँछौं।',
  'To delete your account, send us an email from the address you signed up with ({email}). We will delete your account and all its data - medicines, health records, readings and trackers - within 30 days and reply to confirm.':
      'खाता हटाउन, खाता खोल्दा राखेको इमेल ({email}) बाट हामीलाई इमेल पठाउनुहोस्। हामी 30 दिनभित्र तपाईंको खाता र त्यसका सबै जानकारी (औषधि, स्वास्थ्य कागजपत्र, नाप र हिसाब) हटाउँछौं र हटाएको खबर इमेलमा पठाउँछौं।',
  'Cancel': 'रद्द गर्नुहोस्',
  'Write email': 'इमेल लेख्नुहोस्',
  'No email app found. Email {support} from {email} to request deletion.':
      'इमेल एप भेटिएन। खाता हटाउन {email} बाट {support} मा इमेल पठाउनुहोस्।',
  'Sign out?': 'लग आउट गर्ने हो?',
  'You will stop getting medicine reminders on this phone until you sign in again.':
      'फेरि लग इन नगरेसम्म यो फोनमा औषधि खाने सम्झना आउँदैन।',
  'Edit profile': 'प्रोफाइल सच्याउनुहोस्',
  'MediSathi user': 'MediSathi प्रयोगकर्ता',
  'About me': 'मेरो बारेमा',
  'Today': 'आज',
  'My health': 'मेरो स्वास्थ्य',
  'Could not load your details': 'तपाईंको विवरण ल्याउन सकिएन',
  'None added': 'केही थपिएको छैन',
  'Not set': 'राखिएको छैन',
  'Age': 'उमेर',
  '1 year': '1 वर्ष',
  '{n} years': '{n} वर्ष',
  'Gender': 'लिङ्ग',
  'Male': 'पुरुष',
  'Female': 'महिला',
  'Other': 'अन्य',
  'Blood group': 'ब्लड ग्रुप',
  'Diseases & conditions': 'रोग र स्वास्थ्य समस्या',
  'Allergies': 'एलर्जी',
  'The period and pregnancy trackers are shown when your gender is set to female.':
      'लिङ्गमा महिला छान्नुभयो भने महिनावारी पात्रो र गर्भ पात्रो देखिन्छ।',
  'Health Records': 'स्वास्थ्य कागजपत्र',
  'Prescriptions, lab reports & documents': 'पुर्जा, ल्याब रिपोर्ट र कागजात',
  'Weight & vitals': 'तौल र स्वास्थ्य नाप',
  'Weight, height, BMI, blood pressure': 'तौल, उचाइ, BMI, ब्लड प्रेसर',
  'Period tracker': 'महिनावारी पात्रो',
  'Cycle calendar & predictions': 'महिनावारीको पात्रो र अनुमान',
  'Pregnancy tracker': 'गर्भ पात्रो',
  'Week by week to your due date':
      'बच्चा जन्मने दिनसम्म हप्ता-हप्ताको जानकारी',

  // Edit profile
  'Try again': 'फेरि प्रयास गर्नुहोस्',
  'Date of birth': 'जन्म मिति',
  'Still saving, please wait.': 'सेभ हुँदैछ, एकछिन पर्खनुहोस्।',
  'Profile saved': 'प्रोफाइल सेभ भयो',
  'Enter your name': 'आफ्नो नाम लेख्नुहोस्',
  'Clear': 'हटाउनुहोस्',
  '1 year old': '1 वर्ष',
  '{n} years old': '{n} वर्ष',
  'Add another disease': 'अर्को रोग थप्नुहोस्',
  'Add another allergy': 'अर्को एलर्जी थप्नुहोस्',
  'Add': 'थप्नुहोस्',
  'Save': 'सेभ गर्नुहोस्',

  // Suggested diseases
  'Diabetes': 'मधुमेह (सुगर)',
  'High blood pressure': 'हाई ब्लड प्रेसर',
  'Heart disease': 'मुटुको रोग',
  'Asthma': 'दम',
  'Thyroid disorder': 'थाइराइड',
  'High cholesterol': 'कोलेस्टेरोल बढी',
  'Kidney disease': 'मिर्गौलाको रोग',
  'Arthritis': 'बाथ',
  'Migraine': 'माइग्रेन',
  'Epilepsy': 'छारे रोग',
  'Tuberculosis': 'क्षयरोग (टिबी)',
  'Anaemia': 'रगतको कमी',

  // Suggested allergies
  'Penicillin': 'पेनिसिलिन',
  'Sulfa drugs': 'सल्फा औषधि',
  'Aspirin': 'एस्पिरिन',
  'Ibuprofen': 'आइबुप्रोफेन',
  'Peanuts': 'बदाम',
  'Seafood': 'समुद्री माछा र झिँगे',
  'Eggs': 'अण्डा',
  'Milk': 'दूध',
  'Dust': 'धुलो',
  'Pollen': 'फूलको धुलो (पराग)',
  'Latex': 'लेटेक्स (रबर)',

  // ---------------------------------------------------------------------------
  // About the app
  // ---------------------------------------------------------------------------
  'Version {version}': 'भर्सन {version}',
  'What MediSathi does': 'MediSathi ले के गर्छ',
  'Dose reminders': 'औषधि खाने सम्झना',
  'Alerts at the right local time, even across time zones.':
      'तपाईं जहाँ भए पनि त्यहाँको ठीक समयमा सम्झना आउँछ।',
  'Scan prescriptions': 'पुर्जा स्क्यान गर्नुहोस्',
  'Add medicines from a photo. Text is read on your phone.':
      'फोटोबाट औषधि थप्नुहोस्। फोटोको अक्षर तपाईंकै फोनमा पढिन्छ।',
  'Track adherence': 'औषधि खाएको हिसाब',
  'See taken, skipped and missed doses over time.':
      'कुन औषधि खानुभयो, छोड्नुभयो वा बिर्सनुभयो हेर्नुहोस्।',
  'Refill alerts': 'औषधि सकिन लागेको सूचना',
  'Know before a medicine runs out.': 'औषधि सकिनुअघि नै थाहा पाउनुहोस्।',
  'Important': 'ध्यान दिनुहोस्',
  '{app} helps you remember and track your medicines. It is not medical advice. Always follow your doctor\'s or pharmacist\'s instructions.':
      '{app} ले औषधि खान सम्झाउँछ र त्यसको हिसाब राख्छ। यो डाक्टरको सल्लाह होइन। सधैं आफ्नो डाक्टर वा औषधि पसलेले भनेअनुसार गर्नुहोस्।',
  'Legal': 'कानुनी जानकारी',
  'Open-source licences': 'ओपन सोर्स लाइसेन्स',
  'Last updated: {date}': 'पछिल्लो पटक फेरिएको: {date}',

  // ---------------------------------------------------------------------------
  // About us
  // ---------------------------------------------------------------------------
  'Our mission': 'हाम्रो लक्ष्य',
  'Help everyone take the right medicine at the right time.':
      'सबैलाई ठीक औषधि ठीक समयमा खान सघाउने।',
  'Who we are': 'हामी को हौं',
  '{app} ("Sathi" means companion) is made by {publisher} in {country}. We saw how easy it is to forget a dose, run out of a medicine, or lose track of a family member\'s treatment, so we built a simple companion that reminds, tracks and helps you stay on schedule.':
      '{app} {country}मा {publisher}ले बनाएको हो। औषधि खान बिर्सिने, औषधि सकिने वा परिवारको उपचारको हिसाब हराउने कुरा सजिलै हुन्छ। त्यसैले हामीले सम्झाउने, हिसाब राख्ने र समयमा औषधि खान सघाउने यो सजिलो साथी बनायौं।',
  'MediSathi Team': 'MediSathi टिम',
  'Nepal': 'नेपाल',
  'What we value': 'हामी के कुरामा ध्यान दिन्छौं',
  'Care first': 'पहिले हेरचाह',
  'Built for patients, families and caregivers.':
      'बिरामी, परिवार र हेरचाह गर्नेहरूका लागि बनाइएको।',
  'Private by design': 'तपाईंको कुरा गोप्य रहन्छ',
  'Your health data is never sold or used for ads.':
      'तपाईंको स्वास्थ्यको जानकारी कहिल्यै बेचिँदैन, विज्ञापनमा पनि चलाइँदैन।',
  'Simple to use': 'चलाउन सजिलो',
  'Clear screens and big buttons for every age.':
      'सबै उमेरका लागि प्रस्ट स्क्रिन र ठूला बटन।',
  'Get in touch': 'हामीलाई सम्पर्क गर्नुहोस्',
  'Email us': 'हामीलाई इमेल गर्नुहोस्',
  'No email app found. Write to {email}':
      'इमेल एप भेटिएन। {email} मा लेख्नुहोस्',

  // ---------------------------------------------------------------------------
  // Feedback
  // ---------------------------------------------------------------------------
  'Suggestion': 'सुझाव',
  'Problem': 'समस्या',
  'Compliment': 'तारिफ',
  'Could not send': 'पठाउन सकिएन',
  '{error}\n\nYou can send it by email instead.':
      '{error}\n\nबरु इमेलबाट पठाउन सक्नुहुन्छ।',
  'Use email': 'इमेलबाट पठाउनुहोस्',
  'Thank you! Your feedback was sent.': 'धन्यवाद! तपाईंको सुझाव पठाइयो।',
  'We read every message. Tell us what you like, what is confusing, or what we should build next.':
      'हामी हरेक सन्देश पढ्छौं। तपाईंलाई के मन पर्‍यो, के बुझ्न गाह्रो भयो वा अब के थप्नुपर्छ, हामीलाई भन्नुहोस्।',
  'How do you like MediSathi?': 'MediSathi कस्तो लाग्यो?',
  '1 star': '1 तारा',
  '{n} stars': '{n} तारा',
  'Topic': 'विषय',
  'Your message': 'तपाईंको सन्देश',
  'Write your feedback here': 'आफ्नो कुरा यहाँ लेख्नुहोस्',
  'Please write a few words': 'केही शब्द लेख्नुहोस्',
  'Your app version and phone type are sent with your message to help us fix problems.':
      'समस्या ठीक गर्न सजिलो होस् भनेर तपाईंको सन्देशसँगै एपको भर्सन र फोनको किसिम पनि पठाइन्छ।',

  // ---------------------------------------------------------------------------
  // Help & support
  // ---------------------------------------------------------------------------
  'Frequently asked questions': 'धेरैले सोध्ने प्रश्नहरू',
  'How do I add a medicine?': 'औषधि कसरी थप्ने?',
  'Open the Medicine tab and tap the + button. Choose "Enter manually" to type the details, or "Scan prescription or label" to fill them in from a photo.':
      'तलको "औषधि" मा जानुहोस् र + बटन थिच्नुहोस्। विवरण आफैं लेख्न "आफैं लेख्नुहोस्" छान्नुहोस्, वा फोटोबाट भर्न "पुर्जा वा लेबल स्क्यान गर्नुहोस्" छान्नुहोस्।',
  'I am not getting reminders': 'मलाई सम्झना आइरहेको छैन',
  'Make sure notifications are allowed for MediSathi in your phone settings, and that you are signed in. Some phones stop apps in the background to save battery: set MediSathi to "Unrestricted" or "Not optimised" in battery settings.':
      'फोनको सेटिङमा MediSathi लाई सूचना (नोटिफिकेसन) पठाउन दिइएको छ कि छैन र तपाईं लग इन हुनुहुन्छ कि छैन हेर्नुहोस्। कुनै फोनले ब्याट्री जोगाउन एपलाई पछाडि चल्न दिँदैन। त्यसैले फोनको ब्याट्री सेटिङमा MediSathi लाई "Unrestricted" वा "Not optimised" मा राख्नुहोस्।',
  'How do I mark a dose as taken?': 'औषधि खाएँ भनेर कसरी जनाउने?',
  'On the Dashboard, tap "Take" next to the dose. You can also tap a reminder notification to open it.':
      'ड्यासबोर्डमा औषधिको छेउमा रहेको "खानुहोस्" थिच्नुहोस्। सम्झनाको सूचना थिचेर पनि खोल्न सकिन्छ।',
  'How does refill tracking work?': 'औषधि सकिन लागेको कसरी थाहा हुन्छ?',
  'Turn on "Track my stock" when adding or editing a medicine. Each dose you mark as taken lowers the count, and you get an alert before it runs out. Use "Add stock" from the medicine\'s menu after a refill.':
      'औषधि थप्दा वा सच्याउँदा "मेरो औषधि कति बाँकी छ हिसाब राख्नुहोस्" खोल्नुहोस्। औषधि खाएँ भनेर जनाएको हरेक पटक गन्ती घट्छ र सकिनुअघि सूचना आउँछ। औषधि किनेपछि त्यो औषधिको मेनुबाट "औषधि थप्नुहोस्" थिच्नुहोस्।',
  'Can I pause a medicine?': 'कुनै औषधि केही समय रोक्न मिल्छ?',
  'Yes. In the Medicine tab, open the medicine\'s menu and choose "Stop medicine". It keeps its history but stops doses and reminders until you resume it.':
      'मिल्छ। "औषधि" मा गएर त्यो औषधिको मेनु खोल्नुहोस् र "औषधि रोक्नुहोस्" छान्नुहोस्। पुरानो हिसाब रहिरहन्छ, तर फेरि सुरु नगरेसम्म त्यो औषधि र त्यसको सम्झना रोकिन्छ।',
  'Where are my prescriptions and reports stored?':
      'मेरा पुर्जा र रिपोर्ट कहाँ राखिन्छन्?',
  'Go to Profile and open Health Records. Prescriptions and other documents (lab reports, scans, discharge summaries) are kept in separate folders. Tap Upload to add a photo or PDF. After scanning a prescription you can also choose "Save to Health Records".':
      'प्रोफाइलमा गएर "स्वास्थ्य कागजपत्र" खोल्नुहोस्। पुर्जा र अरू कागजात (ल्याब रिपोर्ट, स्क्यान, अस्पतालबाट निस्कँदाको कागज) छुट्टाछुट्टै फोल्डरमा राखिन्छन्। फोटो वा PDF थप्न "अपलोड गर्नुहोस्" थिच्नुहोस्। पुर्जा स्क्यान गरेपछि "स्वास्थ्य कागजपत्रमा राख्नुहोस्" पनि छान्न सकिन्छ।',
  'How do I track weight, blood pressure or my period?':
      'तौल, ब्लड प्रेसर वा महिनावारीको हिसाब कसरी राख्ने?',
  'Open Profile and choose Weight & vitals, Period tracker or Pregnancy tracker. Your mood check-in is on the Dashboard.':
      'प्रोफाइल खोलेर "तौल र स्वास्थ्य नाप", "महिनावारी पात्रो" वा "गर्भ पात्रो" छान्नुहोस्। आज कस्तो महसुस भयो भनेर जनाउने ठाउँ ड्यासबोर्डमा छ।',
  'How do I switch between light and dark mode?':
      'उज्यालो र अँध्यारो रूप कसरी फेर्ने?',
  'Go to Profile, tap the menu button at the top right, and choose Light, Dark or System under Appearance.':
      'प्रोफाइलमा गएर माथि दायाँको मेनु बटन थिच्नुहोस् र "एपको रूप" मुनि उज्यालो, अँध्यारो वा फोनअनुसार छान्नुहोस्।',
  'How do I delete my account?': 'मेरो खाता कसरी हटाउने?',
  'Open the Profile menu and tap "Delete account", or email {email} from the address you signed up with. We delete your account and all of its data within 30 days.':
      'प्रोफाइलको मेनु खोलेर "खाता हटाउनुहोस्" थिच्नुहोस्, वा खाता खोल्दा राखेको इमेलबाट {email} मा इमेल पठाउनुहोस्। हामी 30 दिनभित्र तपाईंको खाता र त्यसका सबै जानकारी हटाउँछौं।',
  'Still need help?': 'अझै मद्दत चाहियो?',
  'Contact support': 'सहयोगका लागि सम्पर्क गर्नुहोस्',
  'Report a problem': 'समस्या बताउनुहोस्',
  'Tell us what went wrong': 'के बिग्रियो हामीलाई भन्नुहोस्',
};
