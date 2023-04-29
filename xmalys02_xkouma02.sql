-- drop trigger zakaz_rizeni_pres_body;
-- drop trigger udeleni_zakazu_rizeni;

drop table Prestupek cascade constraints;
drop table Ridic cascade constraints;
drop table RidicskyPrukaz cascade constraints;
drop table KradeneVozidlo cascade constraints;
drop table NekradeneVozidlo cascade constraints;
drop table RidicskeOpravneni cascade constraints;
drop table TypRidicskehoOpravneni cascade constraints;

drop sequence seq_id_prestupek;

drop index jmeno_prijmeni_i;

create table Prestupek (
    ID_prestupku integer,
    kategorie varchar(30),
    druh varchar(50),
    vyse_bodu smallint check(vyse_bodu >= 0 and vyse_bodu <= 12),
    vyse_blokove_pokuty integer,
    vyse_pokuty_ve_spravnim_rizeni integer,
    vyse_zakazu_rizeni smallint check(vyse_zakazu_rizeni >= 0), /*v mesicich*/

    /**/
    constraint pokuty_check check(vyse_blokove_pokuty >= 0 and vyse_pokuty_ve_spravnim_rizeni >= 0),

    /* Propojeni s ridicem */
    rodne_cislo_ridice char(11)
);

create table Ridic (
    rodne_cislo_ridice char(11) check(regexp_like(rodne_cislo_ridice, '^\d{2}((0|5)[1-9]|(1|6)[0-2])(0[1-9]|[1-2]\d|3[0-1])/[0-9]{3,4}$')),
    jmeno_prijmeni varchar(30),
    datum_narozeni date,
    pohlavi varchar(4),
    pocet_bodu smallint check(pocet_bodu >= 0 and pocet_bodu <= 12),
    statni_prislusnost char(3),
    misto_narozeni varchar(40)
);

/**
  Zpusob specializace zvolen jako dve ruzne tabulky pro podtypy i s atributy nadtypu.
 */
create table KradeneVozidlo (
    VIN char(17),
    SPZ char(7),
    typ_vozidla varchar(20),
    vyrobce varchar(20),
    model varchar(30),
    rok_vyroby smallint,
    barva varchar(15),
    razeni char(3) check(razeni = 'man' or razeni = 'aut'),

    /* Specializovane atributy */
    datum_cas_odcizeni date,
    misto_odcizeni varchar(40),

    /* Propojeni s ridicem */
    rodne_cislo_vlastnika char(11)
);

create table NekradeneVozidlo (
    VIN char(17),
    SPZ char(7),
    typ_vozidla varchar(20),
    vyrobce varchar(20),
    model varchar(30),
    rok_vyroby smallint,
    barva varchar(15),
    razeni char(3) check(razeni = 'man' or razeni = 'aut'),

    /* Specializovane atributy */
    datum_uvedeni_do_provozu date,
    palivo varchar(20),
    provozni_hmotnost integer check(provozni_hmotnost >= 0), /* kg */

    /* Propojeni s ridicem */
    rodne_cislo_vlastnika char(11)
);

create table RidicskyPrukaz (
    cislo_ridicskeho_prukazu char(9),
    datum_vydani date,
    datum_platnosti date,
    vydavajici_urad varchar(40),

    /* Propojeni s ridicem */
    rodne_cislo_ridice char(11)
);

/**
  Vztahova entitni mnozina vyjadrujici, ze ridicsky prukaz ma M opravneni a zaroven
  jedno opravneni muze nalezet N ridicskym prukazum. Puvodni ERD je tedy doplnen o
  dve entitni mnoziny, RidicskeOpravneni a TypRidicskehoOpravneni.
 */
create table RidicskeOpravneni (
    /* Propojeni s ridicem */
    cislo_ridicskeho_prukazu char(9),

    /* Propojeni s typem opravneni */
    typ_opravneni varchar(3)
);

create table TypRidicskehoOpravneni (
    typ_opravneni varchar(3)
);

/**
  Nastaveni primarnich klicu a cizich klicu, ktere propoji tabulky
 */
