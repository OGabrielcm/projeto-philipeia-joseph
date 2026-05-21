-- =============================================================
-- Philipeia — Schema inicial (MVP)
-- Banco: SQL Server | Executar via SSMS
-- =============================================================

-- -------------------------------------------------------------
-- customers
-- -------------------------------------------------------------
CREATE TABLE customers (
  id                          INT IDENTITY(1,1) PRIMARY KEY,
  nome                        NVARCHAR(120)  NOT NULL,
  cpf                         CHAR(11)       NOT NULL UNIQUE,
  telefone                    CHAR(11)       NOT NULL,
  telefone_whatsapp           CHAR(11)       NULL,
  whatsapp_igual_principal    BIT            NOT NULL DEFAULT 0,
  email                       NVARCHAR(120)  NULL,
  endereco_logradouro         NVARCHAR(200)  NOT NULL,
  endereco_numero             NVARCHAR(20)   NOT NULL,
  endereco_complemento        NVARCHAR(100)  NULL,
  endereco_bairro             NVARCHAR(100)  NOT NULL,
  endereco_cidade             NVARCHAR(100)  NOT NULL,
  endereco_estado             CHAR(2)        NOT NULL,
  endereco_cep                CHAR(8)        NOT NULL,
  deleted_at                  DATETIME2      NULL,
  created_at                  DATETIME2      NOT NULL DEFAULT GETDATE(),
  updated_at                  DATETIME2      NOT NULL DEFAULT GETDATE()
);

CREATE INDEX IX_customers_cpf  ON customers(cpf);
CREATE INDEX IX_customers_nome ON customers(nome);

-- -------------------------------------------------------------
-- styles
-- -------------------------------------------------------------
CREATE TABLE styles (
  id          INT IDENTITY(1,1) PRIMARY KEY,
  nome        NVARCHAR(100) NOT NULL,
  categoria   NVARCHAR(10)  NOT NULL CHECK (categoria IN ('chopp', 'drink')),
  ativo       BIT           NOT NULL DEFAULT 1,
  created_at  DATETIME2     NOT NULL DEFAULT GETDATE(),
  updated_at  DATETIME2     NOT NULL DEFAULT GETDATE(),
  CONSTRAINT UQ_styles_nome_categoria UNIQUE (nome, categoria)
);

-- -------------------------------------------------------------
-- style_volumes
-- -------------------------------------------------------------
CREATE TABLE style_volumes (
  id             INT IDENTITY(1,1) PRIMARY KEY,
  style_id       INT       NOT NULL REFERENCES styles(id) ON DELETE CASCADE,
  volume_litros  SMALLINT  NOT NULL CHECK (volume_litros IN (15, 20, 30, 50)),
  preco          DECIMAL(10,2) NOT NULL CHECK (preco >= 0),
  ativo          BIT       NOT NULL DEFAULT 1,
  created_at     DATETIME2 NOT NULL DEFAULT GETDATE(),
  updated_at     DATETIME2 NOT NULL DEFAULT GETDATE(),
  CONSTRAINT UQ_style_volumes UNIQUE (style_id, volume_litros)
);

-- -------------------------------------------------------------
-- combos
-- -------------------------------------------------------------
CREATE TABLE combos (
  id                 INT IDENTITY(1,1) PRIMARY KEY,
  nome               NVARCHAR(100) NOT NULL UNIQUE,
  style_volume_1_id  INT           NOT NULL REFERENCES style_volumes(id),
  style_volume_2_id  INT           NOT NULL REFERENCES style_volumes(id),
  preco              DECIMAL(10,2) NOT NULL CHECK (preco >= 0),
  ativo              BIT           NOT NULL DEFAULT 1,
  created_at         DATETIME2     NOT NULL DEFAULT GETDATE(),
  updated_at         DATETIME2     NOT NULL DEFAULT GETDATE(),
  CONSTRAINT CK_combo_sv_diff CHECK (style_volume_1_id <> style_volume_2_id)
);

-- -------------------------------------------------------------
-- orders
-- -------------------------------------------------------------
CREATE TABLE orders (
  id                    INT IDENTITY(1,1) PRIMARY KEY,
  numero                AS ('PED-' + RIGHT('00000' + CAST(id AS VARCHAR), 5)) PERSISTED,
  customer_id           INT            NOT NULL REFERENCES customers(id),
  status                NVARCHAR(12)   NOT NULL DEFAULT 'pendente'
                          CHECK (status IN ('pendente', 'confirmado', 'cancelado')),

  data_evento           DATE           NOT NULL,
  hora_inicio           TIME           NOT NULL,
  data_recolhimento     DATE           NOT NULL,
  hora_recolhimento     TIME           NOT NULL,

  endereco_logradouro   NVARCHAR(200)  NOT NULL,
  endereco_numero       NVARCHAR(20)   NOT NULL,
  endereco_complemento  NVARCHAR(100)  NULL,
  endereco_bairro       NVARCHAR(100)  NOT NULL,
  endereco_cidade       NVARCHAR(100)  NOT NULL,
  endereco_estado       CHAR(2)        NOT NULL,
  endereco_cep          CHAR(8)        NOT NULL,

  observacoes           NVARCHAR(2000) NULL,

  subtotal              DECIMAL(10,2)  NOT NULL,
  taxa_instalacao       DECIMAL(10,2)  NOT NULL DEFAULT 0,
  desconto              DECIMAL(10,2)  NOT NULL DEFAULT 0,
  total                 DECIMAL(10,2)  NOT NULL,
  total_overridden      BIT            NOT NULL DEFAULT 0,

  cancelled_at          DATETIME2      NULL,
  cancelled_reason      NVARCHAR(500)  NULL,

  created_at            DATETIME2      NOT NULL DEFAULT GETDATE(),
  updated_at            DATETIME2      NOT NULL DEFAULT GETDATE(),

  CONSTRAINT CK_orders_recolhimento CHECK (data_recolhimento >= data_evento),
  CONSTRAINT CK_orders_total        CHECK (total >= 0)
);

CREATE INDEX IX_orders_status      ON orders(status);
CREATE INDEX IX_orders_data_evento ON orders(data_evento);
CREATE INDEX IX_orders_customer    ON orders(customer_id);

-- -------------------------------------------------------------
-- order_items
-- -------------------------------------------------------------
CREATE TABLE order_items (
  id              INT IDENTITY(1,1) PRIMARY KEY,
  order_id        INT           NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
  tipo            NVARCHAR(10)  NOT NULL CHECK (tipo IN ('item', 'combo')),
  style_volume_id INT           NULL REFERENCES style_volumes(id),
  combo_id        INT           NULL REFERENCES combos(id),
  quantidade      SMALLINT      NOT NULL CHECK (quantidade > 0),
  preco_unitario  DECIMAL(10,2) NOT NULL CHECK (preco_unitario >= 0),
  consignado      BIT           NOT NULL DEFAULT 0,
  posicao         SMALLINT      NOT NULL,
  CONSTRAINT CK_order_items_tipo CHECK (
    (tipo = 'item'  AND style_volume_id IS NOT NULL AND combo_id IS NULL) OR
    (tipo = 'combo' AND combo_id IS NOT NULL AND style_volume_id IS NULL)
  ),
  CONSTRAINT CK_order_items_consig CHECK (
    consignado = 0 OR tipo = 'item'
  )
);
