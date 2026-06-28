final Map<String, dynamic> contraceptionDataEn = {
  "tabs": [
    "Hormonal",
    "LARC", // Long-Acting Reversible
    "Barrier",
    "Permanent",
    "Emergency",
    "Natural"
  ],
  "endorsementTitle": "WHO Endorsement",
  "endorsementDesc": "The best method of contraception depends on your health, lifestyle, and personal preferences. This guide provides information based on WHO recommendations to help you make an informed choice. Always discuss options with a healthcare provider.",
  "methodsSuffix": "Methods",
  "methodLabels": {
    "effectiveness": "Effectiveness",
    "pros": "Advantages",
    "cons": "Things to Consider",
    "bestFor": "Best For:"
  },
  "methods": {
    "pills": {
      "name": "Combined Oral Contraceptive Pill",
      "effectiveness": "91%",
      "description": "A daily pill containing estrogen and progestin to prevent ovulation.",
      "pros": ["Highly effective if taken correctly", "Can regulate periods", "Reduces menstrual cramps"],
      "cons": ["Must be taken daily at same time", "Does not protect against STIs", "May have side effects (nausea, headaches)"],
      "bestFor": "Women who can remember to take a pill every day."
    },
    "patch": {
      "name": "Contraceptive Patch",
      "effectiveness": "91%",
      "description": "A small patch worn on the skin that releases hormones. Changed weekly.",
      "pros": ["Easy to use", "Only needs to be changed once a week", "Can regulate periods"],
      "cons": ["Visible on skin", "Does not protect against STIs", "May cause skin irritation"],
      "bestFor": "Women who prefer a weekly rather than daily routine."
    },
    "ring": {
      "name": "Vaginal Ring",
      "effectiveness": "91%",
      "description": "A flexible ring placed in the vagina that releases hormones. Left in for 3 weeks.",
      "pros": ["Only needs changing once a month", "Easy to insert and remove", "Lower hormone dose than pills"],
      "cons": ["Requires comfort with vaginal insertion", "Does not protect against STIs", "May increase vaginal discharge"],
      "bestFor": "Women comfortable with inserting the ring and who want a monthly routine."
    },
    "injection": {
      "name": "Contraceptive Injection",
      "effectiveness": "94%",
      "description": "An injection of progestogen given every 1 to 3 months depending on the type.",
      "pros": ["Lasts for months", "Highly private", "Can stop periods altogether"],
      "cons": ["Requires clinic visits", "Does not protect against STIs", "May delay return to fertility"],
      "bestFor": "Women who want a highly effective method without daily or weekly tasks."
    },
    "implant": {
      "name": "Contraceptive Implant",
      "effectiveness": "99%",
      "description": "A small, flexible rod placed under the skin of the upper arm. Lasts up to 3-5 years.",
      "pros": ["Highly effective", "Lasts for years", "Can be removed anytime", "Safe during breastfeeding"],
      "cons": ["Requires minor procedure", "Can cause irregular bleeding", "Does not protect against STIs"],
      "bestFor": "Women who want long-term, highly effective, 'fit and forget' contraception."
    },
    "iudCopper": {
      "name": "Copper IUD",
      "effectiveness": "99%",
      "description": "A small, T-shaped device with copper wire placed in the uterus. Lasts up to 5-10 years.",
      "pros": ["Highly effective", "Hormone-free", "Lasts for years", "Can be used as emergency contraception"],
      "cons": ["Requires clinic procedure", "May cause heavier, more painful periods", "Does not protect against STIs"],
      "bestFor": "Women who want highly effective, hormone-free, long-term contraception."
    },
    "iudHormonal": {
      "name": "Hormonal IUD",
      "effectiveness": "99%",
      "description": "A small, T-shaped device placed in the uterus that releases progestin. Lasts 3-7 years.",
      "pros": ["Highly effective", "Lasts for years", "Often makes periods lighter and less painful", "Can be removed anytime"],
      "cons": ["Requires clinic procedure", "May cause irregular spotting initially", "Does not protect against STIs"],
      "bestFor": "Women who want highly effective, long-term contraception and lighter periods."
    },
    "maleCondom": {
      "name": "Male Condom",
      "effectiveness": "82%",
      "description": "A thin sheath rolled onto the erect penis before sex to prevent pregnancy and STIs.",
      "pros": ["Protects against STIs including HIV", "Easy to buy and use", "No hormones", "Used only when needed"],
      "cons": ["Can break or slip off", "Requires partner cooperation", "Effectiveness relies on correct use"],
      "bestFor": "Anyone who needs protection from STIs and pregnancy without hormones."
    },
    "femaleCondom": {
      "name": "Female Condom",
      "effectiveness": "79%",
      "description": "A soft, loose-fitting pouch inserted into the vagina before sex to prevent pregnancy.",
      "pros": ["Protects against STIs including HIV", "Can be inserted up to 8 hours before sex", "No prescription required", "Non-hormonal option"],
      "cons": ["Less effective than male condoms", "Can be noisy during sex", "Requires proper insertion technique"],
      "bestFor": "Women who want STI protection and control over their contraception."
    },
    "diaphragm": {
      "name": "Diaphragm",
      "effectiveness": "83%",
      "description": "A shallow, dome-shaped cup inserted into the vagina to cover the cervix and block sperm.",
      "pros": ["Reusable and lasts for several years", "Non-hormonal option", "Can be inserted up to 6 hours before sex"],
      "cons": ["Requires fitting by healthcare provider", "Must be used with spermicide", "Does not protect against STIs"],
      "bestFor": "Women who want a reusable, non-hormonal barrier method."
    },
    "vasectomy": {
      "name": "Vasectomy (Male Sterilization)",
      "effectiveness": "99%",
      "description": "A minor surgical procedure to cut or block the tubes that carry sperm, preventing them from leaving the body.",
      "pros": ["Permanent and highly effective", "A one-time procedure with quick recovery", "No lasting effect on sex drive"],
      "cons": ["Permanent - reversal is difficult", "Does not become effective immediately", "Does not protect against STIs"],
      "bestFor": "Men or couples who are certain they do not want any more children."
    },
    "tubal": {
      "name": "Tubal Ligation (Female Sterilization)",
      "effectiveness": "99%",
      "description": "A surgical procedure to permanently block or remove the fallopian tubes.",
      "pros": ["Permanent and highly effective", "Effective immediately", "No hormonal side effects"],
      "cons": ["Surgical procedure with associated risks", "Permanent - reversal is major surgery", "Does not protect against STIs"],
      "bestFor": "Women or couples who are certain they do not want any more children."
    },
    "emergencyPills": {
      "name": "Emergency Contraceptive Pills (ECPs)",
      "effectiveness": "95%",
      "description": "Pills that can be taken up to 5 days after unprotected sex to prevent pregnancy.",
      "pros": ["A safe option to prevent pregnancy after unprotected sex", "Available over-the-counter in many places", "No prescription required"],
      "cons": ["Not as effective as regular contraception", "Can cause temporary side effects", "Should not be used regularly"],
      "bestFor": "Emergency situations only - not for regular use."
    },
    "emergencyIud": {
      "name": "Copper IUD (Emergency Use)",
      "effectiveness": "99%",
      "description": "A copper IUD inserted within 5 days of unprotected sex as emergency contraception.",
      "pros": ["Most effective form of emergency contraception", "Can be left in for ongoing contraception", "Hormone-free option"],
      "cons": ["Requires insertion by healthcare provider", "May cause cramping", "Higher upfront cost"],
      "bestFor": "Those who want the most effective emergency contraception and ongoing protection."
    },
    "fam": {
      "name": "Fertility Awareness Methods (FAM)",
      "effectiveness": "76-88%",
      "description": "Tracking menstrual cycle to identify fertile days and avoid sex or use barrier methods during those times.",
      "pros": ["No physical side effects", "No cost after learning", "Helps understand your body"],
      "cons": ["Requires consistent tracking", "Less effective than other methods", "Does not protect against STIs"],
      "bestFor": "Those with regular cycles who want a natural method and are willing to track carefully."
    },
    "withdrawal": {
      "name": "Withdrawal (Pull-Out Method)",
      "effectiveness": "78%",
      "description": "The man withdraws his penis from the vagina before ejaculation to prevent sperm from entering.",
      "pros": ["No cost", "No devices or hormones needed", "Always available"],
      "cons": ["High failure rate", "Requires self-control", "Does not protect against STIs"],
      "bestFor": "Couples who understand the risks and are comfortable with higher failure rates."
    },
    "lam": {
      "name": "Lactational Amenorrhea Method (LAM)",
      "effectiveness": "98%",
      "description": "Temporary contraception after childbirth based on exclusive breastfeeding that suppresses ovulation.",
      "pros": ["Natural and no cost", "Provides optimal nutrition for baby", "Promotes bonding"],
      "cons": ["Only effective for up to 6 months postpartum", "Requires exclusive breastfeeding day and night", "Does not protect against STIs"],
      "bestFor": "New mothers who are exclusively breastfeeding and whose period has not yet returned."
    }
  }
};

