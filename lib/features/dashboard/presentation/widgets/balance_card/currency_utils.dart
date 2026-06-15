String dashboardCurrencySymbol(String code) {
  const map = {
    'PEN': 'S/',
    'USD': '\$',
    'EUR': '€',
    'GBP': '£',
    'CLP': '\$',
    'COP': '\$',
    'MXN': '\$',
    'BRL': 'R\$',
  };
  return map[code] ?? code;
}
