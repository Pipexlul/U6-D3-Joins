-- Create Database
CREATE DATABASE "desafio3-Felipe-Guajardo-117";

-- Connect to created database
\c "desafio3-Felipe-Guajardo-117"

-- Create users table (BONUS: Constraint is not required, but it's a nice touch for data validation)
CREATE TABLE IF NOT EXISTS users (
  id SERIAL PRIMARY KEY,
  name VARCHAR NOT NULL,
  surname VARCHAR NOT NULL,
  email VARCHAR NOT NULL,
  role VARCHAR NOT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMP NOT NULL DEFAULT NOW(),
  CONSTRAINT role_check CHECK (role IN ('administrator', 'user'))
);

-- Create posts table (BONUS: Usage of foreign key)
CREATE TABLE IF NOT EXISTS posts (
  id SERIAL PRIMARY KEY,
  title VARCHAR,
  content TEXT,
  featured BOOLEAN NOT NULL DEFAULT (random() < 0.5),
  user_id BIGINT REFERENCES users (id) ON DELETE CASCADE,
  created_at TIMESTAMP NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);

-- Create comments table
CREATE TABLE IF NOT EXISTS comments (
  id SERIAL PRIMARY KEY,
  content TEXT,
  user_id BIGINT REFERENCES users (id) ON DELETE CASCADE,
  post_id BIGINT REFERENCES posts (id) ON DELETE CASCADE,
  created_at TIMESTAMP NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);

-- BONUS SECTION
-- Create function to prevent custom insert value or modification of created_at fields and automatically update the updated_at fields on tables (on update)
-- TODO: Improvements could be made such as merging the two BEFORE UPDATE triggers and add the created_at and updated_at columns dynamically
CREATE FUNCTION config_table_timestamp_fields(table_name TEXT) RETURNS VOID AS $$
DECLARE
  constraint_created_at_update TEXT;
  constraint_created_at_default TEXT;
  constraint_updated_at TEXT;
BEGIN
  constraint_created_at_update = table_name || '_created_at_constraint_update';
  constraint_created_at_default = table_name || '_created_at_constraint_default';
  constraint_updated_at = table_name || '_updated_at_constraint';

  EXECUTE format('
    CREATE OR REPLACE FUNCTION prevent_created_at_update() RETURNS TRIGGER AS $innerfunc$
    BEGIN
      IF OLD.created_at <> NEW.created_at THEN
        RAISE EXCEPTION ''Cannot update created_at column in %4$I'';
      END IF;
      RETURN NEW;
    END;
    $innerfunc$ LANGUAGE plpgsql;

    CREATE OR REPLACE FUNCTION prevent_created_at_custom_insert() RETURNS TRIGGER AS $innerfunc$
    BEGIN
      NEW.created_at = NOW();
      RETURN NEW;
    END;
    $innerfunc$ LANGUAGE plpgsql;

    CREATE OR REPLACE FUNCTION update_updated_at() RETURNS TRIGGER AS $innerfunc$
    BEGIN
      NEW.updated_at = NOW();
      RETURN NEW;
    END;
    $innerfunc$ LANGUAGE plpgsql;

    CREATE OR REPLACE TRIGGER %1$I
    BEFORE UPDATE ON %4$I
    FOR EACH ROW
    EXECUTE FUNCTION prevent_created_at_update();

    CREATE OR REPLACE TRIGGER %2$I
    BEFORE INSERT ON %4$I
    FOR EACH ROW
    EXECUTE FUNCTION prevent_created_at_custom_insert();

    CREATE OR REPLACE TRIGGER %3$I
    BEFORE UPDATE ON %4$I
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at();
', constraint_created_at_update, constraint_created_at_default, constraint_updated_at, table_name);
END;
$$ LANGUAGE plpgsql;

-- Apply TIMESTAMP config to all created tables
SELECT config_table_timestamp_fields('users');
SELECT config_table_timestamp_fields('posts');
SELECT config_table_timestamp_fields('comments');

-- Insert 5 users into users table
INSERT INTO users (name, surname, email, role) VALUES ('Michael', 'Luce', 'MichaelPLuce@jourrapide.com', 'user');
INSERT INTO users (name, surname, email, role) VALUES ('Joseph', 'Metcalf', 'JosephRMetcalf@armyspy.com', 'administrator');
INSERT INTO users (name, surname, email, role) VALUES ('George', 'McMillan', 'GeorgeGMcMillan@rhyta.com', 'user');
INSERT INTO users (name, surname, email, role) VALUES ('Irene', 'Smith', 'IreneRSmith@armyspy.com', 'user');
INSERT INTO users (name, surname, email, role) VALUES ('Racheal', 'Lewis', 'RachealALewis@dayrep.com', 'administrator');

-- Old way of inserting entries, the method above is prefered so each query can be done individually to get a different created_at value
-- INSERT INTO users (name, surname, email, role) VALUES
-- ('Michael', 'Luce', 'MichaelPLuce@jourrapide.com', 'user'),
-- ('Joseph', 'Metcalf', 'JosephRMetcalf@armyspy.com', 'administrator'),
-- ('George', 'McMillan', 'GeorgeGMcMillan@rhyta.com', 'user'),
-- ('Irene', 'Smith', 'IreneRSmith@armyspy.com', 'user'),
-- ('Racheal', 'Lewis', 'RachealALewis@dayrep.com', 'administrator');

-- Insert 5 posts into posts table
INSERT INTO posts (title, content, user_id) VALUES
('Si haces esto no eres un true programmer', 'Si prefieres la version grafica de cualquier herramienta, no eres un verdadero programador!!!! #TeamTerminal', 2);
INSERT INTO posts (title, content, user_id) VALUES
('Me hackearon', 'Quiero pedir perdon por mi post anterior, eso no fue escrito por mi, y definitivamente no estoy creando una excusa porque el dueño se enojó conmigo', 2);
INSERT INTO posts (title, content, user_id) VALUES
('Hola', 'Hola soy nuevo, y definitivamente no soy un bot. Agregame para que hablemos temas de negocios (no son estafas piramidales, lo prometo)', 1);
INSERT INTO posts (title, content, user_id) VALUES
('Busco programador junior', 'Hola comunidad, busco a algun joven talento recien egresado para participar en exitosa start-up que venderá completos chilenos con sabor a frutilla y alcachofa. Requisitos: 10 años de experiencia en vector databases, 25 años de Assembly, y ser capaz de hackar la NASA (En un tiempo maximo de 2 dias). Beneficios: Contrato de prueba por 3 meses con un sueldo de 145.000 CLP. Y si haces un buen trabajo, pasarás a indefinido y tu sueldo aumentara a 151.000 CLP. Si cometes un error te daremos la opción de elegir entre entregarnos tu casa o todos tus fondos de AFP (somos misericordiosos)', 1);
INSERT INTO posts (title, content, user_id) VALUES
('Oferta', '¿Necesitas mejorar tu RENDIMIENTO (en tu computador)? ¿Acaso te piden MÁS y no llegas al final (Del sprint)?. Contactame y te convertiras en el rey del RING (kernel)', NULL);

-- Old way of inserting entries, the method above is prefered so each query can be done individually to get a different created_at value
-- INSERT INTO posts (title, content, user_id) VALUES 
-- ('Si haces esto no eres un true programmer', 'Si prefieres la version grafica de cualquier herramienta, no eres un verdadero programador!!!! #TeamTerminal', 2),
-- ('Me hackearon', 'Quiero pedir perdon por mi post anterior, eso no fue escrito por mi, y definitivamente no estoy creando una excusa porque el dueño se enojó conmigo', 2),
-- ('Hola', 'Hola soy nuevo, y definitivamente no soy un bot. Agregame para que hablemos temas de negocios (no son estafas piramidales, lo prometo)', 1),
-- ('Busco programador junior', 'Hola comunidad, busco a algun joven talento recien egresado para participar en exitosa start-up que venderá completos chilenos con sabor a frutilla y alcachofa. Requisitos: 10 años de experiencia en vector databases, 25 años de Assembly, y ser capaz de hackar la NASA (En un tiempo maximo de 2 dias). Beneficios: Contrato de prueba por 3 meses con un sueldo de 145.000 CLP. Y si haces un buen trabajo, pasarás a indefinido y tu sueldo aumentara a 151.000 CLP. Si cometes un error te daremos la opción de elegir entre entregarnos tu casa o todos tus fondos de AFP (somos misericordiosos)', 1),
-- ('Oferta', '¿Necesitas mejorar tu RENDIMIENTO (en tu computador)? ¿Acaso te piden MÁS y no llegas al final (Del sprint)?. Contactame y te convertiras en el rey del RING (kernel)', NULL);

-- Insert 5 comments into comments table
INSERT INTO comments (content, user_id, post_id)
VALUES ('¡Wow!, que interesante, contactame si quieres dinero rapido y facil', 1, 1);
INSERT INTO comments (content, user_id, post_id)
VALUES ('Si alguien no está de acuerdo puede marcharse o arrodillarse ante mi, pero tendras que hacer penitencia por cometer el pecado de usar interfaces graficas', 2, 1);
INSERT INTO comments (content, user_id, post_id)
VALUES ('Oye, no estoy de acuerdo, y como puedes decir estas cosas de manera tan mal educada siendo administrador? Pesimo servicio', 3, 1);
INSERT INTO comments (content, user_id, post_id)
VALUES ('¡Que no me lo creo chaval!, te sugiero contactarme para mejorar tu situacion economica, es facil y gratis!', 1, 2);
INSERT INTO comments (content, user_id, post_id)
VALUES ('No se preocupen, en esta comunidad yo no discrimino por su preferencia de terminal o interfaz grafica! Pero igual son mejores las terminales #SoyElCapo', 2, 2);

-- Old way of inserting entries, the method above is prefered so each query can be done individually to get a different created_at value
-- INSERT INTO comments (content, user_id, post_id) VALUES 
-- ('¡Wow!, que interesante, contactame si quieres dinero rapido y facil', 1, 1),
-- ('Si alguien no está de acuerdo puede marcharse o arrodillarse ante mi, pero tendras que hacer penitencia por cometer el pecado de usar interfaces graficas', 2, 1),
-- ('Oye, no estoy de acuerdo, y como puedes decir estas cosas de manera tan mal educada siendo administrador? Pesimo servicio', 3, 1),
-- ('¡Que no me lo creo chaval!, te sugiero contactarme para mejorar tu situacion economica, es facil y gratis!', 1, 2),
-- ('No se preocupen, en esta comunidad yo no discrimino por su preferencia de terminal o interfaz grafica! Pero igual son mejores las terminales #SoyElCapo', 2, 2);

-- Exercises:

-- Query 1: Crea y agrega al entregable las consultas para completar el setup de acuerdo a lo pedido
-- Done Above

-- Query 2: Cruza los datos de la tabla usuarios y posts mostrando las siguientes columnas. nombre e email del usuario junto al título y contenido del post.
SELECT users.name AS user_name, users.surname AS user_surname, users.email AS user_email, posts.title AS post_title, posts.content AS post_content FROM users JOIN posts ON users.id = posts.user_id;

-- Query 3: Muestra el id, título y contenido de los posts de los administradores. El administrador puede ser cualquier id y debe ser seleccionado dinámicamente.
SELECT posts.id AS post_id, posts.title AS post_title, posts.content AS post_content FROM posts JOIN users ON posts.user_id = users.id WHERE users.role = 'administrator';

-- Query 4: Cuenta la cantidad de posts de cada usuario. La tabla resultante debe mostrar el id e email del usuario junto con la cantidad de posts de cada usuario. 
SELECT users.id AS user_id, users.email AS user_email, COUNT(posts.user_id) AS num_posts FROM users LEFT JOIN posts ON users.id = posts.user_id GROUP BY users.id ORDER BY user_id ASC;

-- Query 5: Muestra el email del usuario que ha creado más posts. Aquí la tabla resultante tiene un único registro y muestra solo el email.
SELECT users.email AS user_email_most_posts FROM users JOIN posts ON users.id = posts.user_id GROUP BY users.id ORDER BY COUNT(posts.user_id) DESC LIMIT 1;

-- Query 6: Muestra la fecha del último post de cada usuario.
SELECT users.name AS user_name, users.surname AS user_surname, MAX(posts.created_at) AS last_post_date FROM users LEFT JOIN posts ON users.id = posts.user_id GROUP BY users.id ORDER BY users.id ASC;

-- Query 7: Muestra el título y contenido del post (artículo) con más comentarios.
SELECT posts.title AS post_title, posts.content AS post_content FROM posts JOIN comments ON posts.id = comments.post_id GROUP BY posts.id ORDER BY COUNT(comments.post_id) DESC LIMIT 1;

-- Query 8: Muestra en una tabla el título de cada post, el contenido de cada post y el contenido de cada comentario asociado a los posts mostrados, junto con el email del usuario que lo escribió.
SELECT posts.title AS post_title, posts.content AS post_content, comments.content AS comment_content, users.email AS comment_user_email FROM posts LEFT JOIN comments ON posts.id = comments.post_id LEFT JOIN users ON users.id = comments.user_id;

-- Query 9: Muestra el contenido del último comentario de cada usuario.
SELECT DISTINCT ON (u.id) c.content AS most_recent_comment 
FROM users u 
LEFT JOIN 
comments c ON u.id = c.user_id 
LEFT JOIN (
  SELECT user_id, MAX(created_at) AS last_comment_date FROM comments GROUP BY user_id
) c2 ON c.user_id = c2.user_id AND c.created_at = c2.last_comment_date ORDER BY u.id;

-- Query 10: Muestra los emails de los usuarios que no han escrito ningún comentario.
SELECT u.email AS user_email_no_comments 
FROM users u 
LEFT JOIN comments c ON u.id = c.user_id 
GROUP BY u.id 
HAVING COUNT(c.id) = 0;

-- Old version, fun to look at considering the much simpler solution I came up with afterwards
--SELECT u.email as user_email_no_comments FROM users u LEFT JOIN (
--  SELECT u2.id AS user_id, COUNT(c.id) AS num_comments FROM users u2 LEFT JOIN comments c ON u2.id = c.user_id GROUP BY u2.id
--) c2 ON u.id = c2.user_id WHERE c2.num_comments = 0;

-- Exit psql
\q