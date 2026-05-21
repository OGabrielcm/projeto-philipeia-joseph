-- =============================================================
-- Philipeia — Dados iniciais (catálogo)
-- Executar APÓS script.sql
-- =============================================================

USE philipeia;
GO

-- -------------------------------------------------------------
-- Estilos de chopp (volumes: 30L e 50L)
-- -------------------------------------------------------------
IF NOT EXISTS (SELECT 1 FROM styles WHERE nome = 'Pilsen' AND categoria = 'chopp')
BEGIN
    INSERT INTO styles (nome, categoria) VALUES ('Pilsen', 'chopp');
    PRINT 'Style inserido: Pilsen (chopp)';
END

IF NOT EXISTS (SELECT 1 FROM styles WHERE nome = 'Weiss' AND categoria = 'chopp')
BEGIN
    INSERT INTO styles (nome, categoria) VALUES ('Weiss', 'chopp');
    PRINT 'Style inserido: Weiss (chopp)';
END

IF NOT EXISTS (SELECT 1 FROM styles WHERE nome = 'Red Ale' AND categoria = 'chopp')
BEGIN
    INSERT INTO styles (nome, categoria) VALUES ('Red Ale', 'chopp');
    PRINT 'Style inserido: Red Ale (chopp)';
END

IF NOT EXISTS (SELECT 1 FROM styles WHERE nome = 'Stout' AND categoria = 'chopp')
BEGIN
    INSERT INTO styles (nome, categoria) VALUES ('Stout', 'chopp');
    PRINT 'Style inserido: Stout (chopp)';
END
GO

-- Volumes para chopp (30L e 50L)
INSERT INTO style_volumes (style_id, volume_litros, preco)
SELECT s.id, v.volume_litros, v.preco
FROM styles s
CROSS JOIN (
    VALUES
        (30, 320.00),
        (50, 490.00)
) AS v(volume_litros, preco)
WHERE s.nome = 'Pilsen' AND s.categoria = 'chopp'
  AND NOT EXISTS (
    SELECT 1 FROM style_volumes sv
    WHERE sv.style_id = s.id AND sv.volume_litros = v.volume_litros
  );

INSERT INTO style_volumes (style_id, volume_litros, preco)
SELECT s.id, v.volume_litros, v.preco
FROM styles s
CROSS JOIN (
    VALUES
        (30, 350.00),
        (50, 530.00)
) AS v(volume_litros, preco)
WHERE s.nome = 'Weiss' AND s.categoria = 'chopp'
  AND NOT EXISTS (
    SELECT 1 FROM style_volumes sv
    WHERE sv.style_id = s.id AND sv.volume_litros = v.volume_litros
  );

INSERT INTO style_volumes (style_id, volume_litros, preco)
SELECT s.id, v.volume_litros, v.preco
FROM styles s
CROSS JOIN (
    VALUES
        (30, 370.00),
        (50, 560.00)
) AS v(volume_litros, preco)
WHERE s.nome = 'Red Ale' AND s.categoria = 'chopp'
  AND NOT EXISTS (
    SELECT 1 FROM style_volumes sv
    WHERE sv.style_id = s.id AND sv.volume_litros = v.volume_litros
  );

INSERT INTO style_volumes (style_id, volume_litros, preco)
SELECT s.id, v.volume_litros, v.preco
FROM styles s
CROSS JOIN (
    VALUES
        (30, 390.00),
        (50, 590.00)
) AS v(volume_litros, preco)
WHERE s.nome = 'Stout' AND s.categoria = 'chopp'
  AND NOT EXISTS (
    SELECT 1 FROM style_volumes sv
    WHERE sv.style_id = s.id AND sv.volume_litros = v.volume_litros
  );
GO

-- -------------------------------------------------------------
-- Estilos de drink (volumes: 15L e 20L)
-- -------------------------------------------------------------
IF NOT EXISTS (SELECT 1 FROM styles WHERE nome = 'Caipirinha de Limão' AND categoria = 'drink')
BEGIN
    INSERT INTO styles (nome, categoria) VALUES ('Caipirinha de Limão', 'drink');
    PRINT 'Style inserido: Caipirinha de Limão (drink)';