alter table Ridic add constraint pk_ridic primary key (rodne_cislo_ridice);

alter table Prestupek add constraint pk_prestupek primary key (ID_prestupku);
alter table Prestupek add constraint fk_ridic_prestupek foreign key (rodne_cislo_ridice)
    references Ridic on delete cascade;

alter table RidicskyPrukaz add constraint pk_ridicsky_prukaz primary key (cislo_ridicskeho_prukazu);
alter table RidicskyPrukaz add constraint fk_ridic_ridicak foreign key (rodne_cislo_ridice)
    references Ridic on delete cascade;

alter table KradeneVozidlo add constraint pk_kradene_vozidlo primary key (VIN);
alter table KradeneVozidlo add constraint fk_vlastnik_kradene foreign key (rodne_cislo_vlastnika)
    references Ridic on delete cascade;

alter table NekradeneVozidlo add constraint pk_nekradene_vozidlo primary key (VIN);
alter table NekradeneVozidlo add constraint fk_vlastnik_nekradene foreign key (rodne_cislo_vlastnika)
    references Ridic on delete cascade;

alter table TypRidicskehoOpravneni add constraint pk_typ_opravneni primary key (typ_opravneni);

/**
  Ridicske opravneni je tabulka bez primarniho klice, protoze nepotrebujeme unikatni polozku v teto tabulce.
  Bezny use-case je vypsani ridicskych opravneni jednoho ridicaku nebo napr. pocet ridicaku, ktere maji toto opravneni.
 */
alter table RidicskeOpravneni add constraint fk_opravneni_ridicak foreign key (cislo_ridicskeho_prukazu)
    references RidicskyPrukaz; /* tady nebude on delete cascade, protoze pri smazani jednoho opravneni nechceme smazat ridicak */
alter table RidicskeOpravneni add constraint fk_opravneni_typ foreign key (typ_opravneni)
    references TypRidicskehoOpravneni; /* Tady to same, nechceme smazat typy opravneni, ma je vice ridicaku */

create sequence seq_id_prestupek
    minvalue 1
    start with 1
    increment by 1
    nocache;

/**
  Casto jsou hodnoty nami insertovane do tabulek dosti nerealne. Chteli jsme si jen zprijemnit praci a
  trochu se u toho zasmat. Rikali jsme si, ze to jsou jen "demo data", tak doufame, ze to nebude vadit.
 */
insert into Ridic
values ('990101/0110', 'Adela Novakova', to_date('10.4.1998', 'dd.mm.yyyy'), 'zena', 1, 'eng', 'Londyn');
insert into Ridic
values ('735222/4020', 'Adam Ondra', to_date('01.01.2000', 'dd.mm.yyyy'), 'muz', 9, 'cze', 'Adamov');
insert into Ridic
values ('660101/0112', 'Uwe Filter', to_date('10.4.1620', 'dd.mm.yyyy'), 'jine', 7, 'cze', 'Adamov');
insert into Ridic
values ('020202/2020', 'Patrik Nejezrohlik', to_date('22.4.1973', 'dd.mm.yyyy'), 'muz', 11, 'svk', 'Budapest');
insert into Ridic
values ('020412/9371', 'Honza Zeleny', to_date('22.4.1966', 'dd.mm.yyyy'), 'muz', 0, 'cze', 'As');
insert into Ridic
values ('641108/4783', 'Petr Bezejmenny', to_date('22.4.1999', 'dd.mm.yyyy'), 'muz', 4, 'cze', 'Adamov');
insert into Ridic
values ('901231/1209', 'Andrea Lmaoxdova', to_date('22.7.2003', 'dd.mm.yyyy'), 'zena', 2, 'pol', 'Krakow');

/**
  Zavaznosti:
    1. V pohode
    2. Tak akorat
    3. Zavazne
    4. Nejzavaznejsi
    5. Velky spatny
 */
