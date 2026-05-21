class StyleVolume {
  const StyleVolume({
    required this.id,
    required this.volumeLitros,
    required this.preco,
  });

  final int id;
  final int volumeLitros;
  final double preco;

  factory StyleVolume.fromJson(Map<String, dynamic> j) => StyleVolume(
        id:            j['id'] as int,
        volumeLitros:  j['volume_litros'] as int,
        preco:         (j['preco'] as num).toDouble(),
      );
}

class Estilo {
  const Estilo({
    required this.id,
    required this.nome,
    required this.categoria,
    required this.volumes,
  });

  final int id;
  final String nome;
  final String categoria; // 'chopp' | 'drink'
  final List<StyleVolume> volumes;

  factory Estilo.fromJson(Map<String, dynamic> j) => Estilo(
        id:        j['id'] as int,
        nome:      j['nome'] as String,
        categoria: j['categoria'] as String,
        volumes:   (j['volumes'] as List)
            .map((v) => StyleVolume.fromJson(v as Map<String, dynamic>))
            .toList(),
      );
}

class ComboItem {
  const ComboItem({
    required this.styleVolumeId,
    required this.styleNome,
    required this.volumeLitros,
    required this.preco,
  });

  final int styleVolumeId;
  final String styleNome;
  final int volumeLitros;
  final double preco;

  factory ComboItem.fromJson(Map<String, dynamic> j) => ComboItem(
        styleVolumeId: j['style_volume_id'] as int,
        styleNome:     j['style_nome'] as String,
        volumeLitros:  j['volume_litros'] as int,
        preco:         (j['preco'] as num).toDouble(),
      );
}

class Combo {
  const Combo({
    required this.id,
    required this.nome,
    required this.preco,
    required this.item1,
    required this.item2,
  });

  final int id;
  final String nome;
  final double preco;
  final ComboItem item1;
  final ComboItem item2;

  factory Combo.fromJson(Map<String, dynamic> j) => Combo(
        id:    j['id'] as int,
        nome:  j['nome'] as String,
        preco: (j['preco'] as num).toDouble(),
        item1: ComboItem.fromJson(j['item_1'] as Map<String, dynamic>),
        item2: ComboItem.fromJson(j['item_2'] as Map<String, dynamic>),
      );
}

class CatalogoData {
  const CatalogoData({required this.estilos, required this.combos});
  final List<Estilo> estilos;
  final List<Combo> combos;
}
