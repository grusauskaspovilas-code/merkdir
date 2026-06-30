import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_lt.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('de'),
    Locale('en'),
    Locale('lt'),
  ];

  /// No description provided for @shoppingList.
  ///
  /// In de, this message translates to:
  /// **'Einkaufsliste'**
  String get shoppingList;

  /// No description provided for @product.
  ///
  /// In de, this message translates to:
  /// **'Produkt'**
  String get product;

  /// No description provided for @addProduct.
  ///
  /// In de, this message translates to:
  /// **'+ Produkt'**
  String get addProduct;

  /// No description provided for @addStore.
  ///
  /// In de, this message translates to:
  /// **'+ Geschäft'**
  String get addStore;

  /// No description provided for @favorites.
  ///
  /// In de, this message translates to:
  /// **'Favoriten'**
  String get favorites;

  /// No description provided for @settings.
  ///
  /// In de, this message translates to:
  /// **'Einstellungen'**
  String get settings;

  /// No description provided for @stores.
  ///
  /// In de, this message translates to:
  /// **'Geschäfte'**
  String get stores;

  /// No description provided for @priority.
  ///
  /// In de, this message translates to:
  /// **'Priorität'**
  String get priority;

  /// No description provided for @language.
  ///
  /// In de, this message translates to:
  /// **'Sprache'**
  String get language;

  /// No description provided for @nearbyStores.
  ///
  /// In de, this message translates to:
  /// **'📍 Geschäfte in der Nähe'**
  String get nearbyStores;

  /// No description provided for @noSavedProducts.
  ///
  /// In de, this message translates to:
  /// **'Noch keine Produkte gespeichert'**
  String get noSavedProducts;

  /// No description provided for @searchStores.
  ///
  /// In de, this message translates to:
  /// **'Geschäfte suchen'**
  String get searchStores;

  /// No description provided for @matchingStores.
  ///
  /// In de, this message translates to:
  /// **'Passende Geschäfte gefunden'**
  String get matchingStores;

  /// No description provided for @openShopping.
  ///
  /// In de, this message translates to:
  /// **'Offene Einkäufe'**
  String get openShopping;

  /// No description provided for @later.
  ///
  /// In de, this message translates to:
  /// **'Später'**
  String get later;

  /// No description provided for @toShoppingList.
  ///
  /// In de, this message translates to:
  /// **'Zur Einkaufsliste'**
  String get toShoppingList;

  /// No description provided for @productName.
  ///
  /// In de, this message translates to:
  /// **'Produktname'**
  String get productName;

  /// No description provided for @saved.
  ///
  /// In de, this message translates to:
  /// **'Gespeichert:'**
  String get saved;

  /// No description provided for @category.
  ///
  /// In de, this message translates to:
  /// **'Kategorie'**
  String get category;

  /// No description provided for @wine.
  ///
  /// In de, this message translates to:
  /// **'Wein'**
  String get wine;

  /// No description provided for @chocolate.
  ///
  /// In de, this message translates to:
  /// **'Schokolade'**
  String get chocolate;

  /// No description provided for @snacks.
  ///
  /// In de, this message translates to:
  /// **'Snacks'**
  String get snacks;

  /// No description provided for @cheese.
  ///
  /// In de, this message translates to:
  /// **'Käse'**
  String get cheese;

  /// No description provided for @drinks.
  ///
  /// In de, this message translates to:
  /// **'Getränke'**
  String get drinks;

  /// No description provided for @rating.
  ///
  /// In de, this message translates to:
  /// **'Bewertung'**
  String get rating;

  /// No description provided for @normal.
  ///
  /// In de, this message translates to:
  /// **'Normal'**
  String get normal;

  /// No description provided for @high.
  ///
  /// In de, this message translates to:
  /// **'Hoch'**
  String get high;

  /// No description provided for @low.
  ///
  /// In de, this message translates to:
  /// **'Niedrig'**
  String get low;

  /// No description provided for @findStoresHint.
  ///
  /// In de, this message translates to:
  /// **'Klicken Sie auf die Schaltfläche, um Geschäfte zu finden'**
  String get findStoresHint;

  /// No description provided for @storesNotFound.
  ///
  /// In de, this message translates to:
  /// **'Geschäfte konnten nicht gefunden werden'**
  String get storesNotFound;

  /// No description provided for @noNearbyMatches.
  ///
  /// In de, this message translates to:
  /// **'Keine passenden Artikel für Geschäfte in der Nähe'**
  String get noNearbyMatches;

  /// No description provided for @enterProductName.
  ///
  /// In de, this message translates to:
  /// **'Bitte Produktname eingeben'**
  String get enterProductName;

  /// No description provided for @anyStore.
  ///
  /// In de, this message translates to:
  /// **'Beliebiges Geschäft'**
  String get anyStore;

  /// No description provided for @nearby.
  ///
  /// In de, this message translates to:
  /// **'in der Nähe'**
  String get nearby;

  /// No description provided for @searchingStores.
  ///
  /// In de, this message translates to:
  /// **'Suche nach Geschäften...'**
  String get searchingStores;

  /// No description provided for @noPosition.
  ///
  /// In de, this message translates to:
  /// **'Noch keine Position'**
  String get noPosition;

  /// No description provided for @findStores.
  ///
  /// In de, this message translates to:
  /// **'Geschäfte suchen'**
  String get findStores;

  /// No description provided for @checkPosition.
  ///
  /// In de, this message translates to:
  /// **'Check Position'**
  String get checkPosition;

  /// No description provided for @storeAdded.
  ///
  /// In de, this message translates to:
  /// **'zu Geschäften hinzugefügt'**
  String get storeAdded;

  /// No description provided for @aboutApp.
  ///
  /// In de, this message translates to:
  /// **'Über die App'**
  String get aboutApp;

  /// No description provided for @version.
  ///
  /// In de, this message translates to:
  /// **'Version'**
  String get version;

  /// No description provided for @createdBy.
  ///
  /// In de, this message translates to:
  /// **'Erstellt von'**
  String get createdBy;

  /// No description provided for @allRightsReserved.
  ///
  /// In de, this message translates to:
  /// **'Alle Rechte vorbehalten.'**
  String get allRightsReserved;

  /// No description provided for @notes.
  ///
  /// In de, this message translates to:
  /// **'Notizen'**
  String get notes;

  /// No description provided for @selectPhoto.
  ///
  /// In de, this message translates to:
  /// **'Foto auswählen'**
  String get selectPhoto;

  /// No description provided for @save.
  ///
  /// In de, this message translates to:
  /// **'Speichern'**
  String get save;

  /// No description provided for @toFavorites.
  ///
  /// In de, this message translates to:
  /// **'Zu Favoriten'**
  String get toFavorites;

  /// No description provided for @quickAdd.
  ///
  /// In de, this message translates to:
  /// **'Produkt schnell hinzufügen'**
  String get quickAdd;

  /// No description provided for @productNameHint.
  ///
  /// In de, this message translates to:
  /// **'Produktname'**
  String get productNameHint;

  /// No description provided for @allStores.
  ///
  /// In de, this message translates to:
  /// **'Alle Geschäfte'**
  String get allStores;

  /// No description provided for @add.
  ///
  /// In de, this message translates to:
  /// **'Hinzufügen'**
  String get add;

  /// No description provided for @selectStores.
  ///
  /// In de, this message translates to:
  /// **'Geschäfte auswählen'**
  String get selectStores;

  /// No description provided for @notificationSettings.
  ///
  /// In de, this message translates to:
  /// **'Benachrichtigungseinstellungen'**
  String get notificationSettings;

  /// No description provided for @notificationDistance.
  ///
  /// In de, this message translates to:
  /// **'Erinnerungsabstand'**
  String get notificationDistance;

  /// No description provided for @checkInterval.
  ///
  /// In de, this message translates to:
  /// **'Prüfen alle'**
  String get checkInterval;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['de', 'en', 'lt'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
    case 'lt':
      return AppLocalizationsLt();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