insert into Prestupek
values (seq_id_prestupek.nextval, 'Nejzavaznejsi', 'Jizda pod vlivem', 6, 0, 20000, 12, '735222/4020');
insert into Prestupek
values (seq_id_prestupek.nextval, 'V pohode', 'Srazil chodce', 1, 0, 1, 1, '660101/0112');
insert into Prestupek
values (seq_id_prestupek.nextval, 'Tak akorat', 'Prekroceni rychlosti o 1 km/h', 12, 20000, 100000, 360, '660101/0112');
insert into Prestupek
values (seq_id_prestupek.nextval, 'V pohode', 'Srazil srnu', 5, 10, 30, 3, '990101/0110');
insert into Prestupek
values (seq_id_prestupek.nextval, 'Zavazne', 'Narval to do autobusu', 7, 1234, 5678, 20, '660101/0112');
insert into Prestupek
values (seq_id_prestupek.nextval, 'Nejzavaznejsi', 'Jel jako prase', 4, 1000, 100, 12, '660101/0112');
insert into Prestupek
values (seq_id_prestupek.nextval, 'V pohode', 'Srazil maminku s kocarkem', 3, 2000, 12345, 318, '641108/4783');
insert into Prestupek
values (seq_id_prestupek.nextval, 'Velky spatny', 'Shorelo mu auto za jizdy', 8, 3000, 0, 904, '901231/1209');
insert into Prestupek
values (seq_id_prestupek.nextval, 'Nejzavaznejsi', 'Nedal prednost v jizde', 10, 20000, 0, 57, '901231/1209');

insert into RidicskyPrukaz
values('EA 000000', to_date('13.4.1192', 'dd.mm.yyyy'), to_date('13.4.1193', 'dd.mm.yyyy'), 'Adamov', '735222/4020');
insert into RidicskyPrukaz
values ('EE hahaha', to_date('8.8.888', 'dd.mm.yyyy'), to_date('11.11.1111', 'dd.mm.yyyy'), 'Boskovice', '990101/0110');
insert into RidicskyPrukaz
values ('EO hehehe', to_date('1.1.1400', 'dd.mm.yyyy'), to_date('12.12.1212', 'dd.mm.yyyy'), 'Blansko', '660101/0112');
insert into RidicskyPrukaz
values ('EU hohoho', to_date('20.10.2010', 'dd.mm.yyyy'), to_date('10.10.1010', 'dd.mm.yyyy'), 'Brno', '020202/2020');
insert into RidicskyPrukaz
values ('EI huhuhu', to_date('20.10.2010', 'dd.mm.yyyy'), to_date('10.10.1010', 'dd.mm.yyyy'), 'Brno', '020412/9371');
insert into RidicskyPrukaz
values ('EA 010101', to_date('20.10.2010', 'dd.mm.yyyy'), to_date('10.10.2026', 'dd.mm.yyyy'), 'Adamov', '641108/4783');
insert into RidicskyPrukaz
values ('EE 021123', to_date('20.10.2010', 'dd.mm.yyyy'), to_date('10.10.1010', 'dd.mm.yyyy'), 'Brno', '901231/1209');

/* VIN cisla jsou nahodne vygenerovana na strance https://randomvin.com/ */
insert into NekradeneVozidlo
values ('4Y1SL65848Z411439', '1B10000', 'kamion', 'volvo', 'favorit', '1348', 'fuchsiova', 'aut', to_date('13.4.1192', 'dd.mm.yyyy'), 'hnede uhli', 69420, '735222/4020');
insert into NekradeneVozidlo
values ('4JGDA5HB2EA287176', '2A22222', 'traktor', 'toyota', 'octavia', '1945', 'azurova', 'man', to_date('13.4.1918', 'dd.mm.yyyy'), 'elektrina', 20, '990101/0110');
insert into NekradeneVozidlo
values ('JN8AS5MT8EW670601', '2A22236', 'skateboard', 'tatra', 'aventador', '3001', 'azurova', 'man', to_date('14.7.3005', 'dd.mm.yyyy'), 'antihmota', 20, '990101/0110');
insert into NekradeneVozidlo
values ('JT3GN86RXT0035545', '3c33333', 'traktor', 'lamborghini', 'pickup', '1234', 'tyrkysova', 'aut', to_date('19/12/1939', 'dd.mm.yyyy'), 'hnede uhli', 69420, '660101/0112');
insert into NekradeneVozidlo
values ('1B3ES26C45D159621', '8b41234', 'osobni auto', 'skoda', 'fabie', '2002', 'zluta', 'aut', to_date('19/12/2003', 'dd.mm.yyyy'), 'LPG', 2000, '020412/9371');
insert into NekradeneVozidlo
values ('1FDLF47G7VEB53339', '3m89023', 'osobni auto', 'volkswagen', 'arteon', '2017', 'nachova', 'aut', to_date('19/12/2019', 'dd.mm.yyyy'), 'CNG', 2122, '641108/4783');
insert into NekradeneVozidlo
values ('WDDGF8AB1ER304054', '0d92841', 'dodavka', 'ford', 'transit', '1996', 'fialova', 'man', to_date('19/12/1939', 'dd.mm.yyyy'), 'diesel', 3400, '901231/1209');

