

CREATE DATABASE producao_agricola;
USE producao_agricola;

CREATE TABLE agricultores (
    id INT PRIMARY KEY AUTO_INCREMENT,
    nome VARCHAR(100) NOT NULL,
    telefone VARCHAR(15),
    email VARCHAR(100)
);

CREATE TABLE propriedades (
    id INT PRIMARY KEY AUTO_INCREMENT,
    nome VARCHAR(100) NOT NULL,
    localizacao VARCHAR(255),
    area_total DECIMAL(10, 2),
    agricultor_id INT,
    FOREIGN KEY (agricultor_id) REFERENCES agricultores(id)
);

CREATE TABLE culturas (
    id INT PRIMARY KEY AUTO_INCREMENT,
    nome VARCHAR(100) NOT NULL,
    tipo VARCHAR(100)
);

CREATE TABLE safras (
    id INT PRIMARY KEY AUTO_INCREMENT,
    propriedade_id INT,
    cultura_id INT,
    ano INT,
    area DECIMAL(10, 2),
    rendimento DECIMAL(10, 2),
    FOREIGN KEY (propriedade_id) REFERENCES propriedades(id),
    FOREIGN KEY (cultura_id) REFERENCES culturas(id)
);

CREATE TABLE insumos (
    id INT PRIMARY KEY AUTO_INCREMENT,
    nome VARCHAR(100) NOT NULL,
    preco DECIMAL(10, 2),
    fornecedor VARCHAR(100)
);

CREATE TABLE aplicacoes_insumos (
    id INT PRIMARY KEY AUTO_INCREMENT,
    safra_id INT,
    insumo_id INT,
    quantidade DECIMAL(10, 2),
    FOREIGN KEY (safra_id) REFERENCES safras(id),
    FOREIGN KEY (insumo_id) REFERENCES insumos(id)
);

CREATE TABLE clima (
    id INT PRIMARY KEY AUTO_INCREMENT,
    safra_id INT,
    temperatura_media DECIMAL(5, 2),
    chuva_acumulada DECIMAL(10, 2),
    FOREIGN KEY (safra_id) REFERENCES safras(id)
);

INSERT INTO agricultores (nome, telefone, email) VALUES ('João Silva', '75981234567', 'joao@gmail.com');
INSERT INTO agricultores (nome, telefone, email) VALUES ('Maria Oliveira', '75992345678', 'maria@gmail.com');
INSERT INTO propriedades (nome, localizacao, area_total, agricultor_id) VALUES ('Fazenda Boa Vista', 'Feira de Santana', 100.5, 1);
INSERT INTO propriedades (nome, localizacao, area_total, agricultor_id) VALUES ('Sítio Recanto', 'Serrinha', 50.3, 2);
INSERT INTO culturas (nome, tipo) VALUES ('Milho', 'Cereal');
INSERT INTO culturas (nome, tipo) VALUES ('Soja', 'Grão');
INSERT INTO safras (propriedade_id, cultura_id, ano, area, rendimento) VALUES (1, 1, 2024, 80, 300);
INSERT INTO safras (propriedade_id, cultura_id, ano, area, rendimento) VALUES (2, 2, 2023, 30, 200);
INSERT INTO insumos (nome, preco, fornecedor) VALUES ('Adubo NPK', 120, 'Fertilizantes Ltda');
INSERT INTO insumos (nome, preco, fornecedor) VALUES ('Herbicida X', 60, 'Agroquímica SA');
INSERT INTO aplicacoes_insumos (safra_id, insumo_id, quantidade) VALUES (1, 1, 50);
INSERT INTO aplicacoes_insumos (safra_id, insumo_id, quantidade) VALUES (2, 2, 20);

UPDATE insumos SET preco = 130 WHERE id = 1;
UPDATE propriedades SET area_total = 110 WHERE id = 1;
UPDATE safras SET rendimento = 310 WHERE id = 1;

DELETE FROM aplicacoes_insumos WHERE id = 2;
DELETE FROM culturas WHERE id = 2;
DELETE FROM propriedades WHERE id = 2;

DELIMITER $$

CREATE PROCEDURE ListarSafrasPorAno(IN ano INT)
BEGIN
    SELECT * FROM safras WHERE ano = ano;
END$$

CREATE PROCEDURE AtualizarPrecoInsumo(IN insumo_id INT, IN novo_preco DECIMAL(10, 2))
BEGIN
    UPDATE insumos SET preco = novo_preco WHERE id = insumo_id;
END$$

CREATE PROCEDURE ConsultarColheita(IN safra_id INT)
BEGIN
    SELECT s.id, c.nome AS cultura, s.area, s.rendimento
    FROM safras s
    JOIN culturas c ON s.cultura_id = c.id
    WHERE s.id = safra_id;
END$$

CREATE FUNCTION CalcularCustoTotalInsumos(safra_id INT)
RETURNS DECIMAL(10, 2)
DETERMINISTIC
BEGIN
    RETURN (SELECT SUM(ai.quantidade * i.preco)
            FROM aplicacoes_insumos ai
            JOIN insumos i ON ai.insumo_id = i.id
            WHERE ai.safra_id = safra_id);
END$$

CREATE FUNCTION AreaRestante(area_total DECIMAL(10, 2), area_utilizada DECIMAL(10, 2))
RETURNS DECIMAL(10, 2)
DETERMINISTIC
BEGIN
    RETURN area_total - area_utilizada;
END$$

CREATE FUNCTION CalcularMediaTemperatura(safra_id INT)
RETURNS DECIMAL(5, 2)
DETERMINISTIC
BEGIN
    RETURN (SELECT AVG(temperatura_media) FROM clima WHERE safra_id = safra_id);
END$$

CREATE TRIGGER AtualizarEstoqueInsumo
AFTER INSERT ON aplicacoes_insumos
FOR EACH ROW
BEGIN
    UPDATE insumos SET preco = preco - NEW.quantidade WHERE id = NEW.insumo_id;
END$$

CREATE TRIGGER RestabelecerEstoqueInsumo
AFTER DELETE ON aplicacoes_insumos
FOR EACH ROW
BEGIN
    UPDATE insumos SET preco = preco + OLD.quantidade WHERE id = OLD.insumo_id;
END$$

CREATE TRIGGER AtualizarRendimento
AFTER INSERT ON clima
FOR EACH ROW
BEGIN
    UPDATE safras SET rendimento = rendimento + NEW.chuva_acumulada WHERE id = NEW.safra_id;
END$$

DELIMITER ;

CREATE VIEW V_TodasSafras AS SELECT * FROM safras;
CREATE VIEW V_AreaUtilizada AS SELECT propriedade_id, SUM(area) AS total_area FROM safras GROUP BY propriedade_id;
CREATE VIEW V_RendimentoMedio AS SELECT cultura_id, AVG(rendimento) AS rendimento_medio FROM safras GROUP BY cultura_id;
CREATE VIEW V_AplicacaoInsumos AS SELECT ai.*, i.nome FROM aplicacoes_insumos ai JOIN insumos i ON ai.insumo_id = i.id;
CREATE VIEW V_PropriedadesAgricultores AS SELECT p.*, a.nome AS agricultor FROM propriedades p JOIN agricultores a ON p.agricultor_id = a.id;

SELECT * FROM V_TodasSafras WHERE ano = 2024;
SELECT p.nome, SUM(s.area) AS area_total FROM propriedades p JOIN safras s ON p.id = s.propriedade_id GROUP BY p.nome HAVING area_total > 50 ORDER BY area_total DESC;

