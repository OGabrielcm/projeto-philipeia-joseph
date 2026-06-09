-- =============================================================
-- Philipeia — 02_seed.sql
-- Dados iniciais do catálogo (idempotente: ignora registros
-- que já existam, seguro rodar múltiplas vezes)
--
-- NOTA DE ENCODING:
--   Nomes com acentos usam NCHAR(n) em vez de literais acentuados
--   para garantir o Unicode correto independente do encoding com
--   que o sqlcmd leu o arquivo (CP1252, UTF-8, UTF-8 BOM etc).
--     ã = NCHAR(227)   →  Caipirinha de Limão
--     ô = NCHAR(244)   →  Gin Tônica
-- =============================================================
-- Pré-requisito: 01_schema.sql já executado
-- Execução:  sqlcmd -S ".\SQLEXPRESS" -E -i db\02_seed.sql
--            ou duplo-clique em db\setup.bat
-- =============================================================

USE philipeia;
GO

-- Helper: monta os nomes acentuados uma vez só
DECLARE @caipirinha NVARCHAR(100) = N'Caipirinha de Lim' + NCHAR(227) + N'o';  -- Caipirinha de Limão
DECLARE @gin        NVARCHAR(100) = N'Gin T'             + NCHAR(244) + N'nica'; -- Gin Tônica

-- -------------------------------------------------------------
-- Estilos de chopp  (4 estilos × volumes 30L e 50L)
-- -------------------------------------------------------------
IF NOT EXISTS (SELECT 1 FROM styles WHERE nome = N'Pilsen'  AND categoria = 'chopp')
    INSERT INTO styles (nome, categoria) VALUES (N'Pilsen',  'chopp');

IF NOT EXISTS (SELECT 1 FROM styles WHERE nome = N'Weiss'   AND categoria = 'chopp')
    INSERT INTO styles (nome, categoria) VALUES (N'Weiss',   'chopp');

IF NOT EXISTS (SELECT 1 FROM styles WHERE nome = N'Red Ale' AND categoria = 'chopp')
    INSERT INTO styles (nome, categoria) VALUES (N'Red Ale', 'chopp');

IF NOT EXISTS (SELECT 1 FROM styles WHERE nome = N'Stout'   AND categoria = 'chopp')
    INSERT INTO styles (nome, categoria) VALUES (N'Stout',   'chopp');

-- Volumes 30L e 50L para cada chopp
INSERT INTO style_volumes (style_id, volume_litros, preco)
SELECT s.id, v.vol, v.preco FROM styles s
CROSS JOIN (VALUES (30, 320.00),(50, 490.00)) AS v(vol, preco)
WHERE s.nome = N'Pilsen' AND s.categoria = 'chopp'
  AND NOT EXISTS (SELECT 1 FROM style_volumes sv WHERE sv.style_id = s.id AND sv.volume_litros = v.vol);

INSERT INTO style_volumes (style_id, volume_litros, preco)
SELECT s.id, v.vol, v.preco FROM styles s
CROSS JOIN (VALUES (30, 350.00),(50, 530.00)) AS v(vol, preco)
WHERE s.nome = N'Weiss' AND s.categoria = 'chopp'
  AND NOT EXISTS (SELECT 1 FROM style_volumes sv WHERE sv.style_id = s.id AND sv.volume_litros = v.vol);

INSERT INTO style_volumes (style_id, volume_litros, preco)
SELECT s.id, v.vol, v.preco FROM styles s
CROSS JOIN (VALUES (30, 370.00),(50, 560.00)) AS v(vol, preco)
WHERE s.nome = N'Red Ale' AND s.categoria = 'chopp'
  AND NOT EXISTS (SELECT 1 FROM style_volumes sv WHERE sv.style_id = s.id AND sv.volume_litros = v.vol);

INSERT INTO style_volumes (style_id, volume_litros, preco)
SELECT s.id, v.vol, v.preco FROM styles s
CROSS JOIN (VALUES (30, 390.00),(50, 590.00)) AS v(vol, preco)
WHERE s.nome = N'Stout' AND s.categoria = 'chopp'
  AND NOT EXISTS (SELECT 1 FROM style_volumes sv WHERE sv.style_id = s.id AND sv.volume_litros = v.vol);