insert into KradeneVozidlo
values ('2G2WC58C261211764', '4d44444', 'autobus', 'bmw', 'multipla', '5678', 'ruzova', 'man', to_date('08.08.1873 17:30', 'dd.mm.yyyy hh24:mi'), 'Adamov', '020202/2020');
insert into KradeneVozidlo
values ('1C3EL55R52N367696', '5e55555', 'letadlo', 'skoda', 'thalia', '9101', 'zluta', 'aut', to_date('30.10.1851 18:30', 'dd.mm.yyyy hh24:mi'), 'Adamov', '660101/0112');


insert into TypRidicskehoOpravneni values ('AM');
insert into TypRidicskehoOpravneni values ('A');
insert into TypRidicskehoOpravneni values ('A1');
insert into TypRidicskehoOpravneni values ('A2');
insert into TypRidicskehoOpravneni values ('B1');
insert into TypRidicskehoOpravneni values ('B');
insert into TypRidicskehoOpravneni values ('C1');
insert into TypRidicskehoOpravneni values ('C');
insert into TypRidicskehoOpravneni values ('D');
insert into TypRidicskehoOpravneni values ('D1');
insert into TypRidicskehoOpravneni values ('BE');
insert into TypRidicskehoOpravneni values ('C1E');
insert into TypRidicskehoOpravneni values ('CE');
insert into TypRidicskehoOpravneni values ('D1E');
insert into TypRidicskehoOpravneni values ('DE');
insert into TypRidicskehoOpravneni values ('T');

insert into RidicskeOpravneni values ('EA 000000', 'AM');
insert into RidicskeOpravneni values ('EA 000000', 'T');
insert into RidicskeOpravneni values ('EA 000000', 'B');

insert into RidicskeOpravneni values ('EE hahaha', 'D');
insert into RidicskeOpravneni values ('EE hahaha', 'A1');
insert into RidicskeOpravneni values ('EE hahaha', 'A');
insert into RidicskeOpravneni values ('EE hahaha', 'C1E');

insert into RidicskeOpravneni values ('EO hehehe', 'B');
insert into RidicskeOpravneni values ('EO hehehe', 'B1');

insert into RidicskeOpravneni values ('EU hohoho', 'C1E');
insert into RidicskeOpravneni values ('EU hohoho', 'D');
insert into RidicskeOpravneni values ('EU hohoho', 'T');

insert into RidicskeOpravneni values ('EI huhuhu', 'D1E');
insert into RidicskeOpravneni values ('EI huhuhu', 'T');
insert into RidicskeOpravneni values ('EI huhuhu', 'D');
insert into RidicskeOpravneni values ('EI huhuhu', 'B');
insert into RidicskeOpravneni values ('EI huhuhu', 'AM');

insert into RidicskeOpravneni values ('EA 010101', 'A1');
insert into RidicskeOpravneni values ('EA 010101', 'AM');
insert into RidicskeOpravneni values ('EA 010101', 'A2');
insert into RidicskeOpravneni values ('EA 010101', 'A');

