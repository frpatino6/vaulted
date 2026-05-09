import 'package:dio/dio.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'core/config/app_config.dart';
import 'core/network/dio_credentials.dart';
import 'core/router/app_router_provider.dart';
import 'core/storage/auth_token_store.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_mode_provider.dart';
import 'features/notifications/presentation/providers/notifications_list_provider.dart';
import 'features/notifications/presentation/providers/notifications_provider.dart';
import 'features/presence/presentation/providers/presence_provider.dart';
import 'firebase_options.dart';
