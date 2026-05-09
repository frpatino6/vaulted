import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../../users/domain/current_user_jwt.dart';
import '../../maintenance/data/models/maintenance_model.dart';
import '../../maintenance/domain/maintenance_notifier.dart';
import '../../properties/data/models/property_model.dart';
import '../../properties/domain/properties_notifier.dart';
import '../../properties/presentation/add_property_sheet.dart';
import '../data/models/dashboard_model.dart';
import '../domain/dashboard_notifier.dart';
import '../../movements/data/models/movement_model.dart';
import '../../movements/domain/movement_list_notifier.dart';
import '../../../features/presence/presentation/widgets/online_users_count.dart';
import '../../../core/privacy/privacy_mode_provider.dart';
import '../../../shared/widgets/loading_skeleton.dart';
import '../../../shared/widgets/app_bottom_nav.dart';
import '../../../features/notifications/presentation/providers/notifications_list_provider.dart';
import 'widgets/dashboard_header.dart';
