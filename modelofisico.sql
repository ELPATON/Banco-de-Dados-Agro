
CREATE DATABASE producao_agricola;
USE producao_agricola;


CREATE TABLE culturas (
    id INT PRIMARY KEY AUTO_INCREMENT,
    nome VARCHAR(100) NOT NULL,
    tipo VARCHAR(50),
    ciclo_producao INT NOT NULL COMMENT 'Tempo em dias',
    observacoes TEXT
);

CREATE TABLE areas (
    id INT PRIMARY KEY AUTO_INCREMENT,
    nome VARCHAR(100) NOT NULL,
    localizacao VARCHAR(200),
    tamanho DECIMAL(10, 2) NOT NULL COMMENT 'Em hectares',
    condicoes_solo VARCHAR(100)
);


CREATE TABLE safras (
    id INT PRIMARY KEY AUTO_INCREMENT,
    cultura_id INT NOT NULL,
    area_id INT NOT NULL,
    data_plantio DATE NOT NULL,
    previsao_colheita DATE NOT NULL,
    quantidade_produzida DECIMAL(10, 2) DEFAULT 0 COMMENT 'Em toneladas',
    FOREIGN KEY (cultura_id) REFERENCES culturas(id),
    FOREIGN KEY (area_id) REFERENCES areas(id)
);


CREATE TABLE insumos (
    id INT PRIMARY KEY AUTO_INCREMENT,
    nome VARCHAR(100) NOT NULL,
    tipo VARCHAR(50) NOT NULL COMMENT 'Ex.: fertilizante, pesticida',
    estoque DECIMAL(10, 2) NOT NULL COMMENT 'Quantidade em estoque',
    custo_unidade DECIMAL(10, 2) NOT NULL
);


CREATE TABLE movimentacao_insumos (
    id INT PRIMARY KEY AUTO_INCREMENT,
    insumo_id INT NOT NULL,
    tipo_movimentacao ENUM('entrada', 'saida') NOT NULL,
    quantidade DECIMAL(10, 2) NOT NULL,
    data_movimentacao DATE DEFAULT NOW(),
    FOREIGN KEY (insumo_id) REFERENCES insumos(id)
);


CREATE TABLE clima (
    id INT PRIMARY KEY AUTO_INCREMENT,
    area_id INT NOT NULL,
    data_registro DATE NOT NULL,
    temperatura DECIMAL(5, 2),
    precipitacao DECIMAL(5, 2),
    observacoes TEXT,
    FOREIGN KEY (area_id) REFERENCES areas(id)
);


CREATE TABLE relatorios_producao (
    id INT PRIMARY KEY AUTO_INCREMENT,
    safra_id INT NOT NULL,
    data_relatorio DATE DEFAULT NOW(),
    detalhes TEXT,
    FOREIGN KEY (safra_id) REFERENCES safras(id)
);


CREATE VIEW V_todas_culturas AS
SELECT * FROM culturas;

-- View de todas as áreas de plantio
CREATE VIEW V_todas_areas AS
SELECT * FROM areas;

CREATE VIEW V_producao_por_safra AS
SELECT 
    s.id AS safra_id, 
    c.nome AS cultura, 
    a.nome AS area, 
    s.data_plantio, 
    s.previsao_colheita, 
    s.quantidade_produzida
FROM safras s
JOIN culturas c ON s.cultura_id = c.id
JOIN areas a ON s.area_id = a.id;


CREATE VIEW V_consumo_insumos AS
SELECT 
    mi.insumo_id,
    i.nome AS insumo,
    mi.tipo_movimentacao,
    SUM(mi.quantidade) AS total_movimentado
FROM movimentacao_insumos mi
JOIN insumos i ON mi.insumo_id = i.id
GROUP BY mi.insumo_id, mi.tipo_movimentacao;

-- Procedures

DELIMITER $$
CREATE PROCEDURE listar_safras_por_cultura(IN cultura_nome VARCHAR(100))
BEGIN
    SELECT 
        s.id AS safra_id, 
        a.nome AS area, 
        s.data_plantio, 
        s.previsao_colheita, 
        s.quantidade_produzida
    FROM safras s
    JOIN culturas c ON s.cultura_id = c.id
    JOIN areas a ON s.area_id = a.id
    WHERE c.nome = cultura_nome
    ORDER BY s.data_plantio DESC;
END$$
DELIMITER ;


DELIMITER $$
CREATE TRIGGER atualizar_estoque_insumos
AFTER INSERT ON movimentacao_insumos
FOR EACH ROW
BEGIN
    IF NEW.tipo_movimentacao = 'saida' THEN
        UPDATE insumos
        SET estoque = estoque - NEW.quantidade
        WHERE id = NEW.insumo_id;
    ELSEIF NEW.tipo_movimentacao = 'entrada' THEN
        UPDATE insumos
        SET estoque = estoque + NEW.quantidade
        WHERE id = NEW.insumo_id;
    END IF;
END$$
DELIMITER ;


INSERT INTO culturas (nome, tipo, ciclo_producao, observacoes)
VALUES ('Soja', 'Grãos', 120, 'Cuidado com pragas durante o ciclo.'),
       ('Milho', 'Grãos', 90, 'Prefere solo argiloso.');

INSERT INTO areas (nome, localizacao, tamanho, condicoes_solo)
VALUES ('Campo 1', 'Coordenadas X, Y', 20.5, 'Solo argiloso'),
       ('Campo 2', 'Coordenadas A, B', 15.2, 'Solo arenoso');

INSERT INTO insumos (nome, tipo, estoque, custo_unidade)
VALUES ('Adubo NPK', 'Fertilizante', 500.0, 30.5),
       ('Defensivo XYZ', 'Pesticida', 200.0, 100.0);

INSERT INTO safras (cultura_id, area_id, data_plantio, previsao_colheita, quantidade_produzida)
VALUES (1, 1, '2024-09-01', '2024-12-30', 10.5),
       (2, 2, '2024-10-01', '2024-12-31', 8.0);


CALL listar_safras_por_cultura('Soja');

DROP DATABASE producao_agricola;