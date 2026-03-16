import 'package:flutter/material.dart';

/// Maps the [icon_name] string stored in Supabase → Flutter [IconData].
///
/// Add new entries here as new exams/categories are added to the database.
class IconMapper {
  IconMapper._();

  static const _map = <String, IconData>{
    // Exam icons
    'account_balance':          Icons.account_balance_rounded,
    'military_tech':            Icons.military_tech_rounded,
    'terrain':                  Icons.terrain_rounded,
    'shield':                   Icons.shield_rounded,
    'star':                     Icons.star_rounded,
    'engineering':              Icons.engineering_rounded,
    'security':                 Icons.security_rounded,
    'local_hospital':           Icons.local_hospital_rounded,
    'analytics':                Icons.analytics_rounded,
    'gavel':                    Icons.gavel_rounded,

    // Category icons
    'assignment':               Icons.assignment_rounded,
    'calculate':                Icons.calculate_rounded,
    'history_edu':              Icons.history_edu_rounded,
    'policy':                   Icons.policy_rounded,
    'eco':                      Icons.eco_rounded,
    'balance':                  Icons.balance_rounded,
    'edit_note':                Icons.edit_note_rounded,
    'translate':                Icons.translate_rounded,
    'functions':                Icons.functions_rounded,
    'public':                   Icons.public_rounded,
    'landscape':                Icons.landscape_rounded,
    'water':                    Icons.water_rounded,
    'science':                  Icons.science_rounded,
    'menu_book':                Icons.menu_book_rounded,
    'edit':                     Icons.edit_rounded,
    'quiz':                     Icons.quiz_rounded,
    'settings':                 Icons.settings_rounded,
    'apartment':                Icons.apartment_rounded,
    'precision_manufacturing':  Icons.precision_manufacturing_rounded,
    'bolt':                     Icons.bolt_rounded,
    'developer_board':          Icons.developer_board_rounded,

    // Additional category icons
    'notifications':            Icons.notifications_rounded,
    'school':                   Icons.school_rounded,
    'park':                     Icons.park_rounded,
    'library_books':            Icons.library_books_rounded,
    'medical_services':         Icons.medical_services_rounded,

    // Generic fallbacks
    'book':                     Icons.book_rounded,
    'description':              Icons.description_rounded,
    'help':                     Icons.help_outline_rounded,
  };

  /// Returns the mapped [IconData], or [Icons.description_rounded] if unknown.
  static IconData get(String? name) =>
      _map[name] ?? Icons.description_rounded;
}
