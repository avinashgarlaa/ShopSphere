import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/auth/data/auth_repository_impl.dart';
import '../../features/auth/domain/app_user.dart';
import '../../features/auth/domain/auth_repository.dart';
import '../../features/auth/domain/login_use_case.dart';
import '../../features/auth/presentation/session_controller.dart';
import '../../features/cart/data/cart_repository_impl.dart';
import '../../features/cart/domain/cart_repository.dart';
import '../../features/cart/presentation/cart_controller.dart';
import '../../features/products/data/products_repository_impl.dart';
import '../../features/products/domain/product.dart';
import '../../features/products/domain/product_category.dart';
import '../../features/products/domain/products_repository.dart';
import '../../features/products/presentation/products_controller.dart';
import '../../features/products/presentation/wishlist_controller.dart';
import '../error/result.dart';
import '../network/api_client.dart';
import '../storage/preferences_store.dart';
import '../storage/session_store.dart';

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('SharedPreferences must be provided at startup.');
});

final preferencesStoreProvider = Provider<PreferencesStore>(
  (ref) => PreferencesStore(ref.watch(sharedPreferencesProvider)),
);

final sessionStoreProvider = Provider<SessionStore>(
  (ref) => const SessionStore(FlutterSecureStorage()),
);

final apiClientProvider = Provider<ApiClient>(
  (ref) => ApiClient(
    ref.watch(sessionStoreProvider),
    onSessionExpired: () =>
        ref.read(sessionProvider.notifier).signOut(notice: 'session_expired'),
  ),
);

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepositoryImpl(
    ref.watch(apiClientProvider),
    ref.watch(sessionStoreProvider),
  ),
);

final loginUseCaseProvider = Provider<LoginUseCase>(
  (ref) => LoginUseCase(ref.watch(authRepositoryProvider)),
);

final productsRepositoryProvider = Provider<ProductsRepository>(
  (ref) => ProductsRepositoryImpl(
    ref.watch(apiClientProvider),
    ref.watch(preferencesStoreProvider),
  ),
);

final cartRepositoryProvider = Provider<CartRepository>(
  (ref) => CartRepositoryImpl(
    ref.watch(preferencesStoreProvider),
    ref.watch(apiClientProvider),
  ),
);

final sessionProvider = NotifierProvider<SessionController, SessionState>(
  SessionController.new,
);
final productsProvider = NotifierProvider<ProductsController, ProductsState>(
  ProductsController.new,
);
final cartProvider = NotifierProvider<CartController, CartState>(
  CartController.new,
);

final categoriesProvider = FutureProvider<Result<List<ProductCategory>>>((
  ref,
) async {
  return ref.watch(productsRepositoryProvider).getCategories();
});

final productDetailsProvider = FutureProvider.family<Result<Product>, int>((
  ref,
  productId,
) async {
  return ref.watch(productsRepositoryProvider).getProduct(productId);
});

final profileProvider = FutureProvider<Result<AppUser>>((ref) async {
  return ref.watch(authRepositoryProvider).getCurrentUser();
});

final navigationIndexProvider = StateProvider<int>((ref) => 0);
final selectedProductProvider = StateProvider<Product?>((ref) => null);

final wishlistProvider =
    NotifierProvider<WishlistController, Map<int, Product>>(
      WishlistController.new,
    );
final showWishlistOnlyProvider = StateProvider<bool>((ref) => false);
