-- =============================================================
-- Philipeia — Seed (dados iniciais)
-- =============================================================

-- Estilos de chopp
INSERT INTO styles (nome, categoria) VALUES
  ('Pilsen',         'chopp'),
  ('Weiss',          'chopp'),
  ('Red Ale',        'chopp'),
  ('Stout',          'chopp');

-- Volumes para chopp (30L e 50L)
INSERT INTO style_volumes (style_id, volume_litros, preco) VALUES
  (1, 30, 320.00), (1, 50, 490.00),
  (2, 30, 350.00), (2, 50, 530.00),
  (3, 30, 370.00), (3, 50, 560.00),
  (4, 30, 390.00), (4, 50, 590.00);

-- Estilos de drink
INSERT INTO styles (nome, categoria) VALUES
  ('Caipirinha de Limão', 'drink'),
  ('Gin Tônica',          'drink');

-- Volumes para drink (15L e 20L)
INSERT INTO style_volumes (style_id, volume_litros, preco) VALUES
  (5, 15, 280.00), (5, 20, 360.00),
  (6, 15, 300.00), (6, 20, 390.00);

-- Combo exemplo
INSERT INTO combos (nome, style_volume_1_id, style_volume_2_id, preco) VALUES
  ('Combo Festa (Pilsen 30L + Weiss 30L)', 1, 3, 620.00);
