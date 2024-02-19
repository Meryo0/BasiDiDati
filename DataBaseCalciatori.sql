PGDMP  '                    |         
   Calciatori    16.1    16.1 m    X           0    0    ENCODING    ENCODING        SET client_encoding = 'UTF8';
                      false            Y           0    0 
   STDSTRINGS 
   STDSTRINGS     (   SET standard_conforming_strings = 'on';
                      false            Z           0    0 
   SEARCHPATH 
   SEARCHPATH     8   SELECT pg_catalog.set_config('search_path', '', false);
                      false            [           1262    16679 
   Calciatori    DATABASE        CREATE DATABASE "Calciatori" WITH TEMPLATE = template0 ENCODING = 'UTF8' LOCALE_PROVIDER = libc LOCALE = 'Italian_Italy.1252';
    DROP DATABASE "Calciatori";
                postgres    false            r           1247    16713    genere    TYPE     G   CREATE TYPE public.genere AS ENUM (
    'Femminile',
    'Maschile'
);
    DROP TYPE public.genere;
       public          postgres    false            i           1247    16686    piede    TYPE     U   CREATE TYPE public.piede AS ENUM (
    'Sinistro',
    'Destro',
    'Ambidestro'
);
    DROP TYPE public.piede;
       public          postgres    false            u           1247    16718 	   posizione    TYPE     r   CREATE TYPE public.posizione AS ENUM (
    'portiere',
    'difensore',
    'centrocampista',
    'attaccante'
);
    DROP TYPE public.posizione;
       public          postgres    false            l           1247    16694    sesso    TYPE     C   CREATE TYPE public.sesso AS ENUM (
    'Femmina',
    'Maschio'
);
    DROP TYPE public.sesso;
       public          postgres    false            �           1247    16905    tipo_squadra    TYPE     I   CREATE TYPE public.tipo_squadra AS ENUM (
    'Club',
    'Nazionale'
);
    DROP TYPE public.tipo_squadra;
       public          postgres    false            x           1247    16728    tipo_trofeo    TYPE     M   CREATE TYPE public.tipo_trofeo AS ENUM (
    'individuale',
    'squadra'
);
    DROP TYPE public.tipo_trofeo;
       public          postgres    false            �            1255    16885    dataminwinf()    FUNCTION     	  CREATE FUNCTION public.dataminwinf() RETURNS trigger
    LANGUAGE plpgsql
    AS $$ 
begin  
	if (new.data_vittoria >= (select MIN(data_inizio) from calciatore c join militanza_calciatore mc on c.codicec = mc.codicec where c.codicec = new.codicec)) then 
		return new; 
	elsif (new.data_vittoria >= (select MIN(data_inizio) from calciatore c join militanza_portiere mc on c.codicec = mc.codicec where c.codicec = new.codicec)) then 
		return new;
	end if; 
raise notice 'data_vittoria non valida';
return null;
end; 
$$;
 $   DROP FUNCTION public.dataminwinf();
       public          postgres    false            �            1255    16875    datanminf()    FUNCTION     �  CREATE FUNCTION public.datanminf() RETURNS trigger
    LANGUAGE plpgsql
    AS $$declare 
mindi date;
begin 
select min(data_inizio) into mindi from (select min(data_inizio) as data_inizio from militanza_calciatore  where codicec = new.codicec union select min(data_inizio) as data_inizio from militanza_portiere  where codicec = new.codicec);
if mindi is null then
	return new;
end if;
if(new.datan < mindi) then 
	return new;
end if;
raise notice 'data di nascita non valida';
return null;
end; 
$$;
 "   DROP FUNCTION public.datanminf();
       public          postgres    false            �            1255    16871    dataritmaxf()    FUNCTION     3  CREATE FUNCTION public.dataritmaxf() RETURNS trigger
    LANGUAGE plpgsql
    AS $$declare
dfmaxc date;
dfmaxp date;
begin 
	select MAX(data_fine) into dfmaxc from militanza_calciatore m where m.codicec = new.codicec;
	select MAX(data_fine) into dfmaxp from militanza_portiere m where m.codicec = new.codicec;
	if dfmaxc >= dfmaxp then
		if (new.data_ritiro >= dfmaxc) then
			return new;
		end if;
	else 
		if (new.data_ritiro >= dfmaxp)then
			return new;
		end if;
	end if;
	raise notice 'non è possibile inserire questa data ritiro';
	return null;
end; 
$$;
 $   DROP FUNCTION public.dataritmaxf();
       public          postgres    false                        1255    16926    inserimento_calciatore()    FUNCTION     �  CREATE FUNCTION public.inserimento_calciatore() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
declare
curs1 refcursor;
df date;
di date;
maxdf date;
maxdi date;
begin
	/*controlliamo per prima cosa se il calciatore ha giocato anche da portiere nella stessa squadra*/
	if (new.codicec = (select codicec from  militanza_portiere where codicec = new.codicec and codices = new.codices limit 1)) then 
		open curs1 for select data_inizio,data_fine from  militanza_portiere where codicec = new.codicec and codices = new.codices;
		loop
		fetch curs1 into di,df;
		if (new.data_inizio = di and new.data_fine = df ) then 
			return new;  
		end if;
		EXIT when not found;
		end loop;
		close curs1;
		open curs1 for select data_inizio,data_fine from  militanza_portiere where codicec = new.codicec union select data_inizio,data_fine from  militanza_calciatore where codicec = new.codicec;
		loop
		fetch curs1 into di,df;
		if ((new.data_inizio <= df and new.data_inizio >= di) or (new.data_fine <= df and new.data_fine >= di) or (new.data_inizio <= di and new.data_fine >= df) ) then 
			raise notice 'hai inserito una militanza durante il periodo di un altra militanza';
			return null;  
		end if;
		EXIT when not found;
		end loop;
		close curs1;
		if maxdf is null and new.data_inizio > maxdi then 
			update militanza_calciatore set data_fine = new.data_inizio where data_fine is null and codicec = new.codicec;
		end if;
		return new;
	end if;
	select Max(data_fine),Max(data_inizio) into maxdf,maxdi  from (select data_fine,data_inizio from  militanza_portiere where codicec = new.codicec union select data_inizio,data_fine from  militanza_calciatore where codicec = new.codicec);
	/* inserimento per la prima volta del calciatore*/
	if maxdi is null then 
		return new;
	end if;
	/* inserimento per la seconda o successiva volta del calciatore*/
	open curs1 for select data_inizio,data_fine from  militanza_portiere where codicec = new.codicec union select data_inizio,data_fine from  militanza_calciatore where codicec = new.codicec;
	loop
	EXIT when not found;
	fetch curs1 into di,df;
	if ((new.data_inizio <= df and new.data_inizio >= di) or (new.data_fine <= df and new.data_fine >= di) or (new.data_inizio <= di and new.data_fine >= df) ) then 
		raise notice 'hai inserito una militanza durante il periodo di un altra militanza';
		return null;  
	end if;
	end loop;
	close curs1;
	select data_fine into df from militanza_calciatore where codicec = new.codicec and data_inizio = maxdi;
	if df is null and new.data_inizio > maxdi then 
		update militanza_calciatore set data_fine = new.data_inizio where data_fine is null and codicec = new.codicec;
	end if;
	select data_fine into df from militanza_portiere where codicec = new.codicec and data_inizio = maxdi;
	if df is null and new.data_inizio > maxdi then 
		update militanza_portiere set data_fine = new.data_inizio where data_fine is null and codicec = new.codicec;
	end if;
	return new;
		
end;
$$;
 /   DROP FUNCTION public.inserimento_calciatore();
       public          postgres    false            �            1255    16865    inserimento_calciatori_genere()    FUNCTION     p  CREATE FUNCTION public.inserimento_calciatori_genere() RETURNS trigger
    LANGUAGE plpgsql
    AS $$  
declare 
persona_sesso varchar(15); 
squadra_genere varchar(15); 
begin  
	select sesso into persona_sesso from calciatore where codicec = new.codicec; 
	select genere into squadra_genere from squadra  where codices = new.codices; 
	if (persona_sesso = 'Maschio' and squadra_genere = 'Maschile') OR (persona_sesso = 'Femmina' and squadra_genere = 'Femminile') then  
		return new;
	else 
		raise notice 'non puoi inserire un giocatore % in una squadra %',persona_sesso,squadra_genere;
		return null;
	end if; 
end; 
$$;
 6   DROP FUNCTION public.inserimento_calciatori_genere();
       public          postgres    false            �            1255    16925    inserimento_portiere()    FUNCTION     �  CREATE FUNCTION public.inserimento_portiere() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
declare
curs1 refcursor;
df date;
di date;
maxdf date;
maxdi date;
begin
	/*controlliamo per prima cosa se il portiere ha giocato anche da calciatore nella stessa squadra*/
	if (new.codicec = (select codicec from  militanza_calciatore where codicec = new.codicec and codices = new.codices limit 1)) then 
		open curs1 for select data_inizio,data_fine from  militanza_calciatore where codicec = new.codicec and codices = new.codices;
		loop
		fetch curs1 into di,df;
		if (new.data_inizio = di and new.data_fine = df ) then 
			return new;  
		end if;
		EXIT when not found;
		end loop;
		close curs1;
		open curs1 for select data_inizio,data_fine from  militanza_portiere where codicec = new.codicec union select data_inizio,data_fine from  militanza_calciatore where codicec = new.codicec;
		loop
		fetch curs1 into di,df;
		if ((new.data_inizio <= df and new.data_inizio >=di) or (new.data_fine <= df and new.data_fine >=di) or (new.data_inizio <= di and new.data_fine >=	 df)) then 
			raise notice 'hai inserito una militanza durante il periodo di un altra militanza';
			return null;  
		end if;
		EXIT when not found;
		end loop;
		close curs1;
		if maxdf is null and new.data_inizio > maxdi then 
			update militanza_portiere set data_fine = new.data_inizio where data_fine is null and codicec = new.codicec;
		end if;
		return new;
	end if;
	select Max(data_fine),Max(data_inizio) into maxdf,maxdi  from (select data_fine,data_inizio from  militanza_portiere where codicec = new.codicec union select data_inizio,data_fine from  militanza_calciatore where codicec = new.codicec);
	/* inserimento per la prima volta del portiere*/
	if maxdi is null  then 
		return new;
	end if;
	/* inserimento per la seconda o successiva volta del portiere*/
	open curs1 for select data_inizio,data_fine from  militanza_portiere where codicec = new.codicec union select data_inizio,data_fine from  militanza_calciatore where codicec = new.codicec;
	loop
	EXIT when not found;
	fetch curs1 into di,df;
	if ((new.data_inizio <= df and new.data_inizio >=di) or (new.data_fine <= df and new.data_fine >=di) or (new.data_inizio <= di and new.data_fine >= df) ) then 
		raise notice 'hai inserito una militanza durante il periodo di un altra militanza';
		return null;  
	end if;
	end loop;
	close curs1;
	select data_fine into df from militanza_calciatore where codicec = new.codicec and data_inizio = maxdi;
	if df is null and new.data_inizio > maxdi then 
		update militanza_calciatore set data_fine = new.data_inizio where data_fine is null and codicec = new.codicec;
	end if;
	select data_fine into df from militanza_portiere where codicec = new.codicec and data_inizio = maxdi;
	if df is null and new.data_inizio > maxdi then 
		update militanza_portiere set data_fine = new.data_inizio where data_fine is null and codicec = new.codicec;
	end if;
	return new;	
end;
$$;
 -   DROP FUNCTION public.inserimento_portiere();
       public          postgres    false            �            1255    16867    inserimento_portieri_genere()    FUNCTION     n  CREATE FUNCTION public.inserimento_portieri_genere() RETURNS trigger
    LANGUAGE plpgsql
    AS $$  
declare 
persona_sesso varchar(15); 
squadra_genere varchar(15); 
begin  
	select sesso into persona_sesso from calciatore where codicec = new.codicec; 
	select genere into squadra_genere from squadra  where codices = new.codices; 
	if (persona_sesso = 'Maschio' and squadra_genere = 'Maschile') OR (persona_sesso = 'Femmina' and squadra_genere = 'Femminile') then  
		return new;
	else 
		raise notice 'non puoi inserire un giocatore % in una squadra %',persona_sesso,squadra_genere;
		return null;
	end if; 
end; 
$$;
 4   DROP FUNCTION public.inserimento_portieri_genere();
       public          postgres    false            �            1255    16869    inserimento_stagione_squadra()    FUNCTION       CREATE FUNCTION public.inserimento_stagione_squadra() RETURNS trigger
    LANGUAGE plpgsql
    AS $$  
declare 
curs1 refcursor;
competizione_genere varchar(15); 
squadra_genere varchar(15); 
nazionalità_squadra varchar (15);
nazionalità_competizione varchar (15);
tipocomp varchar(15);
tiposquad varchar(15);
begin  
select genere into competizione_genere from competizione  where nomec = new.nomec; 
select genere into squadra_genere from squadra where codices = new.codices; 
select nazionalità into nazionalità_squadra from squadra where codices = new.codices; 
select tipo_squadra into tiposquad from squadra where codices = new.codices;
select tipo_competizione into tipocomp from competizione where nomec = new.nomec;
	if competizione_genere = squadra_genere then  
		if tipocomp = tiposquad then
			open curs1 for select nomen from competizione c join accetta a  on c.nomec = a.nomec  where c.nomec = new.nomec ;
			LOOP
			fetch curs1 into nazionalità_competizione;
			if(nazionalità_squadra = nazionalità_competizione or nazionalità_competizione is null ) then
				return new;
			end if; 
			EXIT when not found;
			end loop;
			close curs1;
		end if;
	end if;
	raise notice 'inserimento errato la squadra non può partecipare a questa competizione';
	return null;
end; 
$$;
 5   DROP FUNCTION public.inserimento_stagione_squadra();
       public          postgres    false            �            1255    16877 
   onlyporf()    FUNCTION     &  CREATE FUNCTION public.onlyporf() RETURNS trigger
    LANGUAGE plpgsql
    AS $$ 
begin  
	if('portiere' in (select ruolo from ricopre r where r.codicec = new.codicec )) then
		return new; 
	end if; 
raise notice 'il giocatore inserito non ha mai giocato come portiere';
return null;
end; 
$$;
 !   DROP FUNCTION public.onlyporf();
       public          postgres    false            �            1255    16947    trofeigeneref()    FUNCTION     �  CREATE FUNCTION public.trofeigeneref() RETURNS trigger
    LANGUAGE plpgsql
    AS $$  
declare 

begin  
	if('Femmina'= (select sesso from calciatore where codicec=new.codicec ) and 'Femminile' = (select genere from trofeo where nomet=new.nomet )) then
		return new;
	end if;
	if('Maschio'= (select sesso from calciatore where codicec=new.codicec ) and 'Maschile' = (select genere from trofeo where nomet=new.nomet )) then
		return new;
	end if;
	return null;
end; 
$$;
 &   DROP FUNCTION public.trofeigeneref();
       public          postgres    false            �            1255    33086    trofeisquadraf()    FUNCTION     �  CREATE FUNCTION public.trofeisquadraf() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
declare 
curs refcursor;
datai date;
dataf date;
begin
if ('squadra' = (select tipo from trofeo where nomet = new.nomet)) then
	open curs for SELECT inizio_partecipazione, fine_partecipazione FROM stagione_squadra WHERE codices = NEW.codices AND nomec = (select nomec from assegna where nomet = new.nomet);
	loop
		fetch curs into datai,dataf;
		if dataf is null then
			if new.data_vittoria >= datai then
				CLOSE curs;
				return new;
			end if;
		else	
			if new.data_vittoria >= datai AND new.data_vittoria <= dataf then
				CLOSE curs;
				return new;
			end if;
		end if;
	EXIT WHEN NOT FOUND;
	end loop;
	close curs;
	return null;
end if;
end;
$$;
 '   DROP FUNCTION public.trofeisquadraf();
       public          postgres    false            �            1255    33090    trofeogiocatoref()    FUNCTION     �   CREATE FUNCTION public.trofeogiocatoref() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
begin
if ('individuale' = (select tipo from trofeo where nomet = new.nomet)) then
	return new;
end if;
return null;
end;
$$;
 )   DROP FUNCTION public.trofeogiocatoref();
       public          postgres    false            �            1255    16873    updataritmaxf()    FUNCTION     S  CREATE FUNCTION public.updataritmaxf() RETURNS trigger
    LANGUAGE plpgsql
    AS $$declare
dfmaxc date;
dfmaxp date;
begin 
	select MAX(data_fine) into dfmaxc from militanza_calciatore m where m.codicec = new.codicec;
	select MAX(data_fine) into dfmaxp from militanza_calciatore m where m.codicec = new.codicec;
	if dfmaxc >= dfmaxp then
		if (new.data_ritiro >= dfmaxc) then
			return new;
		end if;
	end if;
	if dfmaxp >= dfmaxc then
		if (new.data_ritiro >= dfmaxp)then
			return new;
		end if;
	end if;
	raise notice 'non è possibile inserire questa data ritiro';
	return null;
end; 
$$;
 &   DROP FUNCTION public.updataritmaxf();
       public          postgres    false            �            1259    16891    accetta    TABLE     b   CREATE TABLE public.accetta (
    nomec character varying(50),
    nomen character varying(25)
);
    DROP TABLE public.accetta;
       public         heap    postgres    false            �            1259    16848    assegna    TABLE     t   CREATE TABLE public.assegna (
    nomet character varying(50) NOT NULL,
    nomec character varying(50) NOT NULL
);
    DROP TABLE public.assegna;
       public         heap    postgres    false            �            1259    16700 
   calciatore    TABLE     :  CREATE TABLE public.calciatore (
    codicec integer NOT NULL,
    nome character varying(20) NOT NULL,
    cognome character varying(25) NOT NULL,
    piede public.piede NOT NULL,
    datan date NOT NULL,
    sesso public.sesso NOT NULL,
    data_ritiro date,
    "nazionalità" character varying(25) NOT NULL
);
    DROP TABLE public.calciatore;
       public         heap    postgres    false    873    876            �            1259    16699    calciatore_codicec_seq    SEQUENCE     �   CREATE SEQUENCE public.calciatore_codicec_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 -   DROP SEQUENCE public.calciatore_codicec_seq;
       public          postgres    false    217            \           0    0    calciatore_codicec_seq    SEQUENCE OWNED BY     Q   ALTER SEQUENCE public.calciatore_codicec_seq OWNED BY public.calciatore.codicec;
          public          postgres    false    216            �            1259    16760    competizione    TABLE     �   CREATE TABLE public.competizione (
    nomec character varying(50) NOT NULL,
    genere public.genere NOT NULL,
    tipo_competizione public.tipo_squadra
);
     DROP TABLE public.competizione;
       public         heap    postgres    false    930    882            �            1259    16745    feature    TABLE     r   CREATE TABLE public.feature (
    nomef character varying(20) NOT NULL,
    descrizione character varying(200)
);
    DROP TABLE public.feature;
       public         heap    postgres    false            �            1259    16809    militanza_calciatore    TABLE       CREATE TABLE public.militanza_calciatore (
    data_inizio date NOT NULL,
    data_fine date,
    goal_fatti integer NOT NULL,
    partite_giocate integer NOT NULL,
    codicec integer NOT NULL,
    codices integer NOT NULL,
    CONSTRAINT didf CHECK ((data_fine > data_inizio))
);
 (   DROP TABLE public.militanza_calciatore;
       public         heap    postgres    false            �            1259    16770    militanza_portiere    TABLE     :  CREATE TABLE public.militanza_portiere (
    data_inizio date NOT NULL,
    data_fine date,
    goal_fatti integer NOT NULL,
    partite_giocate integer NOT NULL,
    goal_subiti integer NOT NULL,
    codicec integer NOT NULL,
    codices integer NOT NULL,
    CONSTRAINT didf CHECK ((data_fine > data_inizio))
);
 &   DROP TABLE public.militanza_portiere;
       public         heap    postgres    false            �            1259    16680    nazione    TABLE     p   CREATE TABLE public.nazione (
    nomen character varying(25) NOT NULL,
    continente character varying(25)
);
    DROP TABLE public.nazione;
       public         heap    postgres    false            �            1259    16835 	   possiedef    TABLE     j   CREATE TABLE public.possiedef (
    codicec integer NOT NULL,
    nomef character varying(25) NOT NULL
);
    DROP TABLE public.possiedef;
       public         heap    postgres    false            �            1259    16822    ricopre    TABLE     c   CREATE TABLE public.ricopre (
    codicec integer NOT NULL,
    ruolo public.posizione NOT NULL
);
    DROP TABLE public.ricopre;
       public         heap    postgres    false    885            �            1259    16750    ruolo    TABLE     G   CREATE TABLE public.ruolo (
    posizione public.posizione NOT NULL
);
    DROP TABLE public.ruolo;
       public         heap    postgres    false    885            �            1259    16734    squadra    TABLE     �   CREATE TABLE public.squadra (
    codices integer NOT NULL,
    nomes character varying(20) NOT NULL,
    genere public.genere,
    tipo_squadra public.tipo_squadra,
    "nazionalità" character varying(25) NOT NULL
);
    DROP TABLE public.squadra;
       public         heap    postgres    false    930    882            �            1259    16733    squadra_codices_seq    SEQUENCE     �   CREATE SEQUENCE public.squadra_codices_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 *   DROP SEQUENCE public.squadra_codices_seq;
       public          postgres    false    219            ]           0    0    squadra_codices_seq    SEQUENCE OWNED BY     K   ALTER SEQUENCE public.squadra_codices_seq OWNED BY public.squadra.codices;
          public          postgres    false    218            �            1259    16796    stagione_squadra    TABLE     �   CREATE TABLE public.stagione_squadra (
    nomec character varying(25) NOT NULL,
    codices integer NOT NULL,
    inizio_partecipazione date NOT NULL,
    fine_partecipazione date
);
 $   DROP TABLE public.stagione_squadra;
       public         heap    postgres    false            �            1259    16755    trofeo    TABLE     �   CREATE TABLE public.trofeo (
    nomet character varying(50) NOT NULL,
    descrizione character varying(200),
    tipo public.tipo_trofeo NOT NULL,
    genere public.genere NOT NULL
);
    DROP TABLE public.trofeo;
       public         heap    postgres    false    888    882            �            1259    16783    vince_giocatore    TABLE     �   CREATE TABLE public.vince_giocatore (
    data_vittoria date,
    codicec integer NOT NULL,
    nomet character varying(40) NOT NULL
);
 #   DROP TABLE public.vince_giocatore;
       public         heap    postgres    false            �            1259    33043    vince_squadra    TABLE     �   CREATE TABLE public.vince_squadra (
    data_vittoria date NOT NULL,
    codices integer NOT NULL,
    nomet character varying(50) NOT NULL
);
 !   DROP TABLE public.vince_squadra;
       public         heap    postgres    false            v           2604    16703    calciatore codicec    DEFAULT     x   ALTER TABLE ONLY public.calciatore ALTER COLUMN codicec SET DEFAULT nextval('public.calciatore_codicec_seq'::regclass);
 A   ALTER TABLE public.calciatore ALTER COLUMN codicec DROP DEFAULT;
       public          postgres    false    216    217    217            w           2604    16737    squadra codices    DEFAULT     r   ALTER TABLE ONLY public.squadra ALTER COLUMN codices SET DEFAULT nextval('public.squadra_codices_seq'::regclass);
 >   ALTER TABLE public.squadra ALTER COLUMN codices DROP DEFAULT;
       public          postgres    false    218    219    219            T          0    16891    accetta 
   TABLE DATA           /   COPY public.accetta (nomec, nomen) FROM stdin;
    public          postgres    false    231   ��       S          0    16848    assegna 
   TABLE DATA           /   COPY public.assegna (nomet, nomec) FROM stdin;
    public          postgres    false    230   G�       F          0    16700 
   calciatore 
   TABLE DATA           n   COPY public.calciatore (codicec, nome, cognome, piede, datan, sesso, data_ritiro, "nazionalità") FROM stdin;
    public          postgres    false    217   6�       L          0    16760    competizione 
   TABLE DATA           H   COPY public.competizione (nomec, genere, tipo_competizione) FROM stdin;
    public          postgres    false    223   ~�       I          0    16745    feature 
   TABLE DATA           5   COPY public.feature (nomef, descrizione) FROM stdin;
    public          postgres    false    220   -�       P          0    16809    militanza_calciatore 
   TABLE DATA           u   COPY public.militanza_calciatore (data_inizio, data_fine, goal_fatti, partite_giocate, codicec, codices) FROM stdin;
    public          postgres    false    227   �       M          0    16770    militanza_portiere 
   TABLE DATA           �   COPY public.militanza_portiere (data_inizio, data_fine, goal_fatti, partite_giocate, goal_subiti, codicec, codices) FROM stdin;
    public          postgres    false    224   -�       D          0    16680    nazione 
   TABLE DATA           4   COPY public.nazione (nomen, continente) FROM stdin;
    public          postgres    false    215   ��       R          0    16835 	   possiedef 
   TABLE DATA           3   COPY public.possiedef (codicec, nomef) FROM stdin;
    public          postgres    false    229   *�       Q          0    16822    ricopre 
   TABLE DATA           1   COPY public.ricopre (codicec, ruolo) FROM stdin;
    public          postgres    false    228   ҽ       J          0    16750    ruolo 
   TABLE DATA           *   COPY public.ruolo (posizione) FROM stdin;
    public          postgres    false    221   ��       H          0    16734    squadra 
   TABLE DATA           W   COPY public.squadra (codices, nomes, genere, tipo_squadra, "nazionalità") FROM stdin;
    public          postgres    false    219   ׾       O          0    16796    stagione_squadra 
   TABLE DATA           f   COPY public.stagione_squadra (nomec, codices, inizio_partecipazione, fine_partecipazione) FROM stdin;
    public          postgres    false    226   %�       K          0    16755    trofeo 
   TABLE DATA           B   COPY public.trofeo (nomet, descrizione, tipo, genere) FROM stdin;
    public          postgres    false    222   ��       N          0    16783    vince_giocatore 
   TABLE DATA           H   COPY public.vince_giocatore (data_vittoria, codicec, nomet) FROM stdin;
    public          postgres    false    225   U�       U          0    33043    vince_squadra 
   TABLE DATA           F   COPY public.vince_squadra (data_vittoria, codices, nomet) FROM stdin;
    public          postgres    false    232   r�       ^           0    0    calciatore_codicec_seq    SEQUENCE SET     F   SELECT pg_catalog.setval('public.calciatore_codicec_seq', 145, true);
          public          postgres    false    216            _           0    0    squadra_codices_seq    SEQUENCE SET     B   SELECT pg_catalog.setval('public.squadra_codices_seq', 81, true);
          public          postgres    false    218            �           2606    16919    accetta accetta_nomec_nomen_key 
   CONSTRAINT     b   ALTER TABLE ONLY public.accetta
    ADD CONSTRAINT accetta_nomec_nomen_key UNIQUE (nomec, nomen);
 I   ALTER TABLE ONLY public.accetta DROP CONSTRAINT accetta_nomec_nomen_key;
       public            postgres    false    231    231            }           2606    16705    calciatore calciatore_pkey 
   CONSTRAINT     ]   ALTER TABLE ONLY public.calciatore
    ADD CONSTRAINT calciatore_pkey PRIMARY KEY (codicec);
 D   ALTER TABLE ONLY public.calciatore DROP CONSTRAINT calciatore_pkey;
       public            postgres    false    217            �           2606    16764    competizione competizione_pkey 
   CONSTRAINT     _   ALTER TABLE ONLY public.competizione
    ADD CONSTRAINT competizione_pkey PRIMARY KEY (nomec);
 H   ALTER TABLE ONLY public.competizione DROP CONSTRAINT competizione_pkey;
       public            postgres    false    223            �           2606    16749    feature feature_pkey 
   CONSTRAINT     U   ALTER TABLE ONLY public.feature
    ADD CONSTRAINT feature_pkey PRIMARY KEY (nomef);
 >   ALTER TABLE ONLY public.feature DROP CONSTRAINT feature_pkey;
       public            postgres    false    220            �           2606    16921 I   militanza_calciatore militanza_calciatore_codicec_codices_data_inizio_key 
   CONSTRAINT     �   ALTER TABLE ONLY public.militanza_calciatore
    ADD CONSTRAINT militanza_calciatore_codicec_codices_data_inizio_key UNIQUE (codicec, codices, data_inizio);
 s   ALTER TABLE ONLY public.militanza_calciatore DROP CONSTRAINT militanza_calciatore_codicec_codices_data_inizio_key;
       public            postgres    false    227    227    227            �           2606    16923 =   militanza_portiere militanza_portiere_codicec_data_inizio_key 
   CONSTRAINT     �   ALTER TABLE ONLY public.militanza_portiere
    ADD CONSTRAINT militanza_portiere_codicec_data_inizio_key UNIQUE (codicec, codices, data_inizio);
 g   ALTER TABLE ONLY public.militanza_portiere DROP CONSTRAINT militanza_portiere_codicec_data_inizio_key;
       public            postgres    false    224    224    224            {           2606    16684    nazione nazione_pkey 
   CONSTRAINT     U   ALTER TABLE ONLY public.nazione
    ADD CONSTRAINT nazione_pkey PRIMARY KEY (nomen);
 >   ALTER TABLE ONLY public.nazione DROP CONSTRAINT nazione_pkey;
       public            postgres    false    215            �           2606    16754    ruolo ruolo_pkey 
   CONSTRAINT     U   ALTER TABLE ONLY public.ruolo
    ADD CONSTRAINT ruolo_pkey PRIMARY KEY (posizione);
 :   ALTER TABLE ONLY public.ruolo DROP CONSTRAINT ruolo_pkey;
       public            postgres    false    221                       2606    16739    squadra squadra_pkey 
   CONSTRAINT     W   ALTER TABLE ONLY public.squadra
    ADD CONSTRAINT squadra_pkey PRIMARY KEY (codices);
 >   ALTER TABLE ONLY public.squadra DROP CONSTRAINT squadra_pkey;
       public            postgres    false    219            �           2606    16862    squadra squadtype 
   CONSTRAINT     U   ALTER TABLE ONLY public.squadra
    ADD CONSTRAINT squadtype UNIQUE (nomes, genere);
 ;   ALTER TABLE ONLY public.squadra DROP CONSTRAINT squadtype;
       public            postgres    false    219    219            �           2606    16759    trofeo trofeo_pkey 
   CONSTRAINT     S   ALTER TABLE ONLY public.trofeo
    ADD CONSTRAINT trofeo_pkey PRIMARY KEY (nomet);
 <   ALTER TABLE ONLY public.trofeo DROP CONSTRAINT trofeo_pkey;
       public            postgres    false    222            �           2606    33095 7   vince_giocatore vince_giocatore_data_vittoria_nomet_key 
   CONSTRAINT     �   ALTER TABLE ONLY public.vince_giocatore
    ADD CONSTRAINT vince_giocatore_data_vittoria_nomet_key UNIQUE (data_vittoria, nomet);
 a   ALTER TABLE ONLY public.vince_giocatore DROP CONSTRAINT vince_giocatore_data_vittoria_nomet_key;
       public            postgres    false    225    225            �           2606    33093 3   vince_squadra vince_squadra_data_vittoria_nomet_key 
   CONSTRAINT     ~   ALTER TABLE ONLY public.vince_squadra
    ADD CONSTRAINT vince_squadra_data_vittoria_nomet_key UNIQUE (data_vittoria, nomet);
 ]   ALTER TABLE ONLY public.vince_squadra DROP CONSTRAINT vince_squadra_data_vittoria_nomet_key;
       public            postgres    false    232    232            �           2620    16870 *   stagione_squadra associazione_competizione    TRIGGER     �   CREATE TRIGGER associazione_competizione BEFORE INSERT ON public.stagione_squadra FOR EACH ROW EXECUTE FUNCTION public.inserimento_stagione_squadra();
 C   DROP TRIGGER associazione_competizione ON public.stagione_squadra;
       public          postgres    false    247    226            �           2620    16888    militanza_portiere calcpor    TRIGGER        CREATE TRIGGER calcpor BEFORE INSERT ON public.militanza_portiere FOR EACH ROW EXECUTE FUNCTION public.inserimento_portiere();
 3   DROP TRIGGER calcpor ON public.militanza_portiere;
       public          postgres    false    224    255            �           2620    16886    vince_giocatore dataminwin    TRIGGER     v   CREATE TRIGGER dataminwin BEFORE INSERT ON public.vince_giocatore FOR EACH ROW EXECUTE FUNCTION public.dataminwinf();
 3   DROP TRIGGER dataminwin ON public.vince_giocatore;
       public          postgres    false    225    251            �           2620    49419    calciatore datanmin    TRIGGER     m   CREATE TRIGGER datanmin BEFORE INSERT ON public.calciatore FOR EACH ROW EXECUTE FUNCTION public.datanminf();
 ,   DROP TRIGGER datanmin ON public.calciatore;
       public          postgres    false    246    217            �           2620    49420    calciatore dataritmax    TRIGGER     �   CREATE TRIGGER dataritmax BEFORE INSERT ON public.calciatore FOR EACH ROW WHEN ((new.data_ritiro IS NOT NULL)) EXECUTE FUNCTION public.dataritmaxf();
 .   DROP TRIGGER dataritmax ON public.calciatore;
       public          postgres    false    250    217    217            �           2620    16866 +   militanza_calciatore distinzione_calciatori    TRIGGER     �   CREATE TRIGGER distinzione_calciatori BEFORE INSERT ON public.militanza_calciatore FOR EACH ROW WHEN ((pg_trigger_depth() = 0)) EXECUTE FUNCTION public.inserimento_calciatori_genere();
 D   DROP TRIGGER distinzione_calciatori ON public.militanza_calciatore;
       public          postgres    false    227    234            �           2620    16868 '   militanza_portiere distinzione_portieri    TRIGGER     �   CREATE TRIGGER distinzione_portieri BEFORE INSERT ON public.militanza_portiere FOR EACH ROW EXECUTE FUNCTION public.inserimento_portieri_genere();
 @   DROP TRIGGER distinzione_portieri ON public.militanza_portiere;
       public          postgres    false    224    233            �           2620    16878    militanza_portiere onlyport    TRIGGER     t   CREATE TRIGGER onlyport BEFORE INSERT ON public.militanza_portiere FOR EACH ROW EXECUTE FUNCTION public.onlyporf();
 4   DROP TRIGGER onlyport ON public.militanza_portiere;
       public          postgres    false    249    224            �           2620    16890    militanza_calciatore porcalc    TRIGGER     �   CREATE TRIGGER porcalc BEFORE INSERT ON public.militanza_calciatore FOR EACH ROW EXECUTE FUNCTION public.inserimento_calciatore();
 5   DROP TRIGGER porcalc ON public.militanza_calciatore;
       public          postgres    false    227    256            �           2620    16948    vince_giocatore trofeigenere    TRIGGER     z   CREATE TRIGGER trofeigenere BEFORE INSERT ON public.vince_giocatore FOR EACH ROW EXECUTE FUNCTION public.trofeigeneref();
 5   DROP TRIGGER trofeigenere ON public.vince_giocatore;
       public          postgres    false    225    254            �           2620    33088    vince_squadra trofeisquadra    TRIGGER     z   CREATE TRIGGER trofeisquadra BEFORE INSERT ON public.vince_squadra FOR EACH ROW EXECUTE FUNCTION public.trofeisquadraf();
 4   DROP TRIGGER trofeisquadra ON public.vince_squadra;
       public          postgres    false    232    252            �           2620    33091    vince_giocatore trofeogiocatore    TRIGGER     �   CREATE TRIGGER trofeogiocatore BEFORE INSERT ON public.vince_giocatore FOR EACH ROW EXECUTE FUNCTION public.trofeogiocatoref();
 8   DROP TRIGGER trofeogiocatore ON public.vince_giocatore;
       public          postgres    false    225    253            �           2620    49421    calciatore updataritmax    TRIGGER     �   CREATE TRIGGER updataritmax BEFORE UPDATE OF data_ritiro ON public.calciatore FOR EACH ROW WHEN ((new.data_ritiro IS NOT NULL)) EXECUTE FUNCTION public.updataritmaxf();
 0   DROP TRIGGER updataritmax ON public.calciatore;
       public          postgres    false    248    217    217    217            �           2606    16894    accetta accetta_nomec_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.accetta
    ADD CONSTRAINT accetta_nomec_fkey FOREIGN KEY (nomec) REFERENCES public.competizione(nomec);
 D   ALTER TABLE ONLY public.accetta DROP CONSTRAINT accetta_nomec_fkey;
       public          postgres    false    231    223    4745            �           2606    16899    accetta accetta_nomen_fkey    FK CONSTRAINT     |   ALTER TABLE ONLY public.accetta
    ADD CONSTRAINT accetta_nomen_fkey FOREIGN KEY (nomen) REFERENCES public.nazione(nomen);
 D   ALTER TABLE ONLY public.accetta DROP CONSTRAINT accetta_nomen_fkey;
       public          postgres    false    215    231    4731            �           2606    16932    assegna assegna_nomec_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.assegna
    ADD CONSTRAINT assegna_nomec_fkey FOREIGN KEY (nomec) REFERENCES public.competizione(nomec);
 D   ALTER TABLE ONLY public.assegna DROP CONSTRAINT assegna_nomec_fkey;
       public          postgres    false    4745    223    230            �           2606    16937    assegna assegna_nomet_fkey    FK CONSTRAINT     {   ALTER TABLE ONLY public.assegna
    ADD CONSTRAINT assegna_nomet_fkey FOREIGN KEY (nomet) REFERENCES public.trofeo(nomet);
 D   ALTER TABLE ONLY public.assegna DROP CONSTRAINT assegna_nomet_fkey;
       public          postgres    false    230    222    4743            �           2606    16706 '   calciatore calciatore_nazionalità_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.calciatore
    ADD CONSTRAINT "calciatore_nazionalità_fkey" FOREIGN KEY ("nazionalità") REFERENCES public.nazione(nomen);
 S   ALTER TABLE ONLY public.calciatore DROP CONSTRAINT "calciatore_nazionalità_fkey";
       public          postgres    false    4731    215    217            �           2606    16812 6   militanza_calciatore militanza_calciatore_codicec_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.militanza_calciatore
    ADD CONSTRAINT militanza_calciatore_codicec_fkey FOREIGN KEY (codicec) REFERENCES public.calciatore(codicec);
 `   ALTER TABLE ONLY public.militanza_calciatore DROP CONSTRAINT militanza_calciatore_codicec_fkey;
       public          postgres    false    217    227    4733            �           2606    16817 6   militanza_calciatore militanza_calciatore_codices_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.militanza_calciatore
    ADD CONSTRAINT militanza_calciatore_codices_fkey FOREIGN KEY (codices) REFERENCES public.squadra(codices);
 `   ALTER TABLE ONLY public.militanza_calciatore DROP CONSTRAINT militanza_calciatore_codices_fkey;
       public          postgres    false    4735    227    219            �           2606    16773 2   militanza_portiere militanza_portiere_codicec_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.militanza_portiere
    ADD CONSTRAINT militanza_portiere_codicec_fkey FOREIGN KEY (codicec) REFERENCES public.calciatore(codicec);
 \   ALTER TABLE ONLY public.militanza_portiere DROP CONSTRAINT militanza_portiere_codicec_fkey;
       public          postgres    false    217    224    4733            �           2606    16778 2   militanza_portiere militanza_portiere_codices_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.militanza_portiere
    ADD CONSTRAINT militanza_portiere_codices_fkey FOREIGN KEY (codices) REFERENCES public.squadra(codices);
 \   ALTER TABLE ONLY public.militanza_portiere DROP CONSTRAINT militanza_portiere_codices_fkey;
       public          postgres    false    4735    219    224            �           2606    16838     possiedef possiedef_codicec_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.possiedef
    ADD CONSTRAINT possiedef_codicec_fkey FOREIGN KEY (codicec) REFERENCES public.calciatore(codicec);
 J   ALTER TABLE ONLY public.possiedef DROP CONSTRAINT possiedef_codicec_fkey;
       public          postgres    false    217    4733    229            �           2606    16927    possiedef possiedef_nomef_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.possiedef
    ADD CONSTRAINT possiedef_nomef_fkey FOREIGN KEY (nomef) REFERENCES public.feature(nomef);
 H   ALTER TABLE ONLY public.possiedef DROP CONSTRAINT possiedef_nomef_fkey;
       public          postgres    false    220    4739    229            �           2606    16825    ricopre ricopre_codicec_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.ricopre
    ADD CONSTRAINT ricopre_codicec_fkey FOREIGN KEY (codicec) REFERENCES public.calciatore(codicec);
 F   ALTER TABLE ONLY public.ricopre DROP CONSTRAINT ricopre_codicec_fkey;
       public          postgres    false    4733    217    228            �           2606    16830    ricopre ricopre_ruolo_fkey    FK CONSTRAINT     ~   ALTER TABLE ONLY public.ricopre
    ADD CONSTRAINT ricopre_ruolo_fkey FOREIGN KEY (ruolo) REFERENCES public.ruolo(posizione);
 D   ALTER TABLE ONLY public.ricopre DROP CONSTRAINT ricopre_ruolo_fkey;
       public          postgres    false    228    4741    221            �           2606    16911 !   squadra squadra_nazionalità_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.squadra
    ADD CONSTRAINT "squadra_nazionalità_fkey" FOREIGN KEY ("nazionalità") REFERENCES public.nazione(nomen);
 M   ALTER TABLE ONLY public.squadra DROP CONSTRAINT "squadra_nazionalità_fkey";
       public          postgres    false    4731    215    219            �           2606    16799 .   stagione_squadra stagione_squadra_codices_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.stagione_squadra
    ADD CONSTRAINT stagione_squadra_codices_fkey FOREIGN KEY (codices) REFERENCES public.squadra(codices);
 X   ALTER TABLE ONLY public.stagione_squadra DROP CONSTRAINT stagione_squadra_codices_fkey;
       public          postgres    false    219    4735    226            �           2606    16804 ,   stagione_squadra stagione_squadra_nomec_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.stagione_squadra
    ADD CONSTRAINT stagione_squadra_nomec_fkey FOREIGN KEY (nomec) REFERENCES public.competizione(nomec);
 V   ALTER TABLE ONLY public.stagione_squadra DROP CONSTRAINT stagione_squadra_nomec_fkey;
       public          postgres    false    223    226    4745            �           2606    16791 ,   vince_giocatore vince_giocatore_codicec_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.vince_giocatore
    ADD CONSTRAINT vince_giocatore_codicec_fkey FOREIGN KEY (codicec) REFERENCES public.calciatore(codicec);
 V   ALTER TABLE ONLY public.vince_giocatore DROP CONSTRAINT vince_giocatore_codicec_fkey;
       public          postgres    false    225    217    4733            �           2606    16942 *   vince_giocatore vince_giocatore_nomet_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.vince_giocatore
    ADD CONSTRAINT vince_giocatore_nomet_fkey FOREIGN KEY (nomet) REFERENCES public.trofeo(nomet);
 T   ALTER TABLE ONLY public.vince_giocatore DROP CONSTRAINT vince_giocatore_nomet_fkey;
       public          postgres    false    225    222    4743            �           2606    33046 (   vince_squadra vince_squadra_codices_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.vince_squadra
    ADD CONSTRAINT vince_squadra_codices_fkey FOREIGN KEY (codices) REFERENCES public.squadra(codices);
 R   ALTER TABLE ONLY public.vince_squadra DROP CONSTRAINT vince_squadra_codices_fkey;
       public          postgres    false    4735    219    232            �           2606    33051 &   vince_squadra vince_squadra_nomet_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.vince_squadra
    ADD CONSTRAINT vince_squadra_nomet_fkey FOREIGN KEY (nomet) REFERENCES public.trofeo(nomet);
 P   ALTER TABLE ONLY public.vince_squadra DROP CONSTRAINT vince_squadra_nomet_fkey;
       public          postgres    false    222    232    4743            T   �   x�}���0�g�ٺ�h*$�JPu��V�D20��K�$]���ܙ��,�InuM̀� JdB�ʊL���dA��mAF���y����IrQY*�5��Z�;������B�������z;��8��Vn��)>���\���}ɢ�N6W���t�M5�l��B� j��      S   �   x�ePIn�0<K�୷��q-��p�^za-6&���r��+GY��"�3\F���Gt�;�@0P`�l�*���4�A������%jX��Т����N5�N����2���^,/�!�a'.��R�k(��]�wh=q�?����׳��S�_��D��e��f�)��k�@�xr�ab2Z<�r�����Y7p%�Fw�x��ޒ{sR�7���K�G|��g#��M���      F   8  x�mV�r�8=C_�� �8��X�x�JNe.��)��\ ���-4���"_o��k6%��dgo�nfk�8�Z�E5��&*�1��m��O��˨ K�I3*��"�*�h�8m�8D�g��(���*�,��u0(-MM��>�`�Y�^�V�bT>'k�X�X>�hȝä
