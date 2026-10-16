/// Lightweight app localization for English, Luganda and Swahili.
///
/// This is intentionally dependency-free (no flutter_localizations gen-l10n)
/// so the app keeps working offline and on every platform.
library;

import 'package:flutter/widgets.dart';

enum AppLanguage {
  english('en', 'English'),
  luganda('lg', 'Luganda'),
  swahili('sw', 'Swahili');

  final String code;
  final String label;

  const AppLanguage(this.code, this.label);

  static AppLanguage fromCode(String? code) {
    switch (code) {
      case 'lg':
        return AppLanguage.luganda;
      case 'sw':
        return AppLanguage.swahili;
      default:
        return AppLanguage.english;
    }
  }
}

class AppStrings {
  AppStrings._();

  /// key → {en, lg, sw}
  static const Map<String, Map<String, String>> _strings = {
    // ── Common ──
    'common.save': {
      'en': 'Save',
      'lg': 'Kwekuumye',
      'sw': 'Hifadhi',
    },
    'common.cancel': {
      'en': 'Cancel',
      'lg': 'Sazaako',
      'sw': 'Ghairi',
    },
    'common.loading': {
      'en': 'Loading…',
      'lg': 'Liyimbira…',
      'sw': 'Inapakia…',
    },
    'common.retry': {
      'en': 'Retry',
      'lg': 'Kakirinza',
      'sw': 'Jaribu tena',
    },
    'common.tryAgain': {
      'en': 'Please try again.',
      'lg': 'Kakirinza gatte.',
      'sw': 'Tafadhali jaribu tena.',
    },
    'common.error': {
      'en': 'Something went wrong.',
      'lg': 'Waliwo ekitaagenda bulungi.',
      'sw': 'Kuna tatizo limetokea.',
    },
    'common.delete': {
      'en': 'Delete',
      'lg': 'Gyawo',
      'sw': 'Futa',
    },
    'common.send': {
      'en': 'Send',
      'lg': 'Tuma',
      'sw': 'Tuma',
    },
    'common.newEntry': {
      'en': 'New',
      'lg': 'Empya',
      'sw': 'Mpya',
    },
    'common.active': {
      'en': 'Active',
      'lg': 'Ekokola',
      'sw': 'Inatumika',
    },
    'common.inactive': {
      'en': 'Inactive',
      'lg': 'Teyeekola',
      'sw': 'Haijaikumika',
    },

    // ── Dark mode / preferences ──
    'settings.title': {
      'en': 'Settings & Appearance',
      'lg': 'Enteekateeka & Embeera',
      'sw': 'Mipangilio na Muonekano',
    },
    'settings.theme': {
      'en': 'Appearance',
      'lg': 'Embeera y’ekikulukanyo',
      'sw': 'Muonekano wa programu',
    },
    'settings.darkMode': {
      'en': 'Dark Mode',
      'lg': 'Enzikiza eya kyenvu',
      'sw': 'Hali ya giza',
    },
    'settings.language': {
      'en': 'Language',
      'lg': 'Olulimi',
      'sw': 'Lugha',
    },
    'settings.system': {
      'en': 'System',
      'lg': 'Siziteemu',
      'sw': 'Mfumo',
    },
    'settings.light': {
      'en': 'Light',
      'lg': 'Ekyekkye',
      'sw': 'Mwanga',
    },
    'settings.dark': {
      'en': 'Dark',
      'lg': 'Ekyekira',
      'sw': 'Giza',
    },

    // ── Scheduled pickups ──
    'schedules.title': {
      'en': 'Scheduled Pickups',
      'lg': 'Okukunganyizibwa Okwetekeddwa',
      'sw': 'Uchukuaji uliopangwa',
    },
    'schedules.emptyTitle': {
      'en': 'No scheduled pickups',
      'lg': 'Tewali kukunganyizibwa kwetekeddwa',
      'sw': 'Hakuna uchukuaji uliopangwa',
    },
    'schedules.emptyDesc': {
      'en': 'Set up a recurring pickup so waste gets collected on a regular day.',
      'lg': 'Tekateka okukunganyizibwa okuddira ddala okusobola okukunganya ekidduka ku lunaku olugere',
      'sw': 'Weka uchukuaji unaorudiwa ili taka ikusanywe siku ya kawaida.',
    },
    'schedules.add': {
      'en': 'Add Scheduled Pickup',
      'lg': 'Okukunganyizibwa Okwetekeddwa',
      'sw': 'Ongeza uchukuaji uliopangwa',
    },
    'schedules.frequency': {
      'en': 'Frequency',
      'lg': 'Emmirundi',
      'sw': 'Mara',
    },
    'schedules.weekday': {
      'en': 'Preferred Day',
      'lg': 'Lunaku Olwayagalwa',
      'sw': 'Siku unayopendelea',
    },
    'schedules.time': {
      'en': 'Preferred Time',
      'lg': 'Ssaawa Esinga Okwagalwa',
      'sw': 'Muda unayopendelea',
    },
    'schedules.address': {
      'en': 'Pickup Address',
      'lg': 'Endagiriro Eyakunganyizibwa',
      'sw': 'Anwani ya uchukuaji',
    },
    'schedules.weekly': {
      'en': 'Weekly',
      'lg': 'Buli wiiki',
      'sw': 'Kila wiki',
    },
    'schedules.biweekly': {
      'en': 'Every two weeks',
      'lg': 'Buli wiiki bbiri',
      'sw': 'Kila wiki mbili',
    },
    'schedules.monthly': {
      'en': 'Monthly',
      'lg': 'Buli mwezi',
      'sw': 'Kila mwezi',
    },
    'schedules.created': {
      'en': 'Scheduled pickup created.',
      'lg': 'Ekikunganyizibwa kyeketekeddwa.',
      'sw': 'Uchukuaji uliopangwa umeundwa.',
    },

    // ── Payments ──
    'payments.title': {
      'en': 'Payments & Receipts',
      'lg': 'Okusasulira & Amatilikiti',
      'sw': 'Malipo na Risiti',
    },
    'payments.emptyTitle': {
      'en': 'No payments yet',
      'lg': 'Tebinnasasulwa',
      'sw': 'Hakuna malipo bado',
    },
    'payments.emptyDesc': {
      'en': 'Your payment history and receipts will appear here.',
      'lg': 'Ebyafaayo by’okusasulira n’amatilikiti bijja kulabika wano.',
      'sw': 'Historia ya malipo yako na risiti zitaonekana hapa.',
    },
    'payments.receipt': {
      'en': 'Receipt',
      'lg': 'Etilikititi',
      'sw': 'Risiti',
    },
    'payments.invoice': {
      'en': 'Invoice',
      'lg': 'Envvooza',
      'sw': 'Ankara ya malipo',
    },
    'payments.paid': {
      'en': 'Paid',
      'lg': 'Kisasuddwa',
      'sw': 'Imelipwa',
    },
    'payments.pending': {
      'en': 'Pending',
      'lg': 'Kirondera',
      'sw': 'Inasubiri',
    },
    'payments.method': {
      'en': 'Method',
      'lg': 'Enkola',
      'sw': 'Njia',
    },
    'payments.transactionId': {
      'en': 'Transaction ID',
      'lg': 'Ennamba y’okuteeka',
      'sw': 'Namba ya muamala',
    },
    'payments.date': {
      'en': 'Date',
      'lg': 'Olunaku',
      'sw': 'Tarehe',
    },
    'payments.total': {
      'en': 'Total',
      'lg': 'Eggyera',
      'sw': 'Jumla',
    },

    // ── Ratings ──
    'ratings.title': {
      'en': 'Ratings & Reviews',
      'lg': 'Okulambika & Okukiririzibwa',
      'sw': 'Ukadiriaji na Maoni',
    },
    'ratings.rateCollector': {
      'en': 'Rate your collector',
      'lg': 'Lambika omukunganyizi wo',
      'sw': 'Kadiria mtoaji wako',
    },
    'ratings.avg': {
      'en': 'Average rating',
      'lg': 'Olambiko olwawamu',
      'sw': 'Ukadiriaji wa wastani',
    },
    'ratings.reviews': {
      'en': 'reviews',
      'lg': 'okulambika',
      'sw': 'maoni',
    },
    'ratings.yourReview': {
      'en': 'Share your experience (optional)',
      'lg': 'Laga ekyo ky’ogenda ng’atondeko (sikyalindiriddwa)',
      'sw': 'Taja uzoefu wako (si lazima)',
    },
    'ratings.submit': {
      'en': 'Submit Review',
      'lg': 'Tuma Okulambika',
      'sw': 'Weka Maoni',
    },
    'ratings.thankYou': {
      'en': 'Thank you for reviewing your collector.',
      'lg': 'Webale okulambika omukunganyizi wo.',
      'sw': 'Asante kwa kukadiria mtoaji wako.',
    },
    'ratings.emptyTitle': {
      'en': 'No reviews yet',
      'lg': 'Tekwali kulambika',
      'sw': 'Hakuna maoni bado',
    },
    'ratings.emptyDesc': {
      'en': 'Reviews help everyone choose trusted collectors.',
      'lg': 'Okulambika kuyamba buli omu okulonda abakunganyizi okukkirizibwa.',
      'sw': 'Maoni husaidia kila mtu kuchagua watoaji wanaoaminika.',
    },

    // ── Support ──
    'support.title': {
      'en': 'Help & Support',
      'lg': 'Obuyambi & Okutaasa',
      'sw': 'Usaidizi',
    },
    'support.newTicket': {
      'en': 'New Ticket',
      'lg': 'Tikiti Empya',
      'sw': 'Tiketi Mpya',
    },
    'support.subject': {
      'en': 'Subject',
      'lg': 'Etweka',
      'sw': 'Mada',
    },
    'support.category': {
      'en': 'Category',
      'lg': 'Essenge',
      'sw': 'Kategoria',
    },
    'support.priority': {
      'en': 'Priority',
      'lg': 'Kutikkirirako',
      'sw': 'Kipaumbele',
    },
    'support.message': {
      'en': 'Describe your issue…',
      'lg': 'Nnyonnyola ekizibu kyo…',
      'sw': 'Eleza tatizo lako…',
    },
    'support.emptyTitle': {
      'en': 'No support tickets',
      'lg': 'Tewali tikiti z’obuyambi',
      'sw': 'Hakuna tiketi za usaidizi',
    },
    'support.emptyDesc': {
      'en': 'Reach out and our team will help you.',
      'lg': 'Tumira obubaka, zamanja yaffe ejja kukuyamba.',
      'sw': 'Wasiliana nasi, timu yetu itakusaidia.',
    },
    'support.answered': {
      'en': 'In Progress',
      'lg': 'Kiri mu kukola',
      'sw': 'Inaendelea',
    },
    'support.closed': {
      'en': 'Closed',
      'lg': 'Ekizibwewo',
      'sw': 'Imefungwa',
    },
    'support.opened': {
      'en': 'Open',
      'lg': 'Egguliddwa',
      'sw': 'Imeanza',
    },
    'support.typeMessage': {
      'en': 'Type a message…',
      'lg': 'Wandiika obubaka…',
      'sw': 'Andika ujumbe…',
    },
    'support.ticketNo': {
      'en': 'Ticket',
      'lg': 'Tikiti',
      'sw': 'Tiketi',
    },
    'support.urgent': {
      'en': 'Urgent',
      'lg': 'Kyangu',
      'sw': 'Dharura',
    },

    // ── Chat ──
    'chat.title': {
      'en': 'Chat',
      'lg': 'Okukubaganya ebirowoozo',
      'sw': 'Mazungumzo',
    },
    'chat.emptyTitle': {
      'en': 'No conversations yet',
      'lg': 'Tebannakola nteesa',
      'sw': 'Hakuna mazungumzo bado',
    },
    'chat.emptyDesc': {
      'en': 'Once a collector is assigned to a request, you can chat here.',
      'lg': 'Ng’omukunganyizi ng’atuuzibwa ku kusaba, oyinza okukubaganya ebirowoozo wano.',
      'sw': 'Wakati mtoaji amekabidhiwa ombi, unaweza kuzungumza hapa.',
    },
    'chat.reference': {
      'en': 'Request',
      'lg': 'Okusaba',
      'sw': 'Ombi',
    },
    'chat.typeMessage': {
      'en': 'Message…',
      'lg': 'Obubaka…',
      'sw': 'Ujumbe…',
    },
    'chat.noCollector': {
      'en': 'No collector assigned yet. A chat will open once one is assigned.',
      'lg': 'Tewali mukunganyizi amanyiddwa. Ebyafaayo bijja kugulwa oluvannyuma.',
      'sw': 'Hakuna mtoaji aliyekabidhiwa bado. Mazungumzo yatafunguliwa akiishakabidhiwa.',
    },

    // ── Tracking ──
    'tracking.title': {
      'en': 'Live Tracking',
      'lg': 'Okukolera ekiddisa',
      'sw': 'Ufuatiliaji wa moja kwa moja',
    },
    'tracking.collector': {
      'en': 'Collector location live',
      'lg': 'Envuunzirwa omukunganyizi ekolera ekiddisa',
      'sw': 'Eneo la mtoaji linarushwa moja kwa moja',
    },
    'tracking.distance': {
      'en': 'Distance',
      'lg': 'Otanga',
      'sw': 'Umbalio',
    },
    'tracking.eta': {
      'en': 'ETA',
      'lg': 'Ekiseera kikomawo',
      'sw': 'Muda wa kufika',
    },
    'tracking.status': {
      'en': 'Status',
      'lg': 'Embeera',
      'sw': 'Hali',
    },
    'tracking.noLocation': {
      'en': 'Waiting for the collector’s location…',
      'lg': 'Kulinda envoogho z’omukunganyizi…',
      'sw': 'Tunasubiri eneo la mtoaji…',
    },

    // ── Analytics ──
    'analytics.title': {
      'en': 'Analytics',
      'lg': 'Okusengejja obubaka',
      'sw': 'Takwimu',
    },
    'analytics.overview': {
      'en': 'Overview',
      'lg': 'Omulondo',
      'sw': 'Muhtasari',
    },
    'analytics.financials': {
      'en': 'Financials',
      'lg': 'Ebyenfuna',
      'sw': 'Fedha',
    },
    'analytics.revenue': {
      'en': 'Gross Revenue',
      'lg': 'Omugagga gwonna',
      'sw': 'Mapato yote',
    },
    'analytics.payouts': {
      'en': 'Collector Payouts',
      'lg': 'Okusasulirwa aba kunganizi',
      'sw': 'Malipo ya watoaji',
    },
    'analytics.netMargin': {
      'en': 'Net Margin',
      'lg': 'Navu nagganda',
      'sw': 'Faida halisi',
    },
    'analytics.users': {
      'en': 'Users',
      'lg': 'Abakozesa',
      'sw': 'Watumiaji',
    },
    'analytics.requests': {
      'en': 'Requests',
      'lg': 'Okusaba',
      'sw': 'Maombi',
    },
    'analytics.weight': {
      'en': 'Waste Collected',
      'lg': 'Ekidduka Ekikunganyiziddwa',
      'sw': 'Taka lililokusanywa',
    },
    'analytics.reports': {
      'en': 'Illegal Reports',
      'lg': 'Okubuuza ng etali ya mateeka',
      'sw': 'Ripoti za haramu',
    },
    'analytics.hotspots': {
      'en': 'Hotspots',
      'lg': 'Ebifo ebirimu obungi',
      'sw': 'Maeneo ya hatari',
    },
    'analytics.severity': {
      'en': 'Severity',
      'lg': 'Obuzibu',
      'sw': 'Ukali',
    },

    // ── Zones ──
    'zones.title': {
      'en': 'Zone Assignment',
      'lg': 'Okutuuzibwa ku Sone',
      'sw': 'Ugawaji wa Kanda',
    },
    'zones.assign': {
      'en': 'Assign Zone',
      'lg': 'Tuuzibwa ku Sone',
      'sw': 'Gawa Kanda',
    },
    'zones.collector': {
      'en': 'Collector',
      'lg': 'Omukunganyizi',
      'sw': 'Mtoaji',
    },
    'zones.zone': {
      'en': 'Zone',
      'lg': 'Sone',
      'sw': 'Kanda',
    },
    'zones.selectCollector': {
      'en': 'Select a collector',
      'lg': 'Londa omukunganyizi',
      'sw': 'Chagua mtoaji',
    },
    'zones.selectZone': {
      'en': 'Select a zone',
      'lg': 'Londa sone',
      'sw': 'Chagua kanda',
    },
    'zones.noCollectors': {
      'en': 'No collectors found.',
      'lg': 'Tebali bakunganyizi basangibwa.',
      'sw': 'Hakuna watoaji waliopatikana.',
    },
    'zones.noZones': {
      'en': 'No zones created yet.',
      'lg': 'Tebannakola sone.',
      'sw': 'Hakuna kanda bado.',
    },

    // ── Onboarding ──
    'onboarding.title': {
      'en': 'Welcome to Tweyonje',
      'lg': 'Kaale mu Tweyonje',
      'sw': 'Karibu Tweyonje',
    },
    'onboarding.skip': {
      'en': 'Skip',
      'lg': 'Leka',
      'sw': 'Ruka',
    },
    'onboarding.next': {
      'en': 'Next',
      'lg': 'Ekidda',
      'sw': 'Ifuatayo',
    },
    'onboarding.getStarted': {
      'en': 'Get Started',
      'lg': 'Tandika',
      'sw': 'Anza',
    },
    'onboarding.s1Title': {
      'en': 'Request waste pickup',
      'lg': 'Saba okukunganyizibwa kwa kidduka',
      'sw': 'Omba uchukuaji wa taka',
    },
    'onboarding.s1Desc': {
      'en': 'Schedule a pickup, pay easily, and track your collector in real time.',
      'lg': 'Tekateka okukunganyizibwa, usasule mu ngeri eyangu, otegeerezenga omukunganyizi wo ekiddisa.',
      'sw': 'Panga uchukuaji, lipa kwa urahisi, na ufuatilie mtoaji wako moja kwa moja.',
    },
    'onboarding.s2Title': {
      'en': 'Earn eco-points',
      'lg': 'Funnga eppoin ntali z’embeera',
      'sw': 'Pata alama za mazingira',
    },
    'onboarding.s2Desc': {
      'en': 'Recycle, report illegal dumping, and redeem rewards for your community work.',
      'lg': "Zungulula, okuubete ku kidduka ekitali kya mateeka, era owolekye z'apooli za mu kyaalo kyo.",
      'sw': 'Rejesha taka, ripoti utupaji haramu, na ubadilishane zawadi kwa kazi yako ya jamii.',
    },
    'onboarding.s3Title': {
      'en': 'Together for a cleaner Uganda',
      'lg': 'Wamu okulyoka Uganda etongole',
      'sw': 'Pamoja kwa Uganda safi',
    },
    'onboarding.s3Desc': {
      'en': 'Join collectors and local communities making waste management simple.',
      'lg': 'Yingira wamu n’abakunganyizi n’ebitundu ebikola okukunganya awamu aba omuwangufu.',
      'sw': 'Jiunge na watoaji na jamii zinazorahisisha usimamizi wa taka.',
    },

    // ── Auth: Login ──
    'auth.signIn': {
      'en': 'Sign In',
      'lg': 'Yingira',
      'sw': 'Ingia',
    },
    'auth.signInSubtitle': {
      'en': 'Access your pickups, earnings, and eco-points',
      'lg': 'Funa ebyokukunganya byo, eby’okuwumulwa, n’eppoin ntali zo',
      'sw': 'Pata uchukuaji wako, mapato, na alama za mazingira',
    },
    'auth.signInButton': {
      'en': 'Sign In to Tweyonje',
      'lg': 'Yingira mu Tweyonje',
      'sw': 'Ingia kwenye Tweyonje',
    },
    'auth.emailOrPhone': {
      'en': 'Email or Phone Number',
      'lg': 'Email oba Ennamba ya Essimu',
      'sw': 'Barua pepe au Namba ya Simu',
    },
    'auth.emailOrPhoneHint': {
      'en': 'e.g. resident@tweyonje.ug or +256704567936',
      'lg': 'okuge. resident@tweyonje.ug oba +256704567936',
      'sw': 'mfano resident@tweyonje.ug au +256704567936',
    },
    'auth.emailOrPhoneRequired': {
      'en': 'Please enter your email or phone',
      'lg': 'Teeka email yo oba ennamba ya essimu yo',
      'sw': 'Tafadhali weka barua pepe yako au namba ya simu',
    },
    'auth.emailOrPhoneInvalid': {
      'en': 'Enter a valid email or Ugandan phone number',
      'lg': 'Teeka email oba ennamba ya essimu ey’Uganda eyangu',
      'sw': 'Weka barua pepe sahihi au namba ya simu ya Uganda',
    },
    'auth.password': {
      'en': 'Password',
      'lg': 'Ekisumuluzo',
      'sw': 'Nenosiri',
    },
    'auth.passwordRequired': {
      'en': 'Please enter your password',
      'lg': 'Teeka ekisumuluzo kyo',
      'sw': 'Tafadhali weka nenosiri lako',
    },
    'auth.rememberMe': {
      'en': 'Remember me',
      'lg': 'Njukira',
      'sw': 'Nikumbuke',
    },
    'auth.forgotPassword': {
      'en': 'Forgot Password?',
      'lg': 'Weyongedde ekisumuluzo?',
      'sw': 'Umesahau nenosiri?',
    },
    'auth.biometricSignIn': {
      'en': 'Biometric Sign In',
      'lg': 'Yingira nga ttumya ebifaananyi by’omukono',
      'sw': 'Ingia kwa vitambulisho vya mwili',
    },
    'auth.noAccount': {
      'en': "Don't have an account?",
      'lg': 'Tokozzeeko akaawunti?',
      'sw': 'Huna akaunti?',
    },
    'auth.createAccount': {
      'en': 'Create Account',
      'lg': 'Kuwa Akaawunti',
      'sw': 'Fungua Akaunti',
    },

    // ── Auth: Register ──
    'auth.joinTweyonje': {
      'en': 'Join Tweyonje',
      'lg': 'Yingira mu Tweyonje',
      'sw': 'Jiunge na Tweyonje',
    },
    'auth.createYourAccount': {
      'en': 'Create Your Account',
      'lg': 'Kuwa Akaawunti Yo',
      'sw': 'Fungua Akaunti Yako',
    },
    'auth.registeringAs': {
      'en': 'I AM REGISTERING AS:',
      'lg': 'NNYINZA OKUWANDIKA NGA:',
      'sw': 'NAJISAJILI KAMA:',
    },
    'auth.fullName': {
      'en': 'Full Name',
      'lg': 'Erinnya Lyonna',
      'sw': 'Jina Kamili',
    },
    'auth.fullNameRequired': {
      'en': 'Please enter your full name',
      'lg': 'Teeka erinnya lyonna',
      'sw': 'Tafadhali weka jina lako kamili',
    },
    'auth.email': {
      'en': 'Email Address',
      'lg': 'Addiresi ya Email',
      'sw': 'Anwani ya Barua Pepe',
    },
    'auth.emailRequired': {
      'en': 'Email is required',
      'lg': 'Email y’okukola',
      'sw': 'Barua pepe inahitajika',
    },
    'auth.emailInvalid': {
      'en': 'Please enter a valid email address',
      'lg': 'Teeka email eyangu',
      'sw': 'Tafadhali weka barua pepe sahihi',
    },
    'auth.phone': {
      'en': 'Phone Number (Mobile Money)',
      'lg': 'Ennamba ya Essimu (Mobile Money)',
      'sw': 'Namba ya Simu (M-Pesa)',
    },
    'auth.phoneHint': {
      'en': 'e.g. 0704 567 936',
      'lg': 'okuge. 0704 567 936',
      'sw': 'mfano 0704 567 936',
    },
    'auth.phoneInvalid': {
      'en': 'Enter a valid Ugandan phone number',
      'lg': 'Teeka ennamba ya essimu ey’Uganda eyangu',
      'sw': 'Weka namba ya simu sahihi ya Uganda',
    },
    'auth.passwordHint': {
      'en': 'At least 8 characters',
      'lg': 'Ebibuuzo 8 oba nnyingi',
      'sw': 'Herufi 8 au zaidi',
    },
    'auth.confirmPassword': {
      'en': 'Confirm Password',
      'lg': 'Kakasa Ekisumuluzo',
      'sw': 'Thibitisha Nenosiri',
    },
    'auth.passwordsNoMatch': {
      'en': 'Passwords do not match',
      'lg': 'Ebisumuluzo tebifanana',
      'sw': 'Menosiri hayalingani',
    },
    'auth.agreeTermsPrefix': {
      'en': 'I agree to the ',
      'lg': 'Nkubiriza ku ',
      'sw': 'Nakubaliana na ',
    },
    'auth.termsOfService': {
      'en': 'Terms of Service',
      'lg': 'Ebikwata ku Kola',
      'sw': 'Masharti ya Huduma',
    },
    'auth.and': {
      'en': ' & ',
      'lg': ' ne ',
      'sw': ' na ',
    },
    'auth.privacyPolicy': {
      'en': 'Privacy Policy',
      'lg': 'Ebyuma by’Ebikubo',
      'sw': 'Sera za Faragha',
    },
    'auth.agreeTermsSuffix': {
      'en': '',
      'lg': '',
      'sw': '',
    },
    'auth.acceptTerms': {
      'en': 'Please accept the Terms of Service to continue',
      'lg': 'Kakasa ebikwata ku kola oluvannyuma olwokugenda munda',
      'sw': 'Tafadhali kubaliana na Masharti ya Huduma ili kuendelea',
    },
    'auth.createMyAccount': {
      'en': 'Create My Account',
      'lg': 'Kuwa Akaawunti Yange',
      'sw': 'Fungua Akaunti Yangu',
    },
    'auth.haveAccount': {
      'en': 'Already have an account?',
      'lg': 'Ozzeddemu akaawunti?',
      'sw': 'Tayari una akaunti?',
    },

    // ── Auth: OTP ──
    'auth.verifyAccount': {
      'en': 'Verify your account',
      'lg': 'Kakasa akaawunti yo',
      'sw': 'Thibitisha akaunti yako',
    },
    'auth.otpSentTo': {
      'en': 'We sent a verification code to',
      'lg': 'Tutadde ko ekifaananyi ekikakasa eri',
      'sw': 'Tumeshahi msimbo wa uthibitisho kwa',
    },
    'auth.enterOtp': {
      'en': 'Enter the code you received.',
      'lg': 'Teeka ekifaananyi ekyakaggyewo.',
      'sw': 'Weka msimbo uliopokea.',
    },
    'auth.verifyCode': {
      'en': 'Verify Code',
      'lg': 'Kakasa Ekifaananyi',
      'sw': 'Thibitisha Msimbo',
    },
    'auth.resendCode': {
      'en': 'Resend code',
      'lg': 'Ddamu otumeko ekifaananyi',
      'sw': 'Tuma msimbo tena',
    },
    'auth.resendIn': {
      'en': 'Resend code in',
      'lg': 'Ddamu otumeko ekifaananyi mu',
      'sw': 'Tuma msimbo tena baada ya',
    },
    'auth.seconds': {
      'en': 's',
      'lg': 's',
      'sw': 's',
    },
    'auth.skip': {
      'en': 'Skip',
      'lg': 'Sambako',
      'sw': 'Ruka',
    },
    'auth.verified': {
      'en': 'Your account is now verified.',
      'lg': 'Akaawunti yo kaakakaziddwa.',
      'sw': 'Akaunti yako sasa imethibitishwa.',
    },
    'auth.devCodeLabel': {
      'en': 'Dev code',
      'lg': 'Ekifaananyi ey’omu nkola',
      'sw': 'Msimbo wa majaribio',
    },

    // ── Auth: Password reset ──
    'auth.resetPassword': {
      'en': 'Reset Password',
      'lg': 'Zzaako Ekisumuluzo',
      'sw': 'Weka Upya Nenosiri',
    },
    'auth.resetPasswordSubtitle': {
      'en': 'Enter your registered email address and we will send you a reset code.',
      'lg': 'Teeka email yo eya ku ntapu era tukutumeko ekifaananyi ekizzaako.',
      'sw': 'Weka barua pepe yako iliyosajiliwa na tutakutumia msimbo wa kuiweka upya.',
    },
    'auth.sendResetCode': {
      'en': 'Send Reset Code',
      'lg': 'Tumeko Ekifaananyi',
      'sw': 'Tuma Msimbo wa Kuweka Upya',
    },
    'auth.resetEmailLabel': {
      'en': 'Email Address',
      'lg': 'Addiresi ya Email',
      'sw': 'Anwani ya Barua Pepe',
    },
    'auth.resetEmailRequired': {
      'en': 'Please enter a valid email address',
      'lg': 'Teeka email eyangu',
      'sw': 'Tafadhali weka barua pepe sahihi',
    },
    'auth.resetCodeLabel': {
      'en': 'Reset Code',
      'lg': 'Ekifaananyi',
      'sw': 'Msimbo wa Kuweka Upya',
    },
    'auth.resetCodeRequired': {
      'en': 'Please enter the reset code',
      'lg': 'Teeka ekifaananyi ekizzaako',
      'sw': 'Tafadhali weka msimbo wa kuweka upya',
    },
    'auth.newPassword': {
      'en': 'New Password',
      'lg': 'Ekisumuluzo Ekiggya',
      'sw': 'Nenosiri Jipya',
    },
    'auth.newPasswordRequired': {
      'en': 'New password must be at least 8 characters',
      'lg': 'Ekisumuluzo ekiggya kiyinza okuba ebibuuzo 8 oba nnyingi',
      'sw': 'Nenosiri jipya lazima liwe na herufi 8 au zaidi',
    },
    'auth.confirmNewPassword': {
      'en': 'Confirm New Password',
      'lg': 'Kakasa Ekisumuluzo Ekiggya',
      'sw': 'Thibitisha Nenosiri Jipya',
    },
    'auth.updatePassword': {
      'en': 'Update Password',
      'lg': 'Kyawulo Ekisumuluzo',
      'sw': 'Sasisha Nenosiri',
    },
    'auth.resetSuccess': {
      'en': 'Password updated. You can now sign in.',
      'lg': 'Ekisumuluzo kikyusiddwa. Osaana okuyingira.',
      'sw': 'Nenosiri imesasishwa. Sasa unaweza kuingia.',
    },
    'auth.resetSent': {
      'en': 'If that email is registered, a reset code has been sent.',
      'lg': 'Bwe email eyo eya ku ntapu, ekifaananyi kizzeeko.',
      'sw': 'Ikiwa barua pepe hiyo imesajiliwa, msimbo umetumwa.',
    },

    // ── Auth: errors ──
    'auth.loginFailed': {
      'en': 'Login failed. Please check your credentials.',
      'lg': 'Okuyingira kulemereddwa. Kebera ebizibu byo.',
      'sw': 'Kuingia kumeshindwa. Tafadhali angalia taarifa zako.',
    },
    'auth.registerFailed': {
      'en': 'Registration failed. Please check your information.',
      'lg': 'Okuwandika kulemereddwa. Kebera ebifa ku ntapu.',
      'sw': 'Usajili umeshindwa. Tafadhali angalia taarifa zako.',
    },
  };

  static String tr(String key, String lang) {
    final entry = _strings[key];
    if (entry == null) return key;
    return entry[lang] ?? entry['en'] ?? key;
  }
}

/// Provides the active [AppLanguage] down the widget tree so that
/// `BuildContext.tr(...)` can resolve dynamically without watching providers.
class TranslationsScope extends InheritedWidget {
  final AppLanguage language;

  const TranslationsScope({
    super.key,
    required this.language,
    required super.child,
  });

  static TranslationsScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<TranslationsScope>();

  @override
  bool updateShouldNotify(TranslationsScope oldWidget) =>
      oldWidget.language != language;
}

extension TranslationX on BuildContext {
  /// Returns the localized string for [key] using the current app language.
  String tr(String key) {
    final lang = TranslationsScope.maybeOf(this)?.language ??
        AppLanguage.english;
    return AppStrings.tr(key, lang.code);
  }
}