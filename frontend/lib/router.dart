import 'package:go_router/go_router.dart';
import 'features/auth/login_screen.dart';
import 'features/pedidos/pedidos_list_screen.dart';
import 'features/pedidos/novo_pedido_screen.dart';
import 'features/pedidos/detalhes_pedido_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/login',
  routes: [
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/pedidos',
      builder: (context, state) => const PedidosListScreen(),
    ),
    GoRoute(
      path: '/pedidos/novo',
      builder: (context, state) => const NovoPedidoScreen(),
    ),
    GoRoute(
      path: '/pedidos/:id',
      builder: (context, state) => DetalhesPedidoScreen(
        pedidoId: int.parse(state.pathParameters['id']!),
      ),
    ),
  ],
);
