import 'package:go_router/go_router.dart';
import '../../features/auth/login_screen.dart';
import '../../features/home/home_screen.dart';
import '../../features/correspondence/screens/register_document_screen.dart';
import '../../features/correspondence/screens/correspondence_list_screen.dart';
import '../../features/correspondence/screens/correspondence_detail_screen.dart';
import '../../features/correspondence/screens/reports_screen.dart';
import '../../features/correspondence/models/correspondence_model.dart';
import '../../features/auth/user_management_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/login',
  routes: [
    GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
    GoRoute(path: '/', builder: (context, state) => const HomeScreen()),
    GoRoute(
      path: '/register',
      builder: (context, state) => const RegisterDocumentScreen(),
    ),
    GoRoute(
      path: '/inbox',
      builder: (context, state) =>
          const CorrespondenceListScreen(isInbox: true),
    ),
    GoRoute(
      path: '/outbox',
      builder: (context, state) =>
          const CorrespondenceListScreen(isInbox: false),
    ),
    GoRoute(
      path: '/reports',
      builder: (context, state) => const ReportsScreen(),
    ),
    GoRoute(
      path: '/users',
      builder: (context, state) => const UserManagementScreen(),
    ),
    GoRoute(
      path: '/detail',
      builder: (context, state) {
        final doc = state.extra as CorrespondenceModel;
        return CorrespondenceDetailScreen(doc: doc);
      },
    ),
  ],
);
