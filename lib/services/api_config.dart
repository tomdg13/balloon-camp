class ApiConfig {
  // Change this to your server IP when running on a real device
  // For emulator use 10.0.2.2, for real device use your Mac's local IP
  //  static const String baseUrl = 'http://localhost:3000';
  static const String baseUrl = 'https://balloon-camp-api.sabaiapp.com';

  static const String login        = '/api/auth/login';
  static const String register     = '/api/auth/register';
  static const String tables       = '/api/tables';
  static const String menuFull     = '/api/menu/full';
  static const String menuItems    = '/api/menu/items';
  static const String orders       = '/api/orders';
  static const String bills        = '/api/bills';

  static String tableStatus(int id)      => '/api/tables/$id/status';
  static String orderStatus(int id)      => '/api/orders/$id/status';
  static String menuItemImage(int id)    => '/api/menu/items/$id/image';
  static String billSlip(int id)         => '/api/bills/$id/slip';
  static String billVerify(int id)       => '/api/bills/$id/verify';
}