-- -------------------------------------------------------------
-- Estilos de drink  (2 estilos × volumes 15L e 20L)
-- -------------------------------------------------------------
IF NOT EXISTS (SELECT 1 FROM styles WHERE nome = @caipirinha AND categoria = 'drink')
    INSERT INTO styles (nome, categoria) VALUES (@caipirinha, 'drink');

IF NOT EXISTS (SELECT 1 FROM styles WHERE nome = @gin AND categoria = 'drink')
    INSERT INTO styles (nome, categoria) VALUES (@gin, 'drink');

INSERT INTO style_volumes (style_id, volume_litros, preco)
SELECT s.id, v.vol, v.preco FROM styles s
CROSS JOIN (VALUES (15, 280.00),(20, 360.00)) AS v(vol, preco)
WHERE s.nome = @caipirinha AND s.categoria = 'drink'
  AND NOT EXISTS (SELECT 1 FROM style_volumes sv WHERE sv.style_id = s.id AND sv.volume_litros = v.vol);

INSERT INTO style_volumes (style_id, volume_litros, preco)
SELECT s.id, v.vol, v.preco FROM styles s
CROSS JOIN (VALUES (15, 300.00),(20, 390.00)) AS v(vol, preco)
WHERE s.nome = @gin AND s.categoria = 'drink'
  AND NOT EXISTS (SELECT 1 FROM style_volumes sv WHERE sv.style_id = s.id AND sv.volume_litros = v.vol);

-- -------------------------------------------------------------
-- Combo de exemplo  (usa subquery, não depende de IDs fixos)
-- -------------------------------------------------------------
IF NOT EXISTS (SELECT 1 FROM combos WHERE nome = N'Combo Festa (Pilsen 30L + Weiss 30L)')
BEGIN
    DECLARE @sv1 INT = (
        SELECT sv.id FROM style_volumes sv JOIN styles s ON s.id = sv.style_id
        WHERE s.nome = N'Pilsen' AND s.categoria = 'chopp' AND sv.volume_litros = 30
    );
    DECLARE @sv2 INT = (
        SELECT sv.id FROM style_volumes sv JOIN styles s ON s.id = sv.style_id
        WHERE s.nome = N'Weiss' AND s.categoria = 'chopp' AND sv.volume_litros = 30
    );

    IF @sv1 IS NOT NULL AND @sv2 IS NOT NULL
        INSERT INTO combos (nome, style_volume_1_id, style_volume_2_id, preco)
        VALUES (N'Combo Festa (Pilsen 30L + Weiss 30L)', @sv1, @sv2, 620.00);
    ELSE
        PRINT 'AVISO: volumes nao encontrados — combo nao inserido.';
END
GO

-- -------------------------------------------------------------
-- Verificação final
-- -------------------------------------------------------------
PRINT '';
PRINT '=== Catalogo inserido ===';

SELECT
    s.nome                AS estilo,
    s.categoria,
    sv.volume_litros      AS [vol (L)],
    sv.preco              AS [preco (R$)]
FROM styles s
JOIN style_volumes sv ON sv.style_id = s.id
ORDER BY s.categoria, s.nome, sv.volume_litros;

SELECT
    c.nome                                                  AS combo,
    c.preco                                                 AS [preco (R$)],
    s1.nome + ' ' + CAST(sv1.volume_litros AS VARCHAR) + 'L' AS item_1,
    s2.nome + ' ' + CAST(sv2.volume_litros AS VARCHAR) + 'L' AS item_2
FROM combos c
JOIN style_volumes sv1 ON sv1.id = c.style_volume_1_id
JOIN styles s1         ON s1.id  = sv1.style_id
JOIN style_volumes sv2 ON sv2.id = c.style_volume_2_id
JOIN styles s2         ON s2.id  = sv2.style_id;

PRINT '=== 02_seed.sql concluido. ===';
