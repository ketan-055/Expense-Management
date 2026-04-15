/// Short English month labels (Jan … Dec) for budget display.
String monthShortName(int monthIndex) {
  const names = <String>[
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  if (monthIndex < 1 || monthIndex > 12) return '';
  return names[monthIndex - 1];
}