END

IF NOT EXISTS (SELECT 1 FROM styles WHERE nome = 'Gin Tônica' AND categoria = 'drink')
BEGIN
    INSERT INTO styles (nome, categoria) VALUES ('Gin Tônica', 'drink');
    PRINT 'Style inserido: Gin Tônica (drink)';
END
GO

-- Volumes para drink (15L e 20L)
INSERT INTO style_volumes (style_id, volume_litros, preco)
SELECT s.id, v.volume_litros, v.preco
FROM styles s
CROSS JOIN (
    VALUES
        (15, 280.00),
        (20, 360.00)
) AS v(volume_litros, preco)
WHERE s.nome = 'Caipirinha de Limão' AND s.categoria = 'drink'
  AND NOT EXISTS (
    SELECT 1 FROM style_volumes sv
    WHERE sv.style_id = s.id AND sv.volume_litros = v.volume_litros
  );

INSERT INTO style_volumes (style_id, volume_litros, preco)
SELECT s.id, v.volume_litros, v.preco
FROM styles s
CROSS JOIN (
    VALUES
        (15, 300.00),
        (20, 390.00)
) AS v(volume_litros, preco)
WHERE s.nome = 'Gin Tônica' AND s.categoria = 'drink'
  AND NOT EXISTS (
    SELECT 1 FROM style_volumes sv
    WHERE sv.style_id = s.id AND sv.volume_litros = v.volume_litros
  );
GO

-- -------------------------------------------------------------
-- Combo de exemplo
-- -------------------------------------------------------------
IF NOT EXISTS (SELECT 1 FROM combos WHERE nome = 'Combo Festa (Pilsen 30L + Weiss 30L)')
BEGIN
    DECLARE @sv_pilsen30 INT = (
        SELECT sv.id FROM style_volumes sv
        JOIN styles s ON s.id = sv.style_id
        WHERE s.nome = 'Pilsen' AND s.categoria = 'chopp' AND sv.volume_litros = 30
    );
    DECLARE @sv_weiss30 INT = (
        SELECT sv.id FROM style_volumes sv
        JOIN styles s ON s.id = sv.style_id
        WHERE s.nome = 'Weiss' AND s.categoria = 'chopp' AND sv.volume_litros = 30
    );

    IF @sv_pilsen30 IS NOT NULL AND @sv_weiss30 IS NOT NULL
    BEGIN
        INSERT INTO combos (nome, style_volume_1_id, style_volume_2_id, preco)
        VALUES ('Combo Festa (Pilsen 30L + Weiss 30L)', @sv_pilsen30, @sv_weiss30, 620.00);
        PRINT 'Combo inserido: Combo Festa (Pilsen 30L + Weiss 30L)';
    END
    ELSE
        PRINT 'AVISO: Volumes não encontrados para criar o combo. Verifique os styles.';
END
ELSE
    PRINT 'Combo Festa já existe — ignorado.';
GO

-- -------------------------------------------------------------
-- Verificação final
-- -------------------------------------------------------------
PRINT '';
PRINT '=== Resumo do catálogo inserido ===';
SELECT
    s.nome        AS estilo,
    s.categoria,
    sv.volume_litros AS [volume (L)],
    sv.preco      AS [preço (R$)],
    sv.ativo
FROM styles s
JOIN style_volumes sv ON sv.style_id = s.id
ORDER BY s.categoria, s.nome, sv.volume_litros;

PRINT '';
SELECT
    c.nome AS combo,
    c.preco AS [preço (R$)],
    s1.nome + ' ' + CAST(sv1.volume_litros AS VARCHAR) + 'L' AS item_1,
    s2.nome + ' ' + CAST(sv2.volume_litros AS VARCHAR) + 'L' AS item_2
FROM combos c
JOIN style_volumes sv1 ON sv1.id = c.style_volume_1_id
JOIN styles s1         ON s1.id  = sv1.style_id
JOIN style_volumes sv2 ON sv2.id = c.style_volume_2_id
JOIN styles s2         ON s2.id  = sv2.style_id;

PRINT '=== inserts.sql concluído. ===';
