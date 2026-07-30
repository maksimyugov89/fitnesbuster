import 'en.dart';
import 'ru.dart';
import 'es.dart';
import 'de.dart';
import 'fr.dart';
import 'it.dart';
import 'pt.dart';
import 'tr.dart';
import 'ar.dart';
import 'zh.dart';
import 'ja.dart';
import 'ko.dart';
import 'hi.dart';
import 'uk.dart';
import 'be.dart';

final Map<String, Map<String, String>> allTranslations = {
  'en': enTranslations,
  'ru': ruTranslations,
  'es': {...enTranslations, ...esTranslations},
  'de': {...enTranslations, ...deTranslations},
  'fr': {...enTranslations, ...frTranslations},
  'it': {...enTranslations, ...itTranslations},
  'pt': {...enTranslations, ...ptTranslations},
  'tr': {...enTranslations, ...trTranslations},
  'ar': {...enTranslations, ...arTranslations},
  'zh': {...enTranslations, ...zhTranslations},
  'ja': {...enTranslations, ...jaTranslations},
  'ko': {...enTranslations, ...koTranslations},
  'hi': {...enTranslations, ...hiTranslations},
  'uk': {...enTranslations, ...ukTranslations},
  'be': {...enTranslations, ...beTranslations},
};
