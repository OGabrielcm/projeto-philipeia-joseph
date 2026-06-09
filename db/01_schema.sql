-- =============================================================
-- Philipeia — 01_schema.sql
-- Cria o banco e todas as tabelas (idempotente: seguro rodar
-- múltiplas vezes sem apagar dados existentes)
-- =============================================================
-- Pré-requisito: SQL Server Express rodando em .\SQLEXPRESS
-- Execução:  sqlcmd -S ".\SQLEXPRESS" -E -i db\01_schema.sql
--            ou abrir no SSMS e executar (F5)
-- =============================================================

-- -------------------------------------------------------------
-- 1. Criar banco (ignora se já existir)
-- -------------------------------------------------------------
IF NOT EXISTS (SELECT name FROM sys.databases WHERE name = N'philipeia')
    CREATE DATABASE philipeia;
GO

USE philipeia;
GO

-- -------------------------------------------------------------
-- 2. customers  (dados cadastrais dos clientes)
-- -------------------------------------------------------------
IF NOT EXISTS (SELECT 1 FROM sysobjects WHERE name = 'customers' AND xtype = 'U')
BEGIN
    CREATE TABLE customers (
        id                       INT IDENTITY(1,1) PRIMARY KEY,
        nome                     NVARCHAR(120) NOT NULL,
        cpf                      CHAR(11)      NOT NULL UNIQUE,
        telefone                 CHAR(11)      NOT NULL,
        telefone_whatsapp        CHAR(11)      NULL,
        whatsapp_igual_principal BIT           NOT NULL DEFAULT 0,
        email                    NVARCHAR(120) NULL,
        endereco_logradouro      NVARCHAR(200) NOT NULL,
        endereco_numero          NVARCHAR(20)  NOT NULL,
        endereco_complemento     NVARCHAR(100) NULL,
        endereco_bairro          NVARCHAR(100) NOT NULL,
        endereco_cidade          NVARCHAR(100) NOT NULL,
        endereco_estado          CHAR(2)       NOT NULL,
        endereco_cep             CHAR(8)       NOT NULL,
        deleted_at               DATETIME2     NULL,
        created_at               DATETIME2     NOT NULL DEFAULT GETDATE(),
        updated_at               DATETIME2     NOT NULL DEFAULT GETDATE()
    );

    CREATE INDEX IX_customers_cpf  ON customers(cpf);
    CREATE INDEX IX_customers_nome ON customers(nome);

    PRINT 'Tabela customers criada.';
END
ELSE
    PRINT 'Tabela customers já existe — ignorada.';
GO

-- -------------------------------------------------------------
-- 3. styles  (tipos de chopp e drink do catálogo)
-- -------------------------------------------------------------
IF NOT EXISTS (SELECT 1 FROM sysobjects WHERE name = 'styles' AND xtype = 'U')
BEGIN
    CREATE TABLE styles (
        id         INT IDENTITY(1,1) PRIMARY KEY,
        nome       NVARCHAR(100) NOT NULL,
        categoria  NVARCHAR(10)  NOT NULL CHECK (categoria IN ('chopp', 'drink')),
        ativo      BIT           NOT NULL DEFAULT 1,
        created_at DATETIME2     NOT NULL DEFAULT GETDATE(),
        updated_at DATETIME2     NOT NULL DEFAULT GETDATE(),
        CONSTRAINT UQ_styles_nome_categoria UNIQUE (nome, categoria)
    );

    PRINT 'Tabela styles criada.';
END
ELSE
    PRINT 'Tabela styles já existe — ignorada.';
GO

-- -------------------------------------------------------------
-- 4. style_volumes  (volumes disponíveis e preços por estilo)
-- -------------------------------------------------------------
IF NOT EXISTS (SELECT 1 FROM sysobjects WHERE name = 'style_volumes' AND xtype = 'U')
BEGIN
    CREATE TABLE style_volumes (
        id            INT           IDENTITY(1,1) PRIMARY KEY,
        style_id      INT           NOT NULL REFERENCES styles(id) ON DELETE CASCADE,
        volume_litros SMALLINT      NOT NULL CHECK (volume_litros IN (15, 20, 30, 50)),
        preco         DECIMAL(10,2) NOT NULL CHECK (preco >= 0),
        ativo         BIT           NOT NULL DEFAULT 1,
        created_at    DATETIME2     NOT NULL DEFAULT GETDATE(),
        updated_at    DATETIME2     NOT NULL DEFAULT GETDATE(),
        CONSTRAINT UQ_style_volumes UNIQUE (style_id, volume_litros)
    );

    PRINT 'Tabela style_volumes criada.';
END
ELSE
    PRINT 'Tabela style_volumes já existe — ignorada.';
GO

