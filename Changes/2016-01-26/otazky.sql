USE SpravaZmluv
GO
create table dbo.Otazka
(
	ID int identity(1, 1) not null,
	Znenie varchar(max) not null,
	constraint PK_Otazka primary key (ID)
)
go
alter table dbo.Otazka add Check_Sum as checksum(Znenie)
go
alter table dbo.Otazka add constraint UK_Otazka unique (Check_Sum)
go

drop table dbo.SkolenieTypOtazka
GO
create table dbo.SkolenieTypOtazka
(
	ID int not null identity(1, 1),
	SkolenieTypID int not null,
	OtazkaID int not null,
	constraint PK_SkolenieTypOtazka primary key (ID),
	constraint UK_SkolenieTypOtazka unique (SkolenieTypID, OtazkaID),
	constraint FK_SkolenieTypOtazka_SkolenieTyp foreign key (SkolenieTypID) references dbo.SkolenieTyp (ID),
	constraint FK_SkolenieTypOtazka_Otazka foreign key (OtazkaID) references dbo.Otazka (ID)
)
go

drop table dbo.SkoleniePreKohoOtazka
GO
create table dbo.SkoleniePreKohoOtazka
(
	ID int not null identity(1, 1),
	SkoleniePreKohoID int not null,
	OtazkaID int not null,
	constraint PK_SkoleniePreKohoOtazka primary key (ID),
	constraint UK_SkoleniePreKohoOtazka unique (SkoleniePreKohoID, OtazkaID),
	constraint FK_SkoleniePreKohoOtazka_SkoleniePreKoho foreign key (SkoleniePreKohoID) references dbo.SkoleniePreKoho (ID),
	constraint FK_SkoleniePreKohoOtazka_Otazka foreign key (OtazkaID) references dbo.Otazka (ID)
)
go

drop table dbo.SkolenieOtazka
go
create table dbo.SkolenieOtazka
(
	ID int not null identity(1, 1),
	Poradie int not null,
	SkolenieID int not null,
	OtazkaID int not null,
	constraint PK_SkolenieOtazka primary key (ID),
	constraint UK_SkolenieOtazka unique (SkolenieID, OtazkaID),
	constraint FK_SkolenieOtazka_Skolenie foreign key (SkolenieID) references dbo.Skolenie (ID),
	constraint FK_SkolenieOtazka_Otazka foreign key (OtazkaID) references dbo.Otazka (ID)
)
go

USE [SpravaZmluv]
GO

/****** Object:  View [dbo].[UlohaUvodnaPraca]    Script Date: 16.02.2016 20:57:00 ******/
DROP VIEW [dbo].[UlohaUvodnaPraca]
GO

use SpravaZmluv
go
declare @bozpTyp int
select @bozpTyp = ID from dbo.SkolenieTyp where Nazov like '%BOZP%'

declare @otazky table (id int)

insert dbo.Otazka
output inserted.ID into @otazky(id)
values
('Ako často sa musia zamestnanci oboznamovať s predpismi na zaistenie bezpečnosti a ochrany zdravia pri práci?'),
('Je povinnosť zamestnanca zúčastniť sa lekárskej prehliadky , pokiaľ ho vyšle zamestnávateľ?'),
('Čo je ručná manipulácia s bremenami?'),
('S bremenami akej maximálnej hmotnosti môžu manipulovať ženy pri ručnom zdvíhaní a prenášaní bremien? '),
('Aká je maximálna hmotnosť ručne prenášaného bremena pre mužov?'),
('Aký pracovný prostriedok by ste použili na dosiahnutie uložených predmetov v regáloch vo výške mimo dosah?'),
('Čo je pracovný úraz?'),
('Kedy treba oznámiť vznik pracovného úrazu?'),
('Môžeme hovoriť o pracovnom úraze ak sa stane na ceste do zamestnania, zo zamestnania a pri obednej prestávke?'),
('Komu nahlasuje zamestnanec vznik úrazu ?'),
('Môže zamestnanec svojvoľne opravovať technické zariadenia?'),
('Je inšpektor práce povinný sa pri kontrole objektu preukázať preukazom inšpektora práce? Môže vojsť inšpektor do všetkých priestorov na pracoviskách?'),
('Je zamestnávateľ povinný zabezpečiť pitný režim pre zamestnancov?'),
('Fyzickej osobe nachádzajúcej sa na pracovisku zamestnávateľa, ktorá marí výkon inšpekcie práce môže inšpektorát  práce uložiť poriadkovú pokutu vo výške:'),
('Je zamestnávateľ povinný  vybaviť pracovisko potrebným počtom lekárničiek a zabezpečiť ich pravidelnú kontrolu a doplňovanie?'),
('Môže zamestnávateľ vydať zákaz fajčenia, ak sa v priestoroch zamestnávateľa nachádzajú nefajčiari?'),
('Je povinnosťou zamestnávateľa do lekárničiek zabezpečiť lieky? Napr. ibuprofen, paralen...?'),
('Môže zamestnanec odmietnuť podrobiť sa dychovej skúške na alkohol?'),
('Je povinnosťou zamestnávateľa zabezpečiť pracovné kreslá, ktoré majú opierku na ruky?'),
('Je povinnosťou zamestnanca nahlásiť zistené nedostatky na pracovisku svojmu nadriadenému ?')

insert dbo.SkolenieTypOtazka(SkolenieTypID, OtazkaID)
select @bozpTyp, id from @otazky

insert dbo.SkoleniePreKohoOtazka(SkoleniePreKohoID, OtazkaID)
select spk.ID, o.id from @otazky o cross join dbo.SkoleniePreKoho spk
go

use SpravaZmluv
go

declare @oopTyp int
select @oopTyp = ID from dbo.SkolenieTyp where Nazov like '%Ochrana pred%'
--select @oopTyp

declare @otazky table (id int)

insert dbo.Otazka
output inserted.ID into @otazky(id)
values
('Každý, kto spozoruje požiar je povinný:'),
('Vzniknutý požiar treba okamžite ohlásiť:'),
('Požiarny poplach sa väčšinou vyhlasuje:'),
('Čo vymedzujú požiarne poplachové smernice?'),
('Požiarny evakuačný plán určuje:'),
('Pod pojmom úniková cesta sa rozumie:'),
('Aká zásada platí pre hasiace prístroje, ktoré sú umiestnené na pracoviskách?'),
('Hasiacim prístrojom vodným môžeme účinne hasiť:'),
('Hasiacim prístrojom práškovým sa môžu hasiť predovšetkým:'),
('Do ktorých objektov, priestorov, je oprávnený vstupovať štátny požiarny dozor?'),
('Akú požiadavku má spĺňať požiarny uzáver po každom otvorení alebo pri vzniku požiaru?'),
('Čo patrí medzi požiarne deliace stavebné konštrukcie podľa STN 92 0201-2?')

insert dbo.SkolenieTypOtazka(SkolenieTypID, OtazkaID)
select @oopTyp, id from @otazky

insert dbo.SkoleniePreKohoOtazka(SkoleniePreKohoID, OtazkaID)
select spk.ID, o.id from @otazky o cross join dbo.SkoleniePreKoho spk
go

insert dbo.Konfiguracia(Nastavenie, Hodnota)
values('PredvolenyGenerovanyPocetOtazok', '6')
go

CREATE PROCEDURE report.SkolenieOtazka
	@SkolenieID INT
AS
SELECT
	so.Poradie
	,o.Znenie
FROM
	dbo.SkolenieOtazka so
	INNER JOIN dbo.Otazka o
		on o.ID = so.OtazkaID
WHERE
	so.SkolenieID = @SkolenieID
GO