insert into RidicskeOpravneni values ('EE 021123', 'B');
insert into RidicskeOpravneni values ('EE 021123', 'BE');
insert into RidicskeOpravneni values ('EE 021123', 'C');
insert into RidicskeOpravneni values ('EE 021123', 'D');
insert into RidicskeOpravneni values ('EE 021123', 'C1E');
insert into RidicskeOpravneni values ('EE 021123', 'D1E');

commit;

/* Najdi vsechny prestupky lidi narozenych v Adamove */
select kategorie, druh
from Prestupek join Ridic using (rodne_cislo_ridice)
where misto_narozeni ='Adamov';

/* Najdi vsechna kradena vozidla a jmena jejich vlastniku, ktera byla kradena v Adamove a jejichz vlastnici se narodili v Adamove */
select typ_vozidla, vyrobce, model, jmeno_prijmeni
from KradeneVozidlo v, Ridic r
where v.rodne_cislo_vlastnika = r.rodne_cislo_ridice and
      v.misto_odcizeni = 'Adamov' and r.misto_narozeni = 'Adamov';

/* Najdi vsechna ridicska opravneni, ktera maji lide kteri se narodili v Adamove */
select distinct typ_opravneni
from RidicskeOpravneni join RidicskyPrukaz using(cislo_ridicskeho_prukazu) join Ridic using (rodne_cislo_ridice)
where misto_narozeni = 'Adamov';

/* Kolik maji dohromady nasbirano bodu lide z ruznych mest */
select misto_narozeni, sum(pocet_bodu) as soucet_bodu
from Ridic
group by misto_narozeni
order by soucet_bodu desc;

/* Vypis, kolik nekradenych vozidel jezdi na ktera paliva */
select palivo, count(*) pocet_vozidel
from NekradeneVozidlo v, Ridic r
where v.rodne_cislo_vlastnika = r.rodne_cislo_ridice
group by palivo;

/* Kteri ridici vlastni traktor? */
select distinct jmeno_prijmeni
from NekradeneVozidlo v, Ridic r
where v.rodne_cislo_vlastnika = r.rodne_cislo_ridice and
      typ_vozidla =  'traktor';     --tento select je zde jen aby byl videt rozdil vysledku mezi timto a nasledujicim dotazem

/* Kteri ridic vlastni pouze traktor? */
select distinct jmeno_prijmeni
from NekradeneVozidlo v, Ridic r
where v.rodne_cislo_vlastnika = r.rodne_cislo_ridice and
      typ_vozidla = 'traktor' and
      not exists (select *
                  from NekradeneVozidlo v
                  where r.rodne_cislo_ridice = v.rodne_cislo_vlastnika and
                        v.typ_vozidla <> 'traktor');

/* Kteri ridici spachali prestupek kategorie "nejzavaznejsi"? */
select jmeno_prijmeni, pohlavi, misto_narozeni
from Ridic
where rodne_cislo_ridice in
      (select rodne_cislo_ridice
       from Prestupek
       where kategorie = 'Nejzavaznejsi');


/* Najdi vsechny prestupky, ktere byly spachany ridici, kteri vlastni vozidlo/a na hnede uhli */
select kategorie, druh, jmeno_prijmeni, palivo
from Prestupek p, Ridic r, NekradeneVozidlo v
where p.rodne_cislo_ridice = r.rodne_cislo_ridice and
      r.rodne_cislo_ridice = v.rodne_cislo_vlastnika and
      v.palivo = 'hnede uhli';

commit;




-------------------
-- 4. cast projektu
-------------------

-- Procedura vynuluje body vsem lidem z Adamova, kteri jeste nemaji 12 bodu.
create or replace procedure vynuluj_adamov
is
    cursor lidi_z_adamova is select * from Ridic where misto_narozeni = 'Adamov';
    rec Ridic%rowtype;
begin
--     open lidi_z_adamova;
    for rec in lidi_z_adamova loop
        if rec.pocet_bodu < 12 then
--             DBMS_OUTPUT.PUT_LINE(rec.pocet_bodu || ' beztak Uwe Filter zas');
            update Ridic set pocet_bodu = 0 where rodne_cislo_ridice = rec.rodne_cislo_ridice;
        end if;
    end loop;
