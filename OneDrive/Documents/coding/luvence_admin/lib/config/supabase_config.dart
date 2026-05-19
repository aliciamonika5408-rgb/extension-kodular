import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  SupabaseConfig._();

  static const String url = 'https://kunjlslymhljrkwdmirp.supabase.co';
  static const String anonKey = 'sb_publishable_ypf8qTIPTCsY2nhVhi8hjw_W2u990PK';

  /// Redirect URL for OAuth (must match AndroidManifest + Supabase Dashboard)
  static const String redirectUrl = 'io.supabase.luvenceadmin://login-callback/';

  static Future<void> initialize() async {
    await Supabase.initialize(
      url: url,
      anonKey: anonKey,
      authOptions: const FlutterAuthClientOptions(
        authFlowType: AuthFlowType.pkce,
      ),
    );
  }

  static SupabaseClient get client => Supabase.instance.client;
}
