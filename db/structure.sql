--
-- PostgreSQL database dump
--

-- Dumped from database version 9.6.2
-- Dumped by pg_dump version 9.6.2

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: plpgsql; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS plpgsql WITH SCHEMA pg_catalog;


--
-- Name: EXTENSION plpgsql; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION plpgsql IS 'PL/pgSQL procedural language';


--
-- Name: hstore; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS hstore WITH SCHEMA public;


--
-- Name: EXTENSION hstore; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION hstore IS 'data type for storing sets of (key, value) pairs';


--
-- Name: uuid-ossp; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA public;


--
-- Name: EXTENSION "uuid-ossp"; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION "uuid-ossp" IS 'generate universally unique identifiers (UUIDs)';


SET search_path = public, pg_catalog;

SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: album_translations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE album_translations (
    id integer NOT NULL,
    album_id uuid NOT NULL,
    locale character varying(255) NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    description text
);


--
-- Name: album_translations_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE album_translations_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: album_translations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE album_translations_id_seq OWNED BY album_translations.id;


--
-- Name: albums; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE albums (
    id uuid DEFAULT uuid_generate_v4() NOT NULL,
    name character varying(255),
    slug character varying(255),
    enabled boolean DEFAULT false NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: component_categories; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE component_categories (
    id uuid DEFAULT uuid_generate_v4() NOT NULL,
    rsi_name character varying(255),
    name character varying(255),
    slug character varying(255)
);


--
-- Name: component_category_translations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE component_category_translations (
    id integer NOT NULL,
    component_category_id uuid NOT NULL,
    locale character varying(255) NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    name character varying(255)
);


--
-- Name: component_category_translations_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE component_category_translations_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: component_category_translations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE component_category_translations_id_seq OWNED BY component_category_translations.id;


--
-- Name: component_translations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE component_translations (
    id integer NOT NULL,
    component_id uuid NOT NULL,
    locale character varying(255) NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    name character varying(255),
    component_type character varying(255)
);


--
-- Name: component_translations_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE component_translations_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: component_translations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE component_translations_id_seq OWNED BY component_translations.id;


--
-- Name: components; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE components (
    id uuid DEFAULT uuid_generate_v4() NOT NULL,
    name character varying(255),
    size character varying(255),
    component_type character varying(255),
    enabled boolean DEFAULT false NOT NULL,
    rsi_id integer,
    category_id uuid,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: hardpoint_translations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE hardpoint_translations (
    id integer NOT NULL,
    hardpoint_id uuid NOT NULL,
    locale character varying(255) NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    name character varying(255)
);


--
-- Name: hardpoint_translations_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE hardpoint_translations_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: hardpoint_translations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE hardpoint_translations_id_seq OWNED BY hardpoint_translations.id;


--
-- Name: hardpoints; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE hardpoints (
    id uuid DEFAULT uuid_generate_v4() NOT NULL,
    name character varying(255),
    hardpoint_class character varying(255),
    rating integer,
    max_size integer,
    quantity integer,
    rsi_id integer,
    category_id uuid,
    ship_id uuid,
    component_id uuid,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: images; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE images (
    id uuid DEFAULT uuid_generate_v4() NOT NULL,
    name character varying(255),
    gallery_id uuid,
    gallery_type character varying(255),
    enabled boolean DEFAULT false NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: manufacturer_translations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE manufacturer_translations (
    id integer NOT NULL,
    manufacturer_id uuid NOT NULL,
    locale character varying(255) NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    description text
);


--
-- Name: manufacturer_translations_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE manufacturer_translations_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: manufacturer_translations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE manufacturer_translations_id_seq OWNED BY manufacturer_translations.id;


--
-- Name: manufacturers; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE manufacturers (
    id uuid DEFAULT uuid_generate_v4() NOT NULL,
    name character varying(255),
    slug character varying(255),
    known_for character varying(255),
    description text,
    logo character varying(255),
    enabled boolean DEFAULT false NOT NULL,
    rsi_id integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: schema_migrations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE schema_migrations (
    version character varying(255) NOT NULL
);


--
-- Name: ship_role_translations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE ship_role_translations (
    id integer NOT NULL,
    ship_role_id uuid NOT NULL,
    locale character varying(255) NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    name character varying(255)
);


--
-- Name: ship_role_translations_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE ship_role_translations_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: ship_role_translations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE ship_role_translations_id_seq OWNED BY ship_role_translations.id;


--
-- Name: ship_roles; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE ship_roles (
    id uuid DEFAULT uuid_generate_v4() NOT NULL,
    name character varying(255),
    slug character varying(255),
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: ship_translations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE ship_translations (
    id integer NOT NULL,
    ship_id uuid NOT NULL,
    locale character varying(255) NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    description text
);


--
-- Name: ship_translations_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE ship_translations_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: ship_translations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE ship_translations_id_seq OWNED BY ship_translations.id;


--
-- Name: ships; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE ships (
    id uuid DEFAULT uuid_generate_v4() NOT NULL,
    name character varying(255),
    slug character varying(255),
    description text,
    length character varying(255),
    beam character varying(255),
    height character varying(255),
    mass character varying(255),
    cargo character varying(255),
    crew character varying(255),
    store_image character varying(255),
    store_url character varying(255),
    powerplant_size integer,
    shield_size integer,
    classification character varying(255),
    enabled boolean DEFAULT false NOT NULL,
    rsi_id integer,
    manufacturer_id uuid,
    ship_role_id uuid,
    propulsion_raw text,
    ordnance_raw text,
    modular_raw text,
    avionics_raw text,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    production_status character varying(255),
    production_note character varying(255),
    focus character varying(255),
    on_sale boolean DEFAULT false,
    price numeric(10,2) DEFAULT 0.0 NOT NULL
);


--
-- Name: user_ships; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE user_ships (
    id uuid DEFAULT uuid_generate_v4() NOT NULL,
    user_id uuid,
    ship_id uuid,
    name character varying(255),
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    purchased boolean DEFAULT false
);


--
-- Name: users; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE users (
    id uuid DEFAULT uuid_generate_v4() NOT NULL,
    admin boolean DEFAULT false NOT NULL,
    profile hstore,
    settings hstore,
    gravatar_hash character varying(255),
    gravatar character varying(255),
    locale character varying(255),
    username character varying(255) DEFAULT ''::character varying NOT NULL,
    email character varying(255) DEFAULT ''::character varying NOT NULL,
    encrypted_password character varying(255) DEFAULT ''::character varying NOT NULL,
    reset_password_token character varying(255),
    reset_password_sent_at timestamp without time zone,
    remember_created_at timestamp without time zone,
    sign_in_count integer DEFAULT 0 NOT NULL,
    current_sign_in_at timestamp without time zone,
    last_sign_in_at timestamp without time zone,
    current_sign_in_ip character varying(255),
    last_sign_in_ip character varying(255),
    confirmation_token character varying(255),
    confirmed_at timestamp without time zone,
    confirmation_sent_at timestamp without time zone,
    unconfirmed_email character varying(255),
    failed_attempts integer DEFAULT 0 NOT NULL,
    unlock_token character varying(255),
    locked_at timestamp without time zone,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    provider character varying(255),
    uid character varying(255),
    rsi_organization_url character varying(255),
    rsi_organization_handle character varying(255),
    rsi_organization_name character varying(255),
    rsi_profile_url character varying(255),
    rsi_handle character varying(255)
);


--
-- Name: worker_states; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE worker_states (
    id uuid DEFAULT uuid_generate_v4() NOT NULL,
    name character varying(255),
    running boolean DEFAULT false,
    last_run_start timestamp without time zone,
    last_run_end timestamp without time zone,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: album_translations id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY album_translations ALTER COLUMN id SET DEFAULT nextval('album_translations_id_seq'::regclass);


--
-- Name: component_category_translations id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY component_category_translations ALTER COLUMN id SET DEFAULT nextval('component_category_translations_id_seq'::regclass);


--
-- Name: component_translations id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY component_translations ALTER COLUMN id SET DEFAULT nextval('component_translations_id_seq'::regclass);


--
-- Name: hardpoint_translations id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY hardpoint_translations ALTER COLUMN id SET DEFAULT nextval('hardpoint_translations_id_seq'::regclass);


--
-- Name: manufacturer_translations id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY manufacturer_translations ALTER COLUMN id SET DEFAULT nextval('manufacturer_translations_id_seq'::regclass);


--
-- Name: ship_role_translations id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY ship_role_translations ALTER COLUMN id SET DEFAULT nextval('ship_role_translations_id_seq'::regclass);


--
-- Name: ship_translations id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY ship_translations ALTER COLUMN id SET DEFAULT nextval('ship_translations_id_seq'::regclass);


--
-- Name: album_translations album_translations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY album_translations
    ADD CONSTRAINT album_translations_pkey PRIMARY KEY (id);


--
-- Name: albums albums_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY albums
    ADD CONSTRAINT albums_pkey PRIMARY KEY (id);


--
-- Name: component_categories component_categories_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY component_categories
    ADD CONSTRAINT component_categories_pkey PRIMARY KEY (id);


--
-- Name: component_category_translations component_category_translations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY component_category_translations
    ADD CONSTRAINT component_category_translations_pkey PRIMARY KEY (id);


--
-- Name: component_translations component_translations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY component_translations
    ADD CONSTRAINT component_translations_pkey PRIMARY KEY (id);


--
-- Name: components components_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY components
    ADD CONSTRAINT components_pkey PRIMARY KEY (id);


--
-- Name: hardpoint_translations hardpoint_translations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY hardpoint_translations
    ADD CONSTRAINT hardpoint_translations_pkey PRIMARY KEY (id);


--
-- Name: hardpoints hardpoints_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY hardpoints
    ADD CONSTRAINT hardpoints_pkey PRIMARY KEY (id);


--
-- Name: images images_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY images
    ADD CONSTRAINT images_pkey PRIMARY KEY (id);


--
-- Name: manufacturer_translations manufacturer_translations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY manufacturer_translations
    ADD CONSTRAINT manufacturer_translations_pkey PRIMARY KEY (id);


--
-- Name: manufacturers manufacturers_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY manufacturers
    ADD CONSTRAINT manufacturers_pkey PRIMARY KEY (id);


--
-- Name: ship_role_translations ship_role_translations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY ship_role_translations
    ADD CONSTRAINT ship_role_translations_pkey PRIMARY KEY (id);


--
-- Name: ship_roles ship_roles_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY ship_roles
    ADD CONSTRAINT ship_roles_pkey PRIMARY KEY (id);


--
-- Name: ship_translations ship_translations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY ship_translations
    ADD CONSTRAINT ship_translations_pkey PRIMARY KEY (id);


--
-- Name: ships ships_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY ships
    ADD CONSTRAINT ships_pkey PRIMARY KEY (id);


--
-- Name: user_ships user_ships_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY user_ships
    ADD CONSTRAINT user_ships_pkey PRIMARY KEY (id);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: worker_states worker_states_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY worker_states
    ADD CONSTRAINT worker_states_pkey PRIMARY KEY (id);


--
-- Name: index_album_translations_on_album_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_album_translations_on_album_id ON album_translations USING btree (album_id);


--
-- Name: index_album_translations_on_locale; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_album_translations_on_locale ON album_translations USING btree (locale);


--
-- Name: index_component_category_translations_on_component_category_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_component_category_translations_on_component_category_id ON component_category_translations USING btree (component_category_id);


--
-- Name: index_component_category_translations_on_locale; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_component_category_translations_on_locale ON component_category_translations USING btree (locale);


--
-- Name: index_component_translations_on_component_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_component_translations_on_component_id ON component_translations USING btree (component_id);


--
-- Name: index_component_translations_on_locale; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_component_translations_on_locale ON component_translations USING btree (locale);


--
-- Name: index_hardpoint_translations_on_hardpoint_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_hardpoint_translations_on_hardpoint_id ON hardpoint_translations USING btree (hardpoint_id);


--
-- Name: index_hardpoint_translations_on_locale; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_hardpoint_translations_on_locale ON hardpoint_translations USING btree (locale);


--
-- Name: index_manufacturer_translations_on_locale; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_manufacturer_translations_on_locale ON manufacturer_translations USING btree (locale);


--
-- Name: index_manufacturer_translations_on_manufacturer_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_manufacturer_translations_on_manufacturer_id ON manufacturer_translations USING btree (manufacturer_id);


--
-- Name: index_ship_role_translations_on_locale; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_ship_role_translations_on_locale ON ship_role_translations USING btree (locale);


--
-- Name: index_ship_role_translations_on_ship_role_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_ship_role_translations_on_ship_role_id ON ship_role_translations USING btree (ship_role_id);


--
-- Name: index_ship_translations_on_locale; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_ship_translations_on_locale ON ship_translations USING btree (locale);


--
-- Name: index_ship_translations_on_ship_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_ship_translations_on_ship_id ON ship_translations USING btree (ship_id);


--
-- Name: index_users_on_confirmation_token; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_users_on_confirmation_token ON users USING btree (confirmation_token);


--
-- Name: index_users_on_email; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_users_on_email ON users USING btree (email);


--
-- Name: index_users_on_reset_password_token; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_users_on_reset_password_token ON users USING btree (reset_password_token);


--
-- Name: index_users_on_unlock_token; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_users_on_unlock_token ON users USING btree (unlock_token);


--
-- Name: index_users_on_username; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_users_on_username ON users USING btree (username);


--
-- Name: unique_schema_migrations; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX unique_schema_migrations ON schema_migrations USING btree (version);


--
-- PostgreSQL database dump complete
--

SET search_path TO "$user", public;

INSERT INTO schema_migrations (version) VALUES ('20140115071342');

INSERT INTO schema_migrations (version) VALUES ('20140119154504');

INSERT INTO schema_migrations (version) VALUES ('20161227143357');

INSERT INTO schema_migrations (version) VALUES ('20161227144520');

INSERT INTO schema_migrations (version) VALUES ('20161228003318');

INSERT INTO schema_migrations (version) VALUES ('20161230131913');

INSERT INTO schema_migrations (version) VALUES ('20170107211857');

INSERT INTO schema_migrations (version) VALUES ('20170108185635');

INSERT INTO schema_migrations (version) VALUES ('20170109220904');

INSERT INTO schema_migrations (version) VALUES ('20170110004456');

INSERT INTO schema_migrations (version) VALUES ('20170110230458');