end;
/

--ridici z adamova pred
select * from Ridic where misto_narozeni = 'Adamov';

begin
    vynuluj_adamov();
end;
/

--ridici z adamova po
select * from Ridic where misto_narozeni = 'Adamov';

rollback;




-- Procedura podle VINu najde v tabulce nekradenych vozidel vozidlo, a premisti ho do tabulky kradenych vozidel
create or replace procedure Update_nekradene_na_kradene (vin_auta in char, datum_odciz in varchar, misto_odciz in varchar)
is
    vin_aut char(17);
    datum_odc date;
    misto_odc varchar(40);

    spz_nekrad NekradeneVozidlo.SPZ%type;
    typ NekradeneVozidlo.typ_vozidla%type;
    vyrob NekradeneVozidlo.vyrobce%type;
    rok_vyr NekradeneVozidlo.rok_vyroby%type;
    model_voz NekradeneVozidlo.model%type;
    barva_voz NekradeneVozidlo.barva%type;
    razeni_voz NekradeneVozidlo.razeni%type;

    rodne_c_vlastnika NekradeneVozidlo.rodne_cislo_vlastnika%type;

begin
    vin_aut := vin_auta;
    datum_odc := to_date(datum_odciz, 'dd.mm.yyyy');
    misto_odc := misto_odciz;

    select SPZ, typ_vozidla, vyrobce, model, rok_vyroby, barva, razeni, rodne_cislo_vlastnika
    into spz_nekrad, typ, vyrob, model_voz, rok_vyr, barva_voz, razeni_voz, rodne_c_vlastnika
    from NekradeneVozidlo where VIN = vin_auta;

    delete from NekradeneVozidlo where VIN = vin_aut;

    insert into KradeneVozidlo
    values (vin_aut, spz_nekrad, typ, vyrob, model_voz, rok_vyr, barva_voz, razeni_voz, datum_odc, misto_odc, rodne_c_vlastnika);
--     DBMS_OUTPUT.PUT_LINE(vin_aut);
--     DBMS_OUTPUT.PUT_LINE(spz_nekrad);
--     DBMS_OUTPUT.PUT_LINE(razeni_voz);
exception
when NO_DATA_FOUND then
    DBMS_OUTPUT.PUT_LINE('Vozidlo neni v databazi');
end;
/

--nekradene pred
select * from NekradeneVozidlo
where VIN = '4Y1SL65848Z411439';
--kradene pred
select * from KradeneVozidlo
where VIN = '4Y1SL65848Z411439';

begin
    Update_nekradene_na_kradene ('4Y1SL65848Z411439', '6.8.2000', 'Adamov');
end;
/

--nekradene po
select * from NekradeneVozidlo
where VIN = '4Y1SL65848Z411439';
--kradene po
select * from KradeneVozidlo
where VIN = '4Y1SL65848Z411439';

rollback;



-- triggrrrrrrrrrrrrrrrrrrrrrr
-- drop trigger zakaz_rizeni_pres_body;
--drop trigger udeleni_zakazu_rizeni;

create or replace trigger udeleni_zakazu_rizeni
after insert on Prestupek
for each row
when (new.vyse_zakazu_rizeni > 0)
declare
    datum char(10);
begin
    datum := to_char(sysdate, 'DD-MM-YYYY');
    DBMS_OUTPUT.PUT_LINE('brasko');
--     DBMS_OUTPUT.PUT_LINE(:new.druh);
--     DBMS_OUTPUT.PUT_LINE(datum);
--     DBMS_OUTPUT.PUT_LINE(sysdate - 1); --muzem odecist jeden den. husty
    update RidicskyPrukaz set datum_platnosti = to_date(datum, 'DD-MM-YYYY')
    where rodne_cislo_ridice = :new.rodne_cislo_ridice;
end;
/
commit;

--pred odebranim
select * from RidicskyPrukaz where rodne_cislo_ridice = '660101/0112';