���)BS��iy��뙬-V܁�v�򨬑�<�aPq�M��*�E��[�,�h�2������8���y�Y�w`Z�`F�3a�?�sr�
..��h�񊼼C�ss���U�y�#y��ZA<;N�aP<.`%��|9��Z���A�zi���AL�E{V�tV��l�}޹I���6��ړ��H/�����Epy�_��z����"�u�x}�m��WdV{��-�z�_5��*c�\��R�(!R��4U�@���*�}<��E��Z�td������B�9�d�"������ͣu�|�Ն��M>6Ȱ�;h%y�rk]�Pv��x�+N1ʏ�L�s�<az� R'�P5FiB�꼐���=�N�����Fc���<^i�{}c�s#�L8�դ�S�T<�!bgjR�1��H�ZØ�,�PX,ԓ�f��&��=���W��Y�
7&@}4�����x0V/� ��g���k����'���`J)�s��G͹�U�;��fuJ���3W���d�K�Cϑ%���}�ь��r�V��
�mSє���]zs�f�^��C0'k�O���G裶�<�v�KڧC�%�alx�;��Yj�gPAn���C�ED���bԋ4]A%jSi�Q�B��Bzq�,�r���ZV�O����W ��Ϧ��g������ڸ�f$v�&b؛�ŵ��H��ԝ���7|���X<yIɞ��8[]^�5 �o���L��
k,��vx#m�A[j�/Nx=��t��(¡.b���1�R��?�Z�ÍN�_�`��������q#�r��9V��B����N@d'��:Y�w�b����CBpCj����Ij@˜:>b�mo.�;#�?���a��	�V�J��%��X,�Jx�#      L   �   x�m��
�0���S�͛�KB*��/[���)	9��[-���:���9�e
�	�DE��ٳ��4�
L ��6k4�����\KѬ�[�$�=ځ���c?�J���޵��`�A�\��G�L����vq=��Zvk�?�����C�_����<}�e�w�      I   �   x�M�=R�0�k�:���Y*�����y3���
����ŐC�~?����- ��
\��h=`B���b<k�ht�j�I�0)��&��;�U�tT���H����_�mK��sJ�_VS�/�B+�X��w~��<��O��.�	umJhK�`ǅ:��[����+�k:�w��dX�DN!�����a�>���e�h_�#�2�1i�?n9��1s�      P     x�eTQ��0�&w�`��%����X�v�7ݙv�������1�<����|Sb^;0>j�T�/���e[���������)�N���*��&�D�D#�cT��UO�<G�/`@$�+1�0B���䡈�)Aw5�%-�q�Ɯ��բK�hߚe#��B��u�<���P	���t�]� P[Q��e��t���
�)��h�ߣ#���¹XA����n��ڀ�`ۖo0A��B��=\F�/`�@��4)�y��_,J:C!����!�BI�b��Os����5�=7�hCeBc�o�e�%%��"�)���k
�+�JQ���΁t}`��.��:��O��5��[Qp����6J�����g���ѢC\L9���5�I��`�e"T�1o�VR���a;�����b�?_�v�i9�l1�q�8��AtT;��b�����C<I��ݷ�S��)�o(h<��#�r�DQ�_B�P�Qns&|9�W���OĹ�4�n��D��Qَ�<v���u]�  ��H      M   N   x�-���0C�f�T
$Kt��?G�G���{��|P;�?��H1>�F�o͖2
�m�l�>���^k"J�!"7kE�      D   �   x�M�A
�@Eם�x�)�taܺ	5�@��̴�w(t���y�Ozb�Ϋ�a� ]tj8(}Y2��h4ߐ�r�w������3hs��D��e#z��q�J*���ēuqƝ�j�W�5e����!����u
!� �oX?      R   �   x�m���0E��+�(�#Mv#K(�����EB�&������j�t}�t׫3q�7�O�#͔��V������}�q�G��1�j�|�z�ڮj���i�1�$��V��A^�!�,)
���r��g	�[��n��PX�.; x�|�a      Q   �   x�eQA� ;�c���6��.�1��Ѫ��Z�Ê���c�&��Rk)�T[�f��Pr�Զ�9���h餂��=�g�Ǻn��G��{[�W���l��Rj(&�a�!"cD��8��Ј�W#�'��v�]`u�6 1 衰�B��(DQ��+~?����>�+Nß����7�^      J   8   x�+�/*�L-J�J�LK�+���S�J��s2�K�KJ���JR�b���� ��      H   >  x�}��n�0Eד��*^�Ò������rld;H��;Rc�!�Қ�{2�4�-���P�+OR,U��Jb�f�GEVK�#��B*ԑj;S�>��F{��i4���lo����]��D�ѓG���И��<���`)���<��?��)̭#n�J�]^Ȟ���2��A�+������%)e����^���鏚qԕ�,8�4-�l��G,��0�vN�`e��j����pTk�*���㿛�T'��!��&Ԃ��D�8��5��N��S2k˧�5�D�Mfl�`��͓.�t]T������K�$���K      O   s   x�u�1� ��N�0-HiG/��#+����������5�Ks��:��~�&F��vL�l�#
-/�; �?"-x�A�
�Bz$
�G(�*]$x��k�e�lS�V(���J�A�      K   �  x��TKN�0]7��p��	���b�fH�d$��]�܈#����!m� �β߼���4�99gV릡B�3�J!4�s��g����� êf��ءb�f�AW	6YɊ�K��a�	ҒI����"�K��~kj,v��&`Hk,�Q8��%��H�7���Q�l���95*�r�Zf؞�ǳi��a[����)�2�;oC5���O��GC��C\���,K���gL�l*ң�����,�i�^2��b4�nԡ��-��e�5�+&��&�e3OS^V�w����8��������BŅbc�`�ɕ%`>`e5$��i�~�=�>�J��1��� ���5Z�3D.j��ʻ����&=r5��CX�R�ѽ�|��¨���;,�b�|f�O�sL3�ҢQ喫i������NO���DQ���v      N      x������ � �      U   $   x�3202�50�54�45�N.MI-)������ Y�_     