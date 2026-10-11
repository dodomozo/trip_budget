const Map<String, String> countries = {
  'JP': 'Japan',
  'PH': 'Philippines',
  'US': 'United States',
  'GB': 'United Kingdom',
  'KR': 'South Korea',
  'CN': 'China',
  'SG': 'Singapore',
  'AU': 'Australia',
  'CA': 'Canada',
  'HK': 'Hong Kong',
  'TW': 'Taiwan',
  'TH': 'Thailand',
  'MY': 'Malaysia',
  'ID': 'Indonesia',
  'VN': 'Vietnam',
  'IN': 'India',
  'DE': 'Germany',
  'FR': 'France',
  'IT': 'Italy',
  'ES': 'Spain',
  'NL': 'Netherlands',
  'CH': 'Switzerland',
  'NZ': 'New Zealand',
  'AE': 'United Arab Emirates',
  'SA': 'Saudi Arabia',
  'BR': 'Brazil',
  'MX': 'Mexico',
  'IE': 'Ireland',
  'PT': 'Portugal',
  'SE': 'Sweden',
  'NO': 'Norway',
  'DK': 'Denmark',
};

String countryFlag(String countryCode) {
  return countryCode
      .toUpperCase()
      .codeUnits
      .map((letter) => String.fromCharCode(0x1F1E6 + letter - 65))
      .join();
}
