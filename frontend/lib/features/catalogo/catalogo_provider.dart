import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/dio_client.dart';
import 'catalogo_models.dart';

final catalogoProvider = FutureProvider<CatalogoData>((ref) async {
  final dio = ref.watch(dioProvider);

  final results = await Future.wait([
    dio.get('/catalogo/estilos'),
    dio.get('/catalogo/combos'),
  ]);

  final estilos = (results[0].data as List)
      .map((e) => Estilo.fromJson(e as Map<String, dynamic>))
      .toList();

  final combos = (results[1].data as List)
      .map((e) => Combo.fromJson(e as Map<String, dynamic>))
      .toList();

  return CatalogoData(estilos: estilos, combos: combos);
});