final Map<String, dynamic> contraceptionDataHi = {
  "tabs": [
    "हार्मोनल",
    "LARC (लंबे समय तक)",
    "बैरियर (अवरोध)",
    "स्थायी",
    "आपातकालीन",
    "प्राकृतिक"
  ],
  "endorsementTitle": "WHO द्वारा समर्थित",
  "endorsementDesc": "गर्भनिरोधक का सबसे अच्छा तरीका आपके स्वास्थ्य, जीवनशैली और व्यक्तिगत प्राथमिकताओं पर निर्भर करता है। यह मार्गदर्शिका आपको सूचित विकल्प बनाने में मदद करने के लिए WHO की सिफारिशों पर आधारित जानकारी प्रदान करती है। हमेशा स्वास्थ्य सेवा प्रदाता के साथ विकल्पों पर चर्चा करें।",
  "methodsSuffix": "तरीके",
  "methodLabels": {
    "effectiveness": "प्रभावशीलता",
    "pros": "लाभ",
    "cons": "विचार करने योग्य बातें",
    "bestFor": "इनके लिए सर्वोत्तम:"
  },
  "methods": {
    "pills": {
      "name": "संयुक्त मौखिक गर्भनिरोधक गोली (पिल)",
      "effectiveness": "91%",
      "description": "ओव्यूलेशन को रोकने के लिए एस्ट्रोजन और प्रोजेस्टिन युक्त दैनिक गोली।",
      "pros": ["सही ढंग से लेने पर अत्यधिक प्रभावी", "मासिक धर्म को नियमित कर सकती है", "मासिक धर्म में ऐंठन कम करती है"],
      "cons": ["प्रतिदिन एक ही समय पर लेनी चाहिए", "STI से बचाव नहीं करती", "साइड इफेक्ट्स (मतली, सिरदर्द) हो सकते हैं"],
      "bestFor": "ऐसी महिलाएँ जो रोज़ाना गोली याद रख सकती हैं।"
    },
    "patch": {
      "name": "गर्भनिरोधक पैच",
      "effectiveness": "91%",
      "description": "त्वचा पर पहना जाने वाला एक छोटा पैच जो हार्मोन छोड़ता है। हर हफ़्ते बदला जाता है।",
      "pros": ["उपयोग में आसान", "हफ्ते में सिर्फ एक बार बदलना पड़ता है", "मासिक धर्म नियमित कर सकता है"],
      "cons": ["त्वचा पर दिखाई देता है", "STI से बचाव नहीं करता", "त्वचा में जलन पैदा कर सकता है"],
      "bestFor": "ऐसी महिलाएँ जो रोज़ाना के बजाय साप्ताहिक दिनचर्या पसंद करती हैं।"
    },
    "ring": {
      "name": "वेजाइनल रिंग (योनि छल्ला)",
      "effectiveness": "91%",
      "description": "योनि में रखा जाने वाला लचीला रिंग जो हार्मोन छोड़ता है। 3 सप्ताह के लिए छोड़ दिया जाता है।",
      "pros": ["महीने में केवल एक बार बदलना पड़ता है", "डालने और निकालने में आसान", "गोलियों की तुलना में कम हार्मोन की खुराक"],
      "cons": ["योनि में डालने के साथ सहजता की आवश्यकता है", "STI से बचाव नहीं करती", "योनि स्राव बढ़ा सकती है"],
      "bestFor": "ऐसी महिलाएँ जो रिंग डालने में सहज हैं और मासिक दिनचर्या चाहती हैं।"
    },
    "injection": {
      "name": "गर्भनिरोधक इंजेक्शन",
      "effectiveness": "94%",
      "description": "प्रकार के आधार पर हर 1 से 3 महीने में प्रोजेस्टोजन का इंजेक्शन दिया जाता है।",
      "pros": ["महीनों तक रहता है", "अत्यधिक निजी (प्राइवेट)", "मासिक धर्म पूरी तरह से बंद हो सकता है"],
      "cons": ["क्लिनिक जाने की आवश्यकता है", "STI से बचाव नहीं करता", "प्रजनन क्षमता लौटने में देरी हो सकती है"],
      "bestFor": "ऐसी महिलाएँ जो दैनिक या साप्ताहिक काम के बिना अत्यधिक प्रभावी तरीका चाहती हैं।"
    },
    "implant": {
      "name": "गर्भनिरोधक इम्प्लांट",
      "effectiveness": "99%",
      "description": "ऊपरी बांह की त्वचा के नीचे रखी एक छोटी, लचीली छड़। 3-5 साल तक चलती है।",
      "pros": ["अत्यधिक प्रभावी", "वर्षों तक चलता है", "कभी भी हटाया जा सकता है", "स्तनपान के दौरान सुरक्षित"],
      "cons": ["मामूली प्रक्रिया की आवश्यकता होती है", "अनियमित रक्तस्राव हो सकता है", "STI से बचाव नहीं करता"],
      "bestFor": "ऐसी महिलाएँ जो लंबे समय तक चलने वाला, अत्यधिक प्रभावी, 'लगाओ और भूल जाओ' गर्भनिरोधक चाहती हैं।"
    },
    "iudCopper": {
      "name": "कॉपर IUD (कॉपर टी)",
      "effectiveness": "99%",
      "description": "तांबे के तार वाला एक छोटा, टी-आकार का उपकरण गर्भाशय में रखा जाता है। 5-10 साल तक चलता है।",
      "pros": ["अत्यधिक प्रभावी", "हार्मोन-मुक्त", "वर्षों तक चलता है", "आपातकालीन गर्भनिरोधक के रूप में इस्तेमाल किया जा सकता है"],
      "cons": ["क्लिनिक प्रक्रिया की आवश्यकता है", "मासिक धर्म भारी और अधिक दर्दनाक हो सकता है", "STI से बचाव नहीं करता"],
      "bestFor": "ऐसी महिलाएँ जो अत्यधिक प्रभावी, हार्मोन-मुक्त, दीर्घकालिक गर्भनिरोधक चाहती हैं।"
    },
    "iudHormonal": {
      "name": "हार्मोनल IUD",
      "effectiveness": "99%",
      "description": "गर्भाशय में रखा जाने वाला टी-आकार का उपकरण जो प्रोजेस्टिन छोड़ता है। 3-7 साल तक चलता है।",
      "pros": ["अत्यधिक प्रभावी", "वर्षों तक चलता है", "मासिक धर्म हल्का और कम दर्दनाक बनाता है", "कभी भी हटाया जा सकता है"],
      "cons": ["क्लिनिक प्रक्रिया की आवश्यकता है", "शुरुआत में अनियमित स्पॉटिंग हो सकती है", "STI से बचाव नहीं करता"],
      "bestFor": "ऐसी महिलाएँ जो अत्यधिक प्रभावी, दीर्घकालिक गर्भनिरोधक और हल्के मासिक धर्म चाहती हैं।"
    },
    "maleCondom": {
      "name": "पुरुष कंडोम",
      "effectiveness": "82%",
      "description": "गर्भधारण और STI को रोकने के लिए सेक्स से पहले इरेक्ट लिंग पर लगाया जाने वाला एक पतला आवरण।",
      "pros": ["एचआईवी सहित STI से बचाता है", "खरीदने और उपयोग करने में आसान", "कोई हार्मोन नहीं", "केवल आवश्यकता होने पर उपयोग किया जाता है"],
      "cons": ["टूट या फिसल सकता है", "पार्टनर के सहयोग की आवश्यकता होती है", "प्रभावशीलता सही उपयोग पर निर्भर करती है"],
      "bestFor": "कोई भी व्यक्ति जिसे बिना हार्मोन के STI और गर्भावस्था से सुरक्षा चाहिए।"
    },
    "femaleCondom": {
      "name": "महिला कंडोम",
      "effectiveness": "79%",
      "description": "गर्भावस्था को रोकने के लिए सेक्स से पहले योनि में डाला जाने वाला एक नरम पाउच।",
      "pros": ["एचआईवी सहित STI से बचाता है", "सेक्स से 8 घंटे पहले तक डाला जा सकता है", "बिना पर्ची के उपलब्ध", "गैर-हार्मोनल विकल्प"],
      "cons": ["पुरुष कंडोम की तुलना में कम प्रभावी", "सेक्स के दौरान शोर कर सकता है", "सही ढंग से डालने की तकनीक की आवश्यकता है"],
      "bestFor": "ऐसी महिलाएँ जो STI सुरक्षा और अपने गर्भनिरोधक पर नियंत्रण चाहती हैं।"
    },
    "diaphragm": {
      "name": "डायाफ्राम",
      "effectiveness": "83%",
      "description": "सर्विक्स को कवर करने और शुक्राणु को रोकने के लिए योनि में डाला जाने वाला एक उथला, गुंबद के आकार का कप।",
      "pros": ["पुन: प्रयोज्य और कई वर्षों तक चलता है", "गैर-हार्मोनल विकल्प", "सेक्स से 6 घंटे पहले तक डाला जा सकता है"],
      "cons": ["स्वास्थ्य सेवा प्रदाता द्वारा फिटिंग की आवश्यकता होती है", "शुक्राणुनाशक के साथ इस्तेमाल किया जाना चाहिए", "STI से बचाव नहीं करता"],
      "bestFor": "ऐसी महिलाएँ जो एक पुन: प्रयोज्य, गैर-हार्मोनल अवरोधक तरीका चाहती हैं।"
    },
    "vasectomy": {
      "name": "पुरुष नसबंदी (Vasectomy)",
      "effectiveness": "99%",
      "description": "शुक्राणु ले जाने वाली नलियों को काटने या ब्लॉक करने के लिए एक छोटी शल्य प्रक्रिया।",
      "pros": ["स्थायी और अत्यधिक प्रभावी", "त्वरित रिकवरी के साथ एक बार की प्रक्रिया", "सेक्स ड्राइव पर कोई स्थायी प्रभाव नहीं"],
      "cons": ["स्थायी - इसे उलटना मुश्किल है", "तुरंत प्रभावी नहीं होता है", "STI से बचाव नहीं करता"],
      "bestFor": "पुरुष या जोड़े जो निश्चित हैं कि वे अब और बच्चे नहीं चाहते हैं।"
    },
    "tubal": {
      "name": "महिला नसबंदी (Tubal Ligation)",
      "effectiveness": "99%",
      "description": "फैलोपियन ट्यूब को स्थायी रूप से ब्लॉक करने या हटाने के लिए एक शल्य प्रक्रिया।",
      "pros": ["स्थायी और अत्यधिक प्रभावी", "तुरंत प्रभावी", "कोई हार्मोनल दुष्प्रभाव नहीं"],
      "cons": ["जोखिमों के साथ सर्जिकल प्रक्रिया", "स्थायी - इसे उलटना एक बड़ी सर्जरी है", "STI से बचाव नहीं करता"],
      "bestFor": "महिलाएँ या जोड़े जो निश्चित हैं कि वे अब और बच्चे नहीं चाहते हैं।"
    },
    "emergencyPills": {
      "name": "आपातकालीन गर्भनिरोधक गोलियां (ECP)",
      "effectiveness": "95%",
      "description": "गर्भावस्था को रोकने के लिए असुरक्षित यौन संबंध के 5 दिन बाद तक ली जाने वाली गोलियां।",
      "pros": ["असुरक्षित यौन संबंध के बाद गर्भावस्था को रोकने का एक सुरक्षित विकल्प", "कई जगहों पर आसानी से उपलब्ध", "पर्चे की आवश्यकता नहीं है"],
      "cons": ["नियमित गर्भनिरोधक जितना प्रभावी नहीं", "अस्थायी दुष्प्रभाव हो सकते हैं", "नियमित रूप से उपयोग नहीं किया जाना चाहिए"],
      "bestFor": "केवल आपातकालीन स्थितियों के लिए - नियमित उपयोग के लिए नहीं।"
    },
    "emergencyIud": {
      "name": "कॉपर IUD (आपातकालीन उपयोग)",
      "effectiveness": "99%",
      "description": "आपातकालीन गर्भनिरोधक के रूप में असुरक्षित यौन संबंध के 5 दिनों के भीतर डाला गया कॉपर IUD।",
      "pros": ["आपातकालीन गर्भनिरोधक का सबसे प्रभावी रूप", "निरंतर गर्भनिरोधक के लिए रखा जा सकता है", "हार्मोन-मुक्त विकल्प"],
      "cons": ["स्वास्थ्य प्रदाता द्वारा डालने की आवश्यकता है", "ऐंठन पैदा कर सकता है", "अधिक अग्रिम लागत"],
      "bestFor": "वे लोग जो सबसे प्रभावी आपातकालीन गर्भनिरोधक और चल रही सुरक्षा चाहते हैं।"
    },
    "fam": {
      "name": "प्रजनन जागरूकता विधियाँ (FAM)",
      "effectiveness": "76-88%",
      "description": "उपजाऊ दिनों की पहचान करने के लिए मासिक धर्म चक्र को ट्रैक करना।",
      "pros": ["कोई शारीरिक दुष्प्रभाव नहीं", "सीखने के बाद कोई लागत नहीं", "आपके शरीर को समझने में मदद करता है"],
      "cons": ["लगातार ट्रैकिंग की आवश्यकता है", "अन्य तरीकों की तुलना में कम प्रभावी", "STI से बचाव नहीं करता"],
      "bestFor": "नियमित चक्र वाले लोग जो प्राकृतिक तरीका चाहते हैं और ध्यान से ट्रैक करने को तैयार हैं।"
    },
    "withdrawal": {
      "name": "विथड्रॉल (पुल-आउट मेथड)",
      "effectiveness": "78%",
      "description": "पुरुष स्खलन से पहले योनि से अपने लिंग को निकाल लेता है।",
      "pros": ["कोई कीमत नहीं", "उपकरण या हार्मोन की आवश्यकता नहीं", "हमेशा उपलब्ध"],
      "cons": ["उच्च विफलता दर", "आत्म-नियंत्रण की आवश्यकता है", "STI से बचाव नहीं करता"],
      "bestFor": "जोड़े जो जोखिमों को समझते हैं और विफलता दर के साथ सहज हैं।"
    },
    "lam": {
      "name": "लैक्टेशनल एमेनोरिया विधि (LAM)",
      "effectiveness": "98%",
      "description": "विशेष स्तनपान के आधार पर बच्चे के जन्म के बाद अस्थायी गर्भनिरोधक।",
      "pros": ["प्राकृतिक और मुफ़्त", "बच्चे के लिए इष्टतम पोषण प्रदान करता है", "बॉन्डिंग को बढ़ावा देता है"],
      "cons": ["केवल प्रसव के 6 महीने बाद तक प्रभावी", "दिन-रात स्तनपान की आवश्यकता होती है", "STI से बचाव नहीं करता"],
      "bestFor": "नई माताएँ जो विशेष रूप से स्तनपान करा रही हैं और जिनका मासिक धर्म अभी तक वापस नहीं आया है।"
    }
  }
};

