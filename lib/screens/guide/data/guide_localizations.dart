import 'package:flutter/material.dart';

import 'child_care_data.dart';
import 'contraception_data.dart';
import 'family_planning_data.dart';

class GuideLocalizations {
  /// Returns the localized data map for Child Care Guide based on language code.
  static Map<String, dynamic> getChildCareData(BuildContext context) {
    final String langCode = Localizations.localeOf(context).languageCode;
    if (langCode == 'hi') return childCareDataHi;
    if (langCode == 'bn') return childCareDataBn;
    return childCareDataEn;
  }

  /// Returns the localized data map for Contraception Guide based on language code.
  static Map<String, dynamic> getContraceptionData(BuildContext context) {
    final String langCode = Localizations.localeOf(context).languageCode;
    if (langCode == 'hi') return contraceptionDataHi;
    if (langCode == 'bn') return contraceptionDataBn;
    return contraceptionDataEn;
  }

  /// Returns the localized data map for Family Planning Guide based on language code.
  static Map<String, dynamic> getFamilyPlanningData(BuildContext context) {
    final String langCode = Localizations.localeOf(context).languageCode;
    if (langCode == 'hi') return familyPlanningDataHi;
    if (langCode == 'bn') return familyPlanningDataBn;
    return familyPlanningDataEn;
  }
}