-- -------------------------------------------------------------
-- 5. combos  (pacotes com dois volumes combinados)
-- -------------------------------------------------------------
IF NOT EXISTS (SELECT 1 FROM sysobjects WHERE name = 'combos' AND xtype = 'U')
BEGIN
    CREATE TABLE combos (
        id                INT           IDENTITY(1,1) PRIMARY KEY,
        nome              NVARCHAR(100) NOT NULL UNIQUE,
        style_volume_1_id INT           NOT NULL REFERENCES style_volumes(id),
        style_volume_2_id INT           NOT NULL REFERENCES style_volumes(id),
        preco             DECIMAL(10,2) NOT NULL CHECK (preco >= 0),
        ativo             BIT           NOT NULL DEFAULT 1,
        created_at        DATETIME2     NOT NULL DEFAULT GETDATE(),
        updated_at        DATETIME2     NOT NULL DEFAULT GETDATE(),
        CONSTRAINT CK_combo_sv_diff CHECK (style_volume_1_id <> style_volume_2_id)
    );

    PRINT 'Tabela combos criada.';
END
ELSE
    PRINT 'Tabela combos já existe — ignorada.';
GO

-- -------------------------------------------------------------
-- 6. orders  (pedidos dos eventos)
--    ATENÇÃO: SET QUOTED_IDENTIFIER ON obrigatório para a coluna
--    computada persistida (numero). Sem isso o CREATE TABLE falha.
-- -------------------------------------------------------------
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO

IF NOT EXISTS (SELECT 1 FROM sysobjects WHERE name = 'orders' AND xtype = 'U')
BEGIN
    CREATE TABLE orders (
        id                   INT           IDENTITY(1,1) PRIMARY KEY,
        -- coluna computada: PED-00001, PED-00002 ...
        numero               AS ('PED-' + RIGHT('00000' + CAST(id AS VARCHAR), 5)) PERSISTED,
        customer_id          INT           NOT NULL REFERENCES customers(id),
        status               NVARCHAR(12)  NOT NULL DEFAULT 'pendente'
                                           CHECK (status IN ('pendente', 'confirmado', 'cancelado')),

        data_evento          DATE          NOT NULL,
        hora_inicio          TIME          NOT NULL,
        data_recolhimento    DATE          NOT NULL,
        hora_recolhimento    TIME          NOT NULL,

        endereco_logradouro  NVARCHAR(200) NOT NULL,
        endereco_numero      NVARCHAR(20)  NOT NULL,
        endereco_complemento NVARCHAR(100) NULL,
        endereco_bairro      NVARCHAR(100) NOT NULL,
        endereco_cidade      NVARCHAR(100) NOT NULL,
        endereco_estado      CHAR(2)       NOT NULL,
        endereco_cep         CHAR(8)       NOT NULL,

        observacoes          NVARCHAR(2000) NULL,

        subtotal             DECIMAL(10,2) NOT NULL,
        taxa_instalacao      DECIMAL(10,2) NOT NULL DEFAULT 0,
        desconto             DECIMAL(10,2) NOT NULL DEFAULT 0,
        total                DECIMAL(10,2) NOT NULL,
        total_overridden     BIT           NOT NULL DEFAULT 0,

        cancelled_at         DATETIME2     NULL,
        cancelled_reason     NVARCHAR(500) NULL,

        created_at           DATETIME2     NOT NULL DEFAULT GETDATE(),
        updated_at           DATETIME2     NOT NULL DEFAULT GETDATE(),

        CONSTRAINT CK_orders_recolhimento CHECK (data_recolhimento >= data_evento),
        CONSTRAINT CK_orders_total        CHECK (total >= 0)
    );

    CREATE INDEX IX_orders_status      ON orders(status);
    CREATE INDEX IX_orders_data_evento ON orders(data_evento);
    CREATE INDEX IX_orders_customer    ON orders(customer_id);

    PRINT 'Tabela orders criada.';
END
ELSE
    PRINT 'Tabela orders já existe — ignorada.';
GO

-- -------------------------------------------------------------
-- 7. order_items  (itens/combos de cada pedido)
-- -------------------------------------------------------------
IF NOT EXISTS (SELECT 1 FROM sysobjects WHERE name = 'order_items' AND xtype = 'U')
BEGIN
    CREATE TABLE order_items (
        id              INT           IDENTITY(1,1) PRIMARY KEY,
        order_id        INT           NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
        tipo            NVARCHAR(10)  NOT NULL CHECK (tipo IN ('item', 'combo')),
        style_volume_id INT           NULL REFERENCES style_volumes(id),
        combo_id        INT           NULL REFERENCES combos(id),
        quantidade      SMALLINT      NOT NULL CHECK (quantidade > 0),
        preco_unitario  DECIMAL(10,2) NOT NULL CHECK (preco_unitario >= 0),
        consignado      BIT           NOT NULL DEFAULT 0,
        posicao         SMALLINT      NOT NULL,

        -- exatamente um dos dois FK deve estar preenchido
        CONSTRAINT CK_order_items_tipo CHECK (
            (tipo = 'item'  AND style_volume_id IS NOT NULL AND combo_id IS NULL) OR
            (tipo = 'combo' AND combo_id        IS NOT NULL AND style_volume_id IS NULL)
        ),
        -- consignado só faz sentido para item avulso
        CONSTRAINT CK_order_items_consig CHECK (consignado = 0 OR tipo = 'item')
    );

    PRINT 'Tabela order_items criada.';
END
ELSE
    PRINT 'Tabela order_items já existe — ignorada.';
GO

PRINT '';
PRINT '====================================================';
PRINT ' 01_schema.sql concluído — banco philipeia pronto.';
PRINT ' Execute 02_seed.sql para popular o catálogo.';
PRINT '====================================================';