-- Uwe Filter dostal zakaz rizeni na 2 mesice
insert into Prestupek
values (seq_id_prestupek.nextval, 'Nejzavaznejsi', 'Zabil v lese jelena bez nenavisti', 2, 200, 0, 2, '660101/0112');

--po odebrani
select * from RidicskyPrukaz where rodne_cislo_ridice = '660101/0112';

rollback;



create or replace trigger zakaz_rizeni_pres_body
after update of pocet_bodu on Ridic
for each row
when (new.pocet_bodu = 12)
declare
    datum char(10);
begin
    datum := to_char(sysdate, 'DD-MM-YYYY');
--     DBMS_OUTPUT.PUT_LINE('brasko ten dojel');
    update RidicskyPrukaz set datum_platnosti = to_date(datum, 'DD-MM-YYYY')
    where rodne_cislo_ridice = :new.rodne_cislo_ridice;
end;
/

commit;

--pred
select * from RidicskyPrukaz where rodne_cislo_ridice = '020202/2020';

--chtelo by to proceduru na pridavani bodu. mozna pridat a zavolat z prvniho triggeru
update Ridic set pocet_bodu = 12
where rodne_cislo_ridice = '020202/2020';

--po
select * from RidicskyPrukaz where rodne_cislo_ridice = '020202/2020';
rollback ;


select SPZ, typ_vozidla, vyrobce, model, rok_vyroby,
    case
    when rok_vyroby < 1885
        then 'stare'
    when rok_vyroby > 2023
        then 'husty'
    else 'aktualni'
    end as novota
from NekradeneVozidlo;


/* Pred indexem */
explain plan for
select jmeno_prijmeni, typ_opravneni
from Ridic r, RidicskeOpravneni ro, RidicskyPrukaz rp
where r.rodne_cislo_ridice = rp.rodne_cislo_ridice and
      rp.cislo_ridicskeho_prukazu = ro.cislo_ridicskeho_prukazu and
      r.jmeno_prijmeni = 'Andrea Lmaoxdova'
group by jmeno_prijmeni, typ_opravneni
order by typ_opravneni;

select plan_table_output
from table(DBMS_XPLAN.DISPLAY());

create index jmeno_prijmeni_i
on Ridic(jmeno_prijmeni);

/* Po indexu */
explain plan for
select jmeno_prijmeni, typ_opravneni
from Ridic r, RidicskeOpravneni ro, RidicskyPrukaz rp
where r.jmeno_prijmeni = 'Andrea Lmaoxdova' and
      r.rodne_cislo_ridice = rp.rodne_cislo_ridice and
      rp.cislo_ridicskeho_prukazu = ro.cislo_ridicskeho_prukazu
group by jmeno_prijmeni, typ_opravneni
order by typ_opravneni;

select plan_table_output
from table(DBMS_XPLAN.DISPLAY());

-- SELECT USER FROM dual;
-- -- Výpis rolí přiřazených přihlášenému uživateli (xstudent)
-- SELECT * FROM USER_ROLE_PRIVS;
-- -- Výpis jemu přímo přiřazených systémových práv
-- SELECT * FROM USER_SYS_PRIVS;
-- -- Výpis jemu přímo přiřazených práv k objektům
-- SELECT * FROM USER_SYS_PRIVS;
--
--
-- SELECT * FROM ALL_USERS;
-- SELECT * FROM ALL_USERS where USERNAME = 'XKOUMA02';
--
--
-- declare
--     var1 integer;
-- begin
--     var1 := 42;
--     DBMS_OUTPUT.PUT_LINE(var1);
-- end;
-- /



-- create or replace trigger Update_nekradene_na_kradene
--     before insert on KradeneVozidlo
-- declare
--     vin_existuje exception;
-- begin
--     if exists(select VIN from NekradeneVozidlo where VIN = new.VIN) then
--         raise vin_existuje;
--     end if;
--
-- exception
--     when vin_existuje then
--         delete from NekradeneVozidlo where VIN = new.VIN;
--         DBMS_OUTPUT.PUT_LINE('TRYGRR');
-- end;
-- /