final Map<String, dynamic> contraceptionDataBn = {
  "tabs": [
    "হরমোনাল",
    "LARC (দীর্ঘস্থায়ী)",
    "বাধা (Barrier)",
    "স্থায়ী",
    "জরুরী",
    "প্রাকৃতিক"
  ],
  "endorsementTitle": "WHO দ্বারা অনুমোদিত",
  "endorsementDesc": "গর্ভনিরোধের সর্বোত্তম পদ্ধতি আপনার স্বাস্থ্য, জীবনধারা এবং ব্যক্তিগত পছন্দগুলির উপর নির্ভর করে। এই নির্দেশিকাটি আপনাকে সচেতন সিদ্ধান্ত নিতে সাহায্য করার জন্য WHO-এর সুপারিশগুলির উপর ভিত্তি করে তথ্য প্রদান করে। সর্বদা একজন স্বাস্থ্যসেবা প্রদানকারীর সাথে বিকল্পগুলি নিয়ে আলোচনা করুন।",
  "methodsSuffix": "পদ্ধতি",
  "methodLabels": {
    "effectiveness": "কার্যকারিতা",
    "pros": "সুবিধাসমূহ",
    "cons": "বিবেচ্য বিষয়",
    "bestFor": "যাদের জন্য সেরা:"
  },
  "methods": {
    "pills": {
      "name": "জন্মবিরতিকরণ পিল (Combined Pill)",
      "effectiveness": "৯১%",
      "description": "ডিম্বস্ফোটন রোধ করতে ইস্ট্রোজেন এবং প্রজেস্টিন যুক্ত একটি দৈনিক বড়ি।",
      "pros": ["সঠিকভাবে নেওয়া হলে অত্যন্ত কার্যকর", "মাসিক নিয়মিত করতে পারে", "মাসিক ব্যথা কমায়"],
      "cons": ["প্রতিদিন একই সময়ে নিতে হবে", "STI থেকে রক্ষা করে না", "পার্শ্ব প্রতিক্রিয়া হতে পারে (বমি বমি ভাব, মাথাব্যথা)"],
      "bestFor": "যে মহিলারা প্রতিদিন একটি পিল খাওয়ার কথা মনে রাখতে পারেন।"
    },
    "patch": {
      "name": "গর্ভনিরোধক প্যাচ",
      "effectiveness": "৯১%",
      "description": "ত্বকে পরা একটি ছোট প্যাচ যা হরমোন নিঃসরণ করে। সাপ্তাহিক পরিবর্তন করা হয়।",
      "pros": ["ব্যবহারে সহজ", "সপ্তাহে একবার পরিবর্তন করতে হবে", "মাসিক নিয়মিত করতে পারে"],
      "cons": ["ত্বকে দেখা যায়", "STI থেকে রক্ষা করে না", "ত্বকে জ্বালা সৃষ্টি করতে পারে"],
      "bestFor": "যে মহিলারা প্রতিদিনের পরিবর্তে সাপ্তাহিক রুটিন পছন্দ করেন।"
    },
    "ring": {
      "name": "ভ্যাজাইনাল রিং (যোনি রিং)",
      "effectiveness": "৯১%",
      "description": "যোনিতে স্থাপন করা একটি নমনীয় রিং যা হরমোন নিঃসরণ করে। ৩ সপ্তাহের জন্য রাখা হয়।",
      "pros": ["মাসে মাত্র একবার পরিবর্তন করতে হবে", "ঢোকানো এবং অপসারণ করা সহজ", "পিলের তুলনায় হরমোনের মাত্রা কম"],
      "cons": ["যোনিতে ঢোকানোর স্বাচ্ছন্দ্য প্রয়োজন", "STI থেকে রক্ষা করে না", "যোনি স্রাব বাড়তে পারে"],
      "bestFor": "মহিলারা যারা রিং ঢোকানোতে আরামদায়ক এবং একটি মাসিক রুটিন চান।"
    },
    "injection": {
      "name": "গর্ভনিরোধক ইনজেকশন",
      "effectiveness": "৯৪%",
      "description": "প্রকারের উপর নির্ভর করে প্রতি ১ থেকে ৩ মাসে প্রজেস্টোজেনের একটি ইনজেকশন দেওয়া হয়।",
      "pros": ["কয়েক মাস ধরে কাজ করে", "অত্যন্ত গোপনীয়", "মাসিক পুরোপুরি বন্ধ করতে পারে"],
      "cons": ["ক্লিনিকে যাওয়ার প্রয়োজন", "STI থেকে রক্ষা করে না", "উর্বরতা ফিরে আসতে দেরি হতে পারে"],
      "bestFor": "যে মহিলারা দৈনন্দিন বা সাপ্তাহিক কাজ ছাড়াই অত্যন্ত কার্যকর পদ্ধতি চান।"
    },
    "implant": {
      "name": "গর্ভনিরোধক ইমপ্লান্ট",
      "effectiveness": "৯৯%",
      "description": "উপরের বাহুর ত্বকের নিচে একটি ছোট, নমনীয় রড স্থাপন করা হয়। ৩-৫ বছর স্থায়ী হয়।",
      "pros": ["অত্যন্ত কার্যকর", "কয়েক বছর স্থায়ী হয়", "যেকোন সময় সরানো যেতে পারে", "বুকের দুধ খাওয়ানোর সময় নিরাপদ"],
      "cons": ["ছোটখাটো পদ্ধতির প্রয়োজন", "অনিয়মিত রক্তপাত হতে পারে", "STI থেকে রক্ষা করে না"],
      "bestFor": "মহিলারা যারা দীর্ঘমেয়াদী, অত্যন্ত কার্যকর, 'ফিট এবং ভুলে যাওয়া' গর্ভনিরোধক চান।"
    },
    "iudCopper": {
      "name": "কপার IUD (কপার টি)",
      "effectiveness": "৯৯%",
      "description": "তামার তারের সাথে একটি ছোট, টি-আকৃতির যন্ত্র জরায়ুতে স্থাপন করা হয়। ৫-১০ বছর স্থায়ী হয়।",
      "pros": ["অত্যন্ত কার্যকর", "হরমোন-মুক্ত", "কয়েক বছর স্থায়ী হয়", "জরুরী গর্ভনিরোধক হিসাবে ব্যবহার করা যেতে পারে"],
      "cons": ["ক্লিনিক পদ্ধতি প্রয়োজন", "ভারী এবং বেদনাদায়ক মাসিক হতে পারে", "STI থেকে রক্ষা করে না"],
      "bestFor": "যে মহিলারা অত্যন্ত কার্যকর, হরমোন-মুক্ত, দীর্ঘমেয়াদী গর্ভনিরোধক চান।"
    },
    "iudHormonal": {
      "name": "হরমোনাল IUD",
      "effectiveness": "৯৯%",
      "description": "জরায়ুতে স্থাপন করা একটি টি-আকৃতির যন্ত্র যা প্রজেস্টিন নিঃসরণ করে। ৩-৭ বছর স্থায়ী হয়।",
      "pros": ["অত্যন্ত কার্যকর", "কয়েক বছর স্থায়ী হয়", "মাসিক হালকা এবং কম বেদনাদায়ক করে", "যেকোন সময় সরানো যেতে পারে"],
      "cons": ["ক্লিনিক পদ্ধতি প্রয়োজন", "প্রাথমিকভাবে অনিয়মিত স্পটিং হতে পারে", "STI থেকে রক্ষা করে না"],
      "bestFor": "যে মহিলারা অত্যন্ত কার্যকর, দীর্ঘমেয়াদী গর্ভনিরোধক এবং হালকা মাসিক চান।"
    },
    "maleCondom": {
      "name": "পুরুষ কনডম",
      "effectiveness": "৮২%",
      "description": "গর্ভাবস্থা এবং STI প্রতিরোধের জন্য যৌন মিলনের আগে পুরুষাঙ্গের উপর রোল করা একটি পাতলা আবরণ।",
      "pros": ["এইচআইভি সহ STI থেকে রক্ষা করে", "কেনা এবং ব্যবহার করা সহজ", "কোনো হরমোন নেই", "শুধু প্রয়োজনের সময় ব্যবহৃত হয়"],
      "cons": ["ছিঁড়ে বা পিছলে যেতে পারে", "সঙ্গীর সহযোগিতা প্রয়োজন", "কার্যকারিতা সঠিক ব্যবহারের উপর নির্ভর করে"],
      "bestFor": "যে কেউ যাদের হরমোন ছাড়াই STI এবং গর্ভাবস্থা থেকে সুরক্ষা প্রয়োজন।"
    },
    "femaleCondom": {
      "name": "মহিলা কনডম",
      "effectiveness": "৭৯%",
      "description": "গর্ভাবস্থা প্রতিরোধের জন্য যৌন মিলনের আগে যোনিতে ঢোকানো একটি নরম পাউচ।",
      "pros": ["এইচআইভি সহ STI থেকে রক্ষা করে", "যৌন মিলনের ৮ ঘন্টা আগে ঢোকানো যেতে পারে", "কোনো প্রেসক্রিপশন প্রয়োজন নেই"],
      "cons": ["পুরুষ কনডমের তুলনায় কম কার্যকর", "যৌন মিলনের সময় শব্দ হতে পারে", "সঠিক সন্নিবেশ কৌশলের প্রয়োজন"],
      "bestFor": "যে মহিলারা STI সুরক্ষা এবং তাদের গর্ভনিরোধের উপর নিয়ন্ত্রণ চান।"
    },
    "diaphragm": {
      "name": "ডায়াফ্রাম",
      "effectiveness": "৮৩%",
      "description": "জরায়ুমুখ ঢেকে এবং শুক্রাণু আটকাতে যোনিতে একটি ছোট, গম্বুজ আকৃতির কাপ ঢোকানো হয়।",
      "pros": ["পুনর্ব্যবহারযোগ্য এবং কয়েক বছর স্থায়ী হয়", "নন-হরমোনাল বিকল্প", "যৌন মিলনের ৬ ঘন্টা আগে ঢোকানো যেতে পারে"],
      "cons": ["স্বাস্থ্যসেবা প্রদানকারী দ্বারা ফিটিং প্রয়োজন", "স্পার্মিসাইড এর সাথে ব্যবহার করতে হবে", "STI থেকে রক্ষা করে না"],
      "bestFor": "মহিলারা যারা একটি পুনর্ব্যবহারযোগ্য, অ-হরমোনাল বাধা পদ্ধতি চান।"
    },
    "vasectomy": {
      "name": "পুরুষ বন্ধ্যাকরণ (Vasectomy)",
      "effectiveness": "৯৯%",
      "description": "শুক্রাণু বহনকারী টিউবগুলি কাটা বা ব্লক করার জন্য একটি ছোট অস্ত্রোপচার পদ্ধতি।",
      "pros": ["স্থায়ী এবং অত্যন্ত কার্যকর", "দ্রুত পুনরুদ্ধারের সাথে এককালীন পদ্ধতি", "যৌন আকাঙ্ক্ষার উপর কোন প্রভাব নেই"],
      "cons": ["স্থায়ী - বিপরীত করা কঠিন", "অবিলম্বে কার্যকর হয় না", "STI থেকে রক্ষা করে না"],
      "bestFor": "পুরুষ বা দম্পতি যারা নিশ্চিত যে তারা আর সন্তান চান না।"
    },
    "tubal": {
      "name": "মহিলা বন্ধ্যাকরণ (Tubal Ligation)",
      "effectiveness": "৯৯%",
      "description": "ফ্যালোপিয়ান টিউবগুলিকে স্থায়ীভাবে ব্লক বা অপসারণ করার একটি অস্ত্রোপচার পদ্ধতি।",
      "pros": ["স্থায়ী এবং অত্যন্ত কার্যকর", "অবিলম্বে কার্যকর", "কোন হরমোনের পার্শ্বপ্রতিক্রিয়া নেই"],
      "cons": ["ঝুঁকি সহ অস্ত্রোপচার পদ্ধতি", "স্থায়ী - বিপরীত করা একটি বড় অস্ত্রোপচার", "STI থেকে রক্ষা করে না"],
      "bestFor": "মহিলারা বা দম্পতিরা যারা নিশ্চিত যে তারা আর সন্তান চান না।"
    },
    "emergencyPills": {
      "name": "জরুরী গর্ভনিরোধক বড়ি (ECP)",
      "effectiveness": "৯৫%",
      "description": "গর্ভাবস্থা প্রতিরোধের জন্য অরক্ষিত যৌন মিলনের ৫ দিন পর পর্যন্ত নেওয়া যায় এমন বড়ি।",
      "pros": ["অরক্ষিত যৌন মিলনের পরে গর্ভাবস্থা প্রতিরোধের একটি নিরাপদ বিকল্প", "অনেক জায়গায় সহজেই উপলব্ধ", "প্রেসক্রিপশন প্রয়োজন নেই"],
      "cons": ["নিয়মিত গর্ভনিরোধক হিসাবে কার্যকর নয়", "অস্থায়ী পার্শ্ব প্রতিক্রিয়া হতে পারে", "নিয়মিত ব্যবহার করা উচিত নয়"],
      "bestFor": "শুধুমাত্র জরুরী পরিস্থিতি - নিয়মিত ব্যবহারের জন্য নয়।"
    },
    "emergencyIud": {
      "name": "কপার IUD (জরুরী ব্যবহার)",
      "effectiveness": "৯৯%",
      "description": "জরুরী গর্ভনিরোধক হিসাবে অরক্ষিত যৌন মিলনের ৫ দিনের মধ্যে কপার IUD ঢোকানো হয়।",
      "pros": ["জরুরী গর্ভনিরোধের সবচেয়ে কার্যকর রূপ", "চলমান গর্ভনিরোধের জন্য রাখা যেতে পারে", "হরমোন-মুক্ত বিকল্প"],
      "cons": ["স্বাস্থ্য প্রদানকারী দ্বারা সন্নিবেশ প্রয়োজন", "অস্থায়ী ক্র্যাম্পিং হতে পারে", "সামনের খরচ বেশি"],
      "bestFor": "যারা সবচেয়ে কার্যকর জরুরী গর্ভনিরোধক এবং চলমান সুরক্ষা চান।"
    },
    "fam": {
      "name": "উর্বরতা সচেতনতা পদ্ধতি (FAM)",
      "effectiveness": "৭৬-৮৮%",
      "description": "উর্বর দিন চিহ্নিত করতে মাসিক চক্র ট্র্যাকিং।",
      "pros": ["কোন শারীরিক পার্শ্বপ্রতিক্রিয়া নেই", "শেখার পরে কোন খরচ নেই", "শরীর বুঝতে সাহায্য করে"],
      "cons": ["ধারাবাহিক ট্র্যাকিং প্রয়োজন", "অন্যান্য পদ্ধতির চেয়ে কম কার্যকর", "STI থেকে রক্ষা করে না"],
      "bestFor": "নিয়মিত চক্রযুক্ত মানুষ যারা একটি প্রাকৃতিক পদ্ধতি চান এবং ট্র্যাক করতে ইচ্ছুক।"
    },
    "withdrawal": {
      "name": "প্রত্যাহার পদ্ধতি (Pull-Out)",
      "effectiveness": "৭৮%",
      "description": "বীর্যপাতের আগে পুরুষটি যোনি থেকে তার পুরুষাঙ্গ প্রত্যাহার করে নেয়।",
      "pros": ["কোন খরচ নেই", "কোন সরঞ্জাম বা হরমোনের প্রয়োজন নেই", "সর্বদা উপলব্ধ"],
      "cons": ["উচ্চ ব্যর্থতার হার", "আত্মনিয়ন্ত্রণ প্রয়োজন", "STI থেকে রক্ষা করে না"],
      "bestFor": "দম্পতি যারা ঝুঁকি বোঝেন এবং ব্যর্থতার হারের সাথে আরামদায়ক।"
    },
    "lam": {
      "name": "ল্যাকটেশনাল অ্যামেনোরিয়া (LAM)",
      "effectiveness": "৯৮%",
      "description": "একচেটিয়া স্তন্যপানের উপর ভিত্তি করে সন্তান প্রসবের পর অস্থায়ী গর্ভনিরোধক।",
      "pros": ["প্রাকৃতিক এবং বিনামূল্যে", "শিশুর জন্য পুষ্টি প্রদান করে", "বন্ধন প্রচার করে"],
      "cons": ["প্রসবের পর শুধুমাত্র ৬ মাস পর্যন্ত কার্যকর", "দিন-রাত স্তন্যপান করানো প্রয়োজন", "STI থেকে রক্ষা করে না"],
      "bestFor": "নতুন মায়েরা যারা একচেটিয়াভাবে বুকের দুধ খাওয়াচ্ছেন এবং যাদের মাসিক এখনও ফিরে আসেনি।"
    }
  }
};
