CREATE TABLE notes (
  id INTEGER UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
	category VARCHAR (20),
	name VARCHAR (100),
	email VARCHAR(60),
	text VARCHAR(3000),
	ip_address VARCHAR(16),
	created_at TIMESTAMP,
	updated_at TIMESTAMP,
	INDEX ind_cat_name (category, name)
);

CREATE TABLE users (
  id int(11) NOT NULL auto_increment,
  login varchar(80) default NULL,
  password varchar(40) default NULL,
  PRIMARY KEY  (id)
);

CREATE TABLE bans (
  id int(11) NOT NULL auto_increment,
  ip_filter varchar(16) default NULL,
  PRIMARY KEY  (id)
);

INSERT INTO users VALUES(1,'admin','128c6b1057ef8ccae50308b4ec4955df699c36d3');

-- This table represents files, classes and modules
CREATE TABLE ra_containers
(
     id INTEGER NOT NULL AUTO_INCREMENT PRIMARY KEY,
     type CHAR(15), -- used to specify the type of container (file, class or module)
     parent_id INTEGER, -- parent container id
     name VARCHAR(255), -- name of the class/module/file (relative name for file)
     full_name VARCHAR(255), -- full name of the class/module/file (absolute name for file)
     superclass VARCHAR(255), -- used for classes and modules
     ra_comment_id INTEGER
);

CREATE TABLE ra_in_files
(
     id INTEGER NOT NULL AUTO_INCREMENT PRIMARY KEY,
     file_name VARCHAR(255),
     container_id INTEGER
);

CREATE TABLE ra_methods
(
     id INTEGER NOT NULL AUTO_INCREMENT PRIMARY KEY,
     ra_container_id INTEGER,
     name VARCHAR(128),
     parent_name VARCHAR(255),
     parameters VARCHAR(255),
     block_parameters VARCHAR(255),
     singleton TINYINT(1),
     visibility CHAR(1),
     force_documentation TINYINT(1),
     ra_comment_id INTEGER,
     ra_source_code_id INTEGER
 );
 
-- This table contains the source code for each method
CREATE TABLE ra_source_codes
(
     id INTEGER NOT NULL AUTO_INCREMENT PRIMARY KEY,
     source_code TEXT 
);

-- This table represents attributes, constants, includes, reuqires and aliases
 CREATE TABLE ra_code_objects
 (
     id INTEGER NOT NULL AUTO_INCREMENT PRIMARY KEY,
     ra_container_id INTEGER,
     type CHAR(15), -- attr,const,include,require,alias
     name VARCHAR(128), -- also old_name for alias
     parent_name VARCHAR(255),
     value VARCHAR(128),  -- used for constants (also new_name for alias)
     visibility CHAR(1), -- used for attributes     
     read_write CHAR(2), -- used for attributes
     comment TEXT
 );

-- Holds the text of comments
CREATE TABLE ra_comments
(
	id INTEGER NOT NULL AUTO_INCREMENT PRIMARY KEY,
	comment TEXT
);