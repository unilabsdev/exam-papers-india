class AppConstants {
  AppConstants._();

  static const String appName = 'Exam Papers';
  static const String appVersion = '1.0.0';

  // ── Supabase ────────────────────────────────────────────────────────────────
  static const String supabaseUrl =
      'https://hsvgjgnfrtufrfswwoeu.supabase.co';
  static const String supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9'
      '.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImhzdmdqZ25mcnR1ZnJmc3d3b2V1Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzMzOTI0MDcsImV4cCI6MjA4ODk2ODQwN30'
      '.Qdf7kcQng5s6AmtY0of2R7JsmQg4dRPEAnw7Yb1Sya4';

  // ── Spacing ──────────────────────────────────────────────────────────────────
  static const double spaceXS  = 4.0;
  static const double spaceSM  = 8.0;
  static const double spaceMD  = 16.0;
  static const double spaceLG  = 24.0;
  static const double spaceXL  = 32.0;
  static const double spaceXXL = 48.0;

  // ── Border radius ────────────────────────────────────────────────────────────
  static const double radiusSM = 8.0;
  static const double radiusMD = 12.0;
  static const double radiusLG = 16.0;
  static const double radiusXL = 24.0;

  // ── Grid ─────────────────────────────────────────────────────────────────────
  static const int examGridCrossAxisCount    = 2;
  static const int categoryGridCrossAxisCount = 2;
  static const double examCardAspectRatio    = 0.75;
  static const double categoryCardAspectRatio = 0.90;
}
